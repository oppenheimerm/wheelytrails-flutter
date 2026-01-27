import 'dart:async';
import 'dart:convert';
import 'package:app/features/auth/services/auth_service.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/network/auth_interceptor.dart';

// Dio Provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  // Using encryptedSharedPreferences: true for Android persistence fix
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  dio.interceptors.add(AuthInterceptor(dio, storage));
  return dio;
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final authDio = Dio();
  return AuthService(storage, authDio);
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
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Initial state is loading for startup
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
