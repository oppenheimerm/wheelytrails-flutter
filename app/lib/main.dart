import 'dart:convert';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/core/providers/theme_provider.dart'; // Import theme provider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:app/routing/app_router.dart';
import 'package:app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Options
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // 2. Manual Read (Auth)
  String? token;
  User? user;
  try {
    token = await storage.read(key: 'jwtToken');
    final userStr = await storage.read(key: 'user');
    if (userStr != null) {
      user = User.fromJson(jsonDecode(userStr));
    }
    print('STARTUP: Token found on disk: ${token != null}');
  } catch (e) {
    print('STARTUP ERROR (Auth): $e');
  }

  // 3. Manual Read (Theme)
  ThemeMode initialTheme = ThemeMode.system;
  try {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('theme_mode');
    if (themeStr != null) {
      initialTheme = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeStr,
        orElse: () => ThemeMode.system,
      );
    }
    print('STARTUP: Theme found on disk: $initialTheme');
  } catch (e) {
    print('STARTUP ERROR (Theme): $e');
  }

  // 4. Construct Initial Auth State
  AuthState initialAuthState = AuthState.initial();
  if (token != null && user != null) {
    initialAuthState = AuthState.authenticated(user);
  }

  // 5. Create Container with Overrides
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => AuthController(initialAuthState),
      ),
      themeControllerProvider.overrideWith(() => ThemeController(initialTheme)),
    ],
  );

  // 6. Run App
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Data is ready, just watch router and theme
    final goRouter = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'WheelyTrails',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.LightTheme,
      darkTheme: AppTheme.DarkTheme,
      themeMode: themeMode, // Apply persistent theme
      routerConfig: goRouter,
    );
  }
}
