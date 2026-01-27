import 'package:app/features/auth/models/auth_response.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  AuthService(this._storage, this._dio);

  bool get isLoggedIn => false;

  Future<bool> restoreSessionAsync() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    // As explicitly requested: check for refresh token and call refresh endpoint
    if (refreshToken != null) {
      return await tryRefreshAsync();
    }
    return false;
  }

  Future<bool> tryRefreshAsync() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    final jwtToken = await _storage.read(key: 'jwtToken');

    if (refreshToken != null && jwtToken != null) {
      try {
        final response = await _dio.post(
          'https://api.wheelytrails.com/api/account/identity/refresh-token',
          data: {'jwtToken': jwtToken, 'refreshToken': refreshToken},
        );

        if (response.statusCode == 200) {
          final authResponse = AuthResponse.fromJson(response.data);
          if (authResponse.success && authResponse.jwtToken != null) {
            await _storage.write(key: 'jwtToken', value: authResponse.jwtToken);
            await _storage.write(
              key: 'refreshToken',
              value: authResponse.refreshToken,
            );
            return true;
          }
        }
      } catch (e) {
        // Refresh failed
      }
    }
    await logoutAsync();
    return false;
  }

  Future<bool> ensureAuthorizationHeaderAsync(Dio dio) async {
    final token = await _storage.read(key: 'jwtToken');
    if (token != null) {
      if (JwtDecoder.isExpired(token)) {
        if (await tryRefreshAsync()) {
          final newToken = await _storage.read(key: 'jwtToken');
          dio.options.headers['Authorization'] = 'Bearer $newToken';
          return true;
        }
      } else {
        dio.options.headers['Authorization'] = 'Bearer $token';
        return true;
      }
    }
    return false;
  }

  Future<void> logoutAsync() async {
    await _storage.deleteAll();
  }

  Future<User?> loginAsync(String email, String password) async {
    try {
      final response = await _dio.post(
        'https://api.wheelytrails.com/api/account/identity/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        if (authResponse.success && authResponse.user != null) {
          await _storage.write(key: 'jwtToken', value: authResponse.jwtToken);
          await _storage.write(
            key: 'refreshToken',
            value: authResponse.refreshToken,
          );
          return authResponse.user;
        } else {
          throw Exception(authResponse.message);
        }
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
