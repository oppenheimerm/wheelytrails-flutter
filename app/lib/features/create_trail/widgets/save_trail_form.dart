import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaveTrailForm extends StatefulWidget {
  final List<dynamic> difficulties; // New: From API
  final List<dynamic> surfaces; // New: From API
  final Future<void> Function(
    String title,
    String description,
    String difficultyCode,
    String surfaceCode,
  )
  onSave;
  final VoidCallback onCancel;

  const SaveTrailForm({
    super.key,
    required this.difficulties,
    required this.surfaces,
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

  String? _selectedDifficultyCode;
  String? _selectedSurfaceCode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default to the first difficulty in the list (e.g., "EASY")
    if (widget.difficulties.isNotEmpty) {
      _selectedDifficultyCode = widget.difficulties.first['code'];
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSurfaceCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a surface type')),
        );
        return;
      }

      setState(() => _isSaving = true);
      try {
        await widget.onSave(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _selectedDifficultyCode!,
          _selectedSurfaceCode!,
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blackBold = GoogleFonts.figtree(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );
    final blackText = GoogleFonts.figtree(color: Colors.black);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Save Trail', style: blackBold.copyWith(fontSize: 24)),
              const SizedBox(height: 24),

              // --- 1. TITLE ---
              Text('Title', style: blackBold.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: blackText,
                decoration: const InputDecoration(
                  hintText: 'e.g. Sunny Morning Walk',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // --- 2. DESCRIPTION ---
              Text('Description', style: blackBold.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: blackText,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tell others about this trail...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. DIFFICULTY ---
              Text('Difficulty', style: blackBold.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDifficultyCode,
                items: widget.difficulties.map((d) {
                  return DropdownMenuItem<String>(
                    value: d['code'],
                    child: Text(d['title'], style: blackText),
                  );
                }).toList(),
                onChanged: (val) =>
                    setState(() => _selectedDifficultyCode = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              // --- 4. SURFACE TYPE ---
              Text('Primary Surface', style: blackBold.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: widget.surfaces.map((s) {
                  final isSelected = _selectedSurfaceCode == s['code'];
                  return ChoiceChip(
                    label: Text(s['title']),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(
                        () =>
                            _selectedSurfaceCode = selected ? s['code'] : null,
                      );
                    },
                    selectedColor: const Color(0xFF2D5A27),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // --- 5. ACTION BUTTONS ---
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5A27),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Trail'),
                    ),
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
