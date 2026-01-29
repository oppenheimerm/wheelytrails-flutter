import 'dart:async';
import 'dart:convert';
import 'package:app/features/auth/services/auth_service.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/models/country.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
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
    ),
  );
  // Using encryptedSharedPreferences: true for Android persistence fix
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Add Interceptors
  dio.interceptors.add(AuthInterceptor(dio, storage, ref));

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

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  print('DEBUG: Initializing authServiceProvider...');
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final authDio = ref.watch(dioProvider);
  print(
    'DEBUG: authServiceProvider creating AuthService with watched dioProvider',
  );
  return AuthService(storage, authDio);
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
      return _initialOverride!;
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
    await authService.logoutAsync();
    await Helper.clearUser();
    state = AuthState.unauthenticated();
  }

  Future<void> updateProfile({
    required String firstName,
    required String bio,
    required String countryCode,
  }) async {
    print('DEBUG: AuthController.updateProfile called');
    // Note: NOT setting state.isLoading = true here to avoid global rebuilds.
    // The UI should handle its own loading state.

    try {
      final authService = ref.read(authServiceProvider);
      // 2. Call Service
      print('DEBUG: Calling authService.updateSettings...');
      final updatedSettingsMap = await authService.updateSettings({
        'firstName': firstName,
        'bio': bio,
        'countryCode': countryCode,
        'gpsAccuracy': 1,
      });
      print('DEBUG: authService.updateSettings returned: $updatedSettingsMap');

      if (updatedSettingsMap != null) {
        // 3. Update Local State via Merge Strategy
        final currentUser = state.user;
        if (currentUser != null) {
          final mergedUser = currentUser.copyWith(
            firstName: updatedSettingsMap['firstName'] as String?,
            bio: updatedSettingsMap['bio'] as String?,
            countryCode: updatedSettingsMap['countryCode'] as String?,
            gpsAccuracy: (updatedSettingsMap['gpsAccuracy'] as num?)
                ?.toDouble(),
          );
          await Helper.storeUser(mergedUser);
          state = AuthState.authenticated(mergedUser);
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
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<User?> getStoredUser() async {
    try {
      final str = await _storage.read(key: 'user');
      if (str != null) {
        return User.fromJson(jsonDecode(str));
      }
    } catch (_) {}
    return null;
  }

  static Future<void> storeUser(User? user) async {
    if (user != null) {
      await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
    }
  }

  static Future<void> clearUser() async {
    await _storage.delete(key: 'user');
  }
}
