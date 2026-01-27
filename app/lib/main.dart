import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/routing/app_router.dart';
import 'package:app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create a container to read providers before the app starts
  final container = ProviderContainer();

  // Show a splash screen or simple loading indicator if needed native side,
  // but here we delay the Flutter app mount until auth is ready.
  // Ideally, native splash screen covers this wait.

  try {
    // Eagerly wait for session restoration
    await container.read(authStartupProvider.future);
  } catch (e) {
    // Handle startup error (e.g., log it), app will likely start unauthenticated
    print('Startup Error: $e');
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Data is ready, just watch router
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'WheelyTrails',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.LightTheme,
      darkTheme: AppTheme.DarkTheme,
      routerConfig: goRouter,
    );
  }
}
