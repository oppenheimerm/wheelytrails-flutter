import 'package:app/features/trail/models/trail_models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaveTrailForm extends StatefulWidget {
  final Future<void> Function(
    String title,
    String description,
    DifficultyLevel difficulty,
    int surfaceFlags,
  )
  onSave;

  final VoidCallback onCancel;

  const SaveTrailForm({
    super.key,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<SaveTrailForm> createState() => _SaveTrailFormState();
}

class _SaveTrailFormState extends State<SaveTrailForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DifficultyLevel _difficulty = DifficultyLevel.easy;
  final Set<SurfaceType> _selectedSurfaces = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _calculateSurfaceFlags() {
    int flags = 0;
    for (final type in _selectedSurfaces) {
      flags |= type.value;
    }
    return flags;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        await widget.onSave(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _difficulty,
          _calculateSurfaceFlags(),
        );
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // High visibility theme overrides
    final blackText = GoogleFonts.figtree(color: Colors.black);
    final blackBold = GoogleFonts.figtree(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    return Container(
      color: Colors.white, // Ensure white background
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Save Trail', style: blackBold.copyWith(fontSize: 24)),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                style: blackText,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  labelStyle: blackText,
                  counterStyle: blackText,
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                style: blackText,
                maxLength: 600,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: blackText,
                  counterStyle: blackText,
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Difficulty
              Text('Difficulty', style: blackBold.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              SegmentedButton<DifficultyLevel>(
                segments: const [
                  ButtonSegment(
                    value: DifficultyLevel.easy,
                    label: Text('Easy'),
                    icon: Icon(Icons.sentiment_satisfied),
                  ),
                  ButtonSegment(
                    value: DifficultyLevel.medium,
                    label: Text('Medium'),
                    icon: Icon(Icons.sentiment_neutral),
                  ),
                  ButtonSegment(
                    value: DifficultyLevel.hard,
                    label: Text('Hard'),
                    icon: Icon(Icons.sentiment_very_dissatisfied),
                  ),
                ],
                selected: {_difficulty},
                onSelectionChanged: (Set<DifficultyLevel> newSelection) {
                  setState(() {
                    _difficulty = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return Colors.black;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF2D5A27); // Forest Green
                    }
                    return Colors.white;
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Surface Types
              Text('Surface Types', style: blackBold.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: SurfaceType.values
                    .where((t) => t != SurfaceType.none)
                    .map((type) {
                      return FilterChip(
                        label: Text(type.label),
                        labelStyle: TextStyle(
                          color: _selectedSurfaces.contains(type)
                              ? Colors.white
                              : Colors.black,
                        ),
                        selected: _selectedSurfaces.contains(type),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedSurfaces.add(type);
                            } else {
                              _selectedSurfaces.remove(type);
                            }
                          });
                        },
                        checkmarkColor: Colors.white,
                        selectedColor: const Color(0xFF2D5A27),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black26),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : widget.onCancel,
                    child: Text('Cancel', style: blackText),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5A27),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Trail'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
