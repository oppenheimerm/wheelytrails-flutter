import 'package:app/features/create_trail/widgets/save_trail_form.dart';
import 'package:app/features/trail/models/trail_models.dart';
import 'package:app/features/trail/controllers/trail_record_controller.dart';
import 'package:app/features/trail/presentation/widgets/poi_selection_sheet.dart';
import 'package:app/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/preferences_service.dart';
import 'package:go_router/go_router.dart';

class CreateTrailScreen extends ConsumerStatefulWidget {
  const CreateTrailScreen({super.key});

  @override
  ConsumerState<CreateTrailScreen> createState() => _CreateTrailScreenState();
}

class _CreateTrailScreenState extends ConsumerState<CreateTrailScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize controller (check permissions, location) on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trailRecordControllerProvider.notifier).initialize();
    });
  }

  void _showBitrateWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS tracking is active and may impact battery life.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showPoiSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PoiSelectionSheet(
        onPoiSelected: (type) {
          // TODO: Add Note dialog? For now just add type.
          ref.read(trailRecordControllerProvider.notifier).addPoi(type, null);
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trailRecordControllerProvider);
    final controller = ref.read(trailRecordControllerProvider.notifier);

    // If not recording...
    if (!state.isRecording) {
      // ...but we have points, it means we just finished and need to save.
      if (state.points.isNotEmpty) {
        return Scaffold(
          appBar: AppBar(title: const Text('Complete Trail')),
          body: SaveTrailForm(
            onSave: (title, description, difficulty, surfaceFlags) async {
              // Construct DTO
              final dto = CreateTrailDTO(
                title: title,
                description: description,
                difficulty: difficulty.value,
                surfaceFlags: surfaceFlags,
                startLocation: state.points.first,
                endLocation: state.points.last,
                waypoints: state.points,
                pois: state.pois,
                elevationProfile: state.points
                    .map((p) => p.altitude ?? 0.0)
                    .toList(),
                lengthMeters: state.distanceKm * 1000,
              );

              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Saving trail...'),
                        ],
                      ),
                      duration: Duration(days: 1), // Indefinite until dismissed
                    ),
                  );
                }

                // Save
                await controller.saveTrail(dto);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trail saved successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  // Reset controller and navigate home
                  controller.reset();
                  // Using GoRouter to navigate home
                  context.go('/home');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving trail: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            onCancel: () {
              // Discard confirmation? Or just reset.
              // For simplicity now, just reset (maybe ask confirm in a real app, but requirements didn't specify).
              // Actually, let's show a dialog before discarding here?
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Discard Trail?'),
                  content: const Text(
                    'Are you sure you want to discard this recording?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.reset();
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.accessible_forward, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'Ready to Record?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                final showWarning = ref
                    .read(preferencesServiceProvider)
                    .showRecordingWarning;
                if (showWarning) {
                  _showBitrateWarning(context);
                }
                controller.startRecording();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Recording'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Dashboard View
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Trail'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Time',
                    value: _formatDuration(state.elapsedTime),
                    unit: '',
                    icon: Icons.timer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Distance',
                    value: state.distanceKm.toStringAsFixed(2),
                    unit: 'km',
                    icon: Icons.map,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Elevation',
                    value: (state.currentElevation).toStringAsFixed(0),
                    unit: 'm',
                    icon: Icons.terrain,
                  ),
                ),
                const SizedBox(width: 12),
                // Placeholder for maybe Avg Speed or similar? Or just empty for now.
                const Expanded(child: SizedBox()),
              ],
            ),

            const Spacer(),

            // POI Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.tonalIcon(
                onPressed: _showPoiSheet,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add Point of Interest'),
              ),
            ),
            const SizedBox(height: 16),

            // Controls (Pause/Stop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (state.isPaused)
                  FilledButton.icon(
                    onPressed: controller
                        .startRecording, // Resume (start handles resume logic too)
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: controller.pauseRecording,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),

                if (state.points.length < 2)
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Discard Recording?'),
                          content: const Text(
                            'This trail is too short to save. Do you want to discard it?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                // Stop recording (will return tooShort and reset)
                                await controller.stopRecording();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Recording discarded'),
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              child: const Text('Discard'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Discard'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () async {
                      // Try stopping
                      final result = await controller.stopRecording();
                      if (context.mounted) {
                        if (result == StopRecordingResult.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Debug data synced to dev log'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          // Should not happen given the if check, but graceful fallback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Recording Discarded (Too Short)'),
                            ),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Finish Trail'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
