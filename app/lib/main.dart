import 'dart:convert';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/routing/app_router.dart';
import 'package:app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Options
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // 2. Manual Read
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
    print('STARTUP ERROR: $e');
  }

  // 3. Construct Initial State
  AuthState initialState = AuthState.initial();
  if (token != null && user != null) {
    initialState = AuthState.authenticated(user);
  }

  // 4. Create Container with Override
  // Pass the state to the Controller if we modified it to accept it,
  // OR we can just allow the controller to build normally and rely on restoreSession if we didn't use an override,
  // BUT the request specified: "Pass that initial token directly into the ProviderContainer".
  // So we use the override approach.
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => AuthController(initialState)),
    ],
  );

  // 5. Run App
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
