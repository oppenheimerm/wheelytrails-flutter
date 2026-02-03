import 'dart:async';
import 'dart:convert';
import 'package:app/features/auth/services/auth_service.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/models/country.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/network/auth_interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

// Dio Provider
final dioProvider = Provider<Dio>((ref) {
  print('DEBUG: Initializing dioProvider...');
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      baseUrl: 'https://api.wheelytrails.com',
    ),
  );
  // Using encryptedSharedPreferences: true for Android persistence fix
  // final storage = const FlutterSecureStorage(
  //   aOptions: AndroidOptions(encryptedSharedPreferences: true),
  // );
  // Storage is instantiated inside AuthInterceptor now.

  // Add Interceptors
  dio.interceptors.add(AuthInterceptor());

  // Retry Logic
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      logPrint: print,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ),
  );

  // Pretty Logging
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      compact: true,
      maxWidth: 90,
    ),
  );

  print(
    'DEBUG: dioProvider initialized with Auth, Retry, and Logger interceptors',
  );
  return dio;
});

// Public Dio Provider (No Auth Interceptor)
final publicDioProvider = Provider<Dio>((ref) {
  print('DEBUG: Initializing publicDioProvider...');
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      baseUrl: 'https://api.wheelytrails.com',
    ),
  );

  // Retry Logic
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      logPrint: print,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ),
  );

  // Pretty Logging
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      compact: true,
      maxWidth: 90,
    ),
  );

  return dio;
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  print('DEBUG: Initializing authServiceProvider (Singleton)...');
  return AuthService.instance;
});

// Countries Provider
final countriesProvider = FutureProvider<List<Country>>((ref) async {
  final authService = ref.read(authServiceProvider);
  return await authService.fetchCountries();
});

// Auth States
enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  factory AuthState.initial() =>
      const AuthState(status: AuthStatus.initial, isLoading: true);
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated({String? message}) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: message);
}

// Startup Provider - Handles the cold boot wait
final authStartupProvider = FutureProvider<void>((ref) async {
  // Wait for session restoration
  await ref.read(authControllerProvider.notifier).restoreSession();
});

// Auth Controller
// Auth Controller
// We remove the auto-dispose or keep it, but we need to allow overriding the build logic or ensure it reads what we want.
// BUT, refactoring to simple manual read in main:
// User wants: "Pass that initial token directly into the ProviderContainer".
// Best way: use 'overrides' in main.
// So `authControllerProvider` needs to be overrideable. It already is.
// But `AuthController` needs to know about the initial state.
// We can make `AuthController` have a state setter or constructor argument.
// However, the `Notifier` constructor is `AuthController.new`.
// We can change the provider to:
// final authControllerProvider = NotifierProvider<AuthController, AuthState>(() => AuthController());
// Then in main: `overrides: [ authControllerProvider.overrideWith(() => AuthController(initialState)) ]`
// Updating AuthController to store initial state:

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

class AuthController extends Notifier<AuthState> {
  final AuthState? _initialOverride;

  AuthController([this._initialOverride]);

  @override
  AuthState build() {
    // If override is provided, use it. But we can't easily pass it via default constructor usage
    // unless we change how provider is declared.
    // Actually, `AuthController([this._override])` works if we use a closure in provider decl.

    if (_initialOverride != null) {
      return _initialOverride;
    }

    return AuthState.initial();
  }

  Future<void> restoreSession() async {
    final authService = ref.read(authServiceProvider);
    try {
      final success = await authService.restoreSessionAsync();
      print('DEBUG: restoreSession finished. Result: $success');

      if (success) {
        final user = await Helper.getStoredUser();
        if (user != null) {
          state = AuthState.authenticated(user);
        } else {
          state = AuthState.unauthenticated(message: "User data missing");
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      print('AUTH_DEBUG: Restoration error: $e');
      state = AuthState.unauthenticated(message: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.loginAsync(email, password);
      if (user != null) {
        await Helper.storeUser(user);
        state = AuthState.authenticated(user);
      }
    } catch (e) {
      state = AuthState.unauthenticated(message: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);

    // 1. Wipe the tokens and handshake from the disk
    await authService.logoutAsync();

    // 2. Wipe the local 'user' helper data
    await Helper.clearUser();

    // 3. Move the app back to the 'Logged Out' screen
    state = AuthState.unauthenticated();
  }

  Future<void> updateProfile({
    required String firstName,
    required String bio,
    required String countryCode,
  }) async {
    print('DEBUG: AuthController.updateProfile called');

    try {
      final authService = ref.read(authServiceProvider);

      // 1. Call Service
      final responseMap = await authService.updateSettings({
        'FirstName': firstName, // Use PascalCase to match your C# properties
        'Bio': bio,
        'CountryCode': countryCode,
      });

      // 2. Extract data from the nested 'updatedSettings' key
      if (responseMap != null && responseMap['success'] == true) {
        final updatedData =
            responseMap['updatedSettings'] as Map<String, dynamic>;

        final currentUser = state.user;
        if (currentUser != null) {
          // 3. Create the merged user object
          final mergedUser = currentUser.copyWith(
            firstName: updatedData['firstName'] as String?,
            bio: updatedData['bio'] as String?,
            countryCode: updatedData['countryCode'] as String?,
          );

          // 4. Persist to local storage so it survives app restarts
          await Helper.storeUser(mergedUser);

          // 5. Update the Riverpod state (This triggers the UI rebuild)
          state = AuthState.authenticated(mergedUser);

          print(
            'DEBUG: AuthProvider state updated with: ${mergedUser.firstName}',
          );
        }
      }
    } catch (e) {
      print('DEBUG: AuthController Error: $e');
      rethrow;
    }
  }
}

// Helper class
class Helper {
  // Universal configuration for all platforms
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(),
  );

  static Future<User?> getStoredUser() async {
    try {
      final str = await _storage.read(key: 'user');
      if (str != null) {
        return User.fromJson(jsonDecode(str));
      }
    } catch (e) {
      debugPrint('AUTH_HELPER_ERROR: $e');
    }
    return null;
  }

  static Future<void> storeUser(User? user) async {
    if (user != null) {
      await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
    }
  }

  static Future<void> clearUser() async {
    // This clears the user object and the tokens to ensure a clean logout
    await _storage.deleteAll();
  }
}
