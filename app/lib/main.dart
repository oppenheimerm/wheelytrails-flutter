import 'dart:convert';
import 'package:app/core/network/token_service.dart';
import 'package:app/core/providers/providers.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/core/providers/theme_provider.dart'; // Import theme provider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:app/routing/app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/services/preferences_service.dart';

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

  // 3. Manual Read (Theme) & Prefs
  ThemeMode initialTheme = ThemeMode.system;
  late final SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('theme_mode');
    if (themeStr != null) {
      initialTheme = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeStr,
        orElse: () => ThemeMode.system,
      );
    }
    print('STARTUP: Theme found on disk: $initialTheme');
  } catch (e) {
    print('STARTUP ERROR (Theme/Prefs): $e');
    // Fallback? If prefs fails, app might be unstable if we rely on it.
    // Re-throw or handle? For now, we assume it works or we might crash on provider override without value?
    // Actually, 'late final' must be assigned. If it fails, we have a problem.
    // Let's create a dummy if failed? Or await again?
    // In production we'd want robust handling.
    prefs = await SharedPreferences.getInstance(); // Retry or crash
  }

  // ---------------------------------------------------------
  // 🟢 NEW STEP 4a: Create the TokenService instance HERE
  // This happens after you read the token but BEFORE you build the Container
  // ---------------------------------------------------------
  final tokenService = TokenService();
  if (token != null) {
    tokenService.setAccessToken(token, null);
  }

  // 4. Construct Initial Auth State
  AuthState initialAuthState = AuthState.initial();
  if (token != null && user != null) {
    initialAuthState = AuthState.authenticated(user);
  }

  // 5. Create Container with Overrides
  final container = ProviderContainer(
    overrides: [
      // -------------------------------------------------------
      // 🟢 NEW OVERRIDE: Add this to your existing list
      // This "teaches" the rest of the app to use our synced service
      // -------------------------------------------------------
      tokenServiceProvider.overrideWithValue(tokenService),

      authControllerProvider.overrideWith(
        () => AuthController(initialAuthState),
      ),
      themeControllerProvider.overrideWith(() => ThemeController(initialTheme)),
      sharedPreferencesProvider.overrideWithValue(prefs),
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
    // final themeMode = ref.watch(themeControllerProvider); // Unused as we enforce light mode

    return MaterialApp.router(
      title: 'WheelyTrails',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5A27), // Forest Green
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.figtreeTextTheme().copyWith(
          bodyLarge: GoogleFonts.figtree(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: GoogleFonts.figtree(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          bodySmall: GoogleFonts.figtree(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          labelLarge: GoogleFonts.figtree(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          labelMedium: GoogleFonts.figtree(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          labelSmall: GoogleFonts.figtree(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // darkTheme: AppTheme.DarkTheme, // Explicitly ignoring dark theme as requested
      themeMode: ThemeMode.light, // Enforce light mode
      routerConfig: goRouter,
    );
  }
}
