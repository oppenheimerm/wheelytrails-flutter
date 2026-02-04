import 'package:app/core/services/preferences_service.dart';
import 'package:app/features/trail/controllers/trail_record_controller.dart';
import 'package:app/features/trail/presentation/widgets/poi_selection_sheet.dart';
import 'package:app/features/trail/services/trail_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/trail/providers/trail_metadata_provider.dart';
import 'package:app/features/trail/models/trail_models.dart';
import 'package:app/widgets/stat_card.dart';
import 'package:app/features/create_trail/widgets/save_trail_form.dart';

class CreateTrailScreen extends ConsumerStatefulWidget {
  const CreateTrailScreen({super.key});

  @override
  ConsumerState<CreateTrailScreen> createState() => _CreateTrailScreenState();
}

class _CreateTrailScreenState extends ConsumerState<CreateTrailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trailRecordControllerProvider.notifier).initialize();
    });
  }

  // --- 1. Discard Dialog Helper ---
  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Recording?'),
        content: const Text('This will permanently delete this trail data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(trailRecordControllerProvider.notifier).reset();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showBitrateWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS tracking is active and may impact battery life.'),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  void _showPoiSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PoiSelectionSheet(
        onPoiSelected: (type) {
          // Add the POI via the controller
          ref.read(trailRecordControllerProvider.notifier).addPoi(type, null);
          // Automatically close the sheet after selection
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trailRecordControllerProvider);
    final controller = ref.read(trailRecordControllerProvider.notifier);
    final metadataAsync = ref.watch(trailMetadataProvider);

    final prefs = ref.watch(preferencesServiceProvider);
    final distanceUnit = prefs.useMetricUnits ? 'km' : 'mi';
    final elevationUnit = prefs.useMetricUnits ? 'm' : 'ft';

    // --- STATE 1: ACTIVE RECORDING ---
    if (state.isRecording) {
      return Scaffold(
        appBar: AppBar(title: Text(state.isPaused ? 'Paused' : 'Recording')),
        body: Column(
          children: [
            // ... (Your StatCards go h
            //
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
                    unit: distanceUnit,
                    icon: Icons.map,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatCard(
              label: 'Elevation',
              value: state.currentElevation.toStringAsFixed(0),
              unit: elevationUnit,
              icon: Icons.terrain,
            ),

            const Spacer(),

            // POI Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _showPoiSheet,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add Point of Interest'),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: _showDiscardDialog,
                  child: const Text('Discard'),
                ),

                // Pause/Resume Toggle
                state.isPaused
                    ? FilledButton(
                        onPressed: controller.startRecording,
                        child: const Text('Resume'),
                      )
                    : OutlinedButton(
                        onPressed: controller.pauseRecording,
                        child: const Text('Pause'),
                      ),

                // FINISH BUTTON: The gateway to the form
                FilledButton(
                  onPressed: () async {
                    final result = await controller.stopRecording();
                    if (result == StopRecordingResult.tooShort &&
                        context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trail too short to save!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    // If success, state.isRecording becomes false, triggering State 2 below.
                  },
                  child: const Text('Finish'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // --- STATE 2: RECORDING STOPPED -> SHOW SAVE FORM ---
    if (state.points.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Trail')),
        body: metadataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (metadata) => SaveTrailForm(
            difficulties: metadata.difficulties,
            surfaces: metadata.surfaces,
            onCancel: _showDiscardDialog,
            onSave: (title, description, difficultyCode, surfaceCode) async {
              // 1. Prepare the Data
              final dto = CreateTrailDTO(
                title: title,
                description: description,
                difficulty: difficultyCode,
                surfaceType: surfaceCode,
                startLocation: state.points.first,
                endLocation: state.points.last,
                waypoints: state.points,
                pois: state.pois,
                elevationProfile: state.points
                    .map((p) => p.altitude ?? 0.0)
                    .toList(),
                lengthMeters: state.distanceKm * 1000,
              );

              // 2. Submit to API
              final result = await controller.saveTrail(dto);

              // 3. Cleanup & Exit (This ensures the form closes and points are cleared)
              if (context.mounted) {
                if (result == CreateTrailResult.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trail saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                controller.reset(); // Empties the points list
                context.go('/home'); // Moves the user away from the form
              }
            },
          ),
        ),
      );
    }

    // --- STATE 3: IDLE ---
    return Scaffold(
      body: Center(
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
                if (prefs.showRecordingWarning) _showBitrateWarning(context);
                controller.startRecording();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Recording'),
            ),
          ],
        ),
      ),
    );
  }
}
