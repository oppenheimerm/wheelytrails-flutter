import 'package:app/features/auth/models/country.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart'; // Removed

enum SaveState { idle, saving, saved }

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _bioController;
  final _formKey = GlobalKey<FormState>();

  String? _selectedCountryCode;
  bool _initialized = false;

  // Use ValueNotifier for local UI state to avoid full screen rebuilds
  final ValueNotifier<SaveState> _saveStateNotifier = ValueNotifier(
    SaveState.idle,
  );

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _bioController.dispose();
    _saveStateNotifier.dispose();
    super.dispose();
  }

  void _initializeFields(
    List<Country> countries, {
    required String? userFirstName,
    required String? userBio,
    required String? userCountryCode,
  }) {
    if (_initialized) return;

    if (userFirstName != null) _firstNameController.text = userFirstName;
    if (userBio != null) _bioController.text = userBio;

    if (userCountryCode != null &&
        countries.any((c) => c.code == userCountryCode)) {
      _selectedCountryCode = userCountryCode;
    } else {
      // No fallback to 'BR' as requested
      _selectedCountryCode = null;
    }
    _initialized = true;
  }

  Future<void> _saveProfile() async {
    print('DEBUG: _saveProfile invoked');
    if (_formKey.currentState!.validate()) {
      print('DEBUG: Form validated');

      // Dismiss keyboard
      FocusScope.of(context).unfocus();

      // Start Saving - No SetState
      _saveStateNotifier.value = SaveState.saving;

      try {
        print('DEBUG: Calling updateProfile');

        // Calls API and now updates state internally on success
        await ref
            .read(authControllerProvider.notifier)
            .updateProfile(
              firstName: _firstNameController.text.trim(),
              bio: _bioController.text.trim(),
              countryCode: _selectedCountryCode!, // Validated by form
            );

        print('DEBUG: updateProfile success');

        // Immediate Visual Feedback
        HapticFeedback.lightImpact();

        // Mark Saved - No SetState needed for full screen
        if (mounted) {
          _saveStateNotifier.value = SaveState.saved;
        }
      } catch (e) {
        print('DEBUG: _saveProfile caught error: $e');
        if (mounted) {
          _saveStateNotifier.value = SaveState.idle;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building EditProfileScreen...');

    final countriesAsync = ref.watch(countriesProvider);
    final currentUser = ref.read(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          ValueListenableBuilder<SaveState>(
            valueListenable: _saveStateNotifier,
            builder: (context, state, child) {
              if (state == SaveState.saving) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              } else if (state == SaveState.saved) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Saved',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return TextButton(
                onPressed: _saveProfile,
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],
      ),
      body: countriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading metadata: $err')),
        data: (countries) {
          if (currentUser != null && !_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_initialized) {
                setState(() {
                  _initializeFields(
                    countries,
                    userFirstName: currentUser.firstName,
                    userBio: currentUser.bio,
                    userCountryCode: currentUser.countryCode,
                  );
                });
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedCountryCode,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                    ),
                    items: countries.map((country) {
                      return DropdownMenuItem(
                        value: country.code,
                        child: Text(country.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCountryCode = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a country' : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.info_outline),
                      ),
                      semanticCounterText: 'User Bio',
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
