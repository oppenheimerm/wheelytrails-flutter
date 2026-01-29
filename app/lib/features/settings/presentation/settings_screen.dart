import 'package:app/core/providers/theme_provider.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final colorScheme = Theme.of(context).colorScheme;

    // Format date if user exists
    String memberSince = 'Unknown';
    if (user != null) {
      memberSince = DateFormat.yMMMMd().format(user.registrationDate);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header: Profile
          if (user != null) ...[
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        (user.profilePicture != null &&
                            user.profilePicture!.isNotEmpty)
                        ? NetworkImage(user.profilePicture!)
                        : null,
                    child:
                        (user.profilePicture == null ||
                            user.profilePicture!.isEmpty)
                        ? Icon(
                            Icons.account_circle,
                            size: 60,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.firstName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/edit-profile'),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Section 1: Appearance
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle app appearance'),
                  secondary: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: colorScheme.primary,
                  ),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    ref.read(themeControllerProvider.notifier).toggleTheme();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Safety
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Safety',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Trail Recording Alerts'),
                  subtitle: const Text('Show warning during recording'),
                  secondary: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.primary,
                  ),
                  value:
                      user?.showRecordingWarning ??
                      true, // Default to true or read from user
                  onChanged: (value) {
                    // TODO: Implement toggle for safety setting via API or local state
                    // For now, it's illustrative as we don't have a user update endpoint ready in this context
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Safety setting update not implemented yet.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Account Info (Read Only)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Username'),
                  subtitle: Text(user?.profileUsername ?? 'N/A'),
                  leading: const Icon(Icons.alternate_email),
                  enabled: false,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('Member Since'),
                  subtitle: Text(memberSince),
                  leading: const Icon(Icons.calendar_today),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Footer: Logout
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                context.go('/login');
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
