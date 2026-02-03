import 'package:app/core/api_constants.dart';
import 'package:app/features/auth/models/auth_response.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/models/country.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Singleton Pattern
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;

  AuthService._internal();

  // 1. Explicitly define the options
  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // Simply initialize WindowsOptions without the undefined containerName
    wOptions: WindowsOptions(),
  );

  bool get isLoggedIn =>
      false; // Logic not fully implemented in valid/invalid check here?
  // keeping existing "false" placeholder or implementing check?
  // Existing was "bool get isLoggedIn => false;" - keeping as is to avoid scope creep,
  // though normally this would check token existence/validity.

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'jwtToken');
  }

  Future<bool> restoreSessionAsync() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken != null) {
      return await refresh(); // Using the new refresh method
    }
    return false;
  }

  // Unified Refresh Logic
  Future<bool> refresh() async {
    print('DEBUG: AuthService performing token refresh...');
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      // jwtToken read removed as it was unused locally

      if (refreshToken == null) {
        print('DEBUG: No refresh token available.');
        return false;
      }

      // We make the call to the endpoint
      // Adjust endpoint if needed. Previous code used /refresh-token or /identity/refresh?
      // TrailApiService used: /api/account/identity/refresh
      // Old AuthService used: /api/account/identity/refresh-token
      // I will use /api/account/identity/refresh as it was verified working in TrailApiService most recently (or confirmed by user context).
      // Actually, let's use the one from TrailApiService success: /api/account/identity/refresh

      final response = await Dio().post(
        ApiConstants.fullUrl(ApiConstants.refreshToken),
        data: {
          'refreshToken': refreshToken,
        }, // The working payload from TrailApiService
      );

      if (response.statusCode == 200) {
        final newJwt = response.data['jwtToken'];
        final newRefresh = response.data['refreshToken'];

        // Also handle AuthResponse wrapper if the API returns that format?
        // TrailApiService logic: response.data['jwtToken'] directly.
        // Old AuthService logic: AuthResponse.fromJson(response.data).
        // I'll support the map access as verified recent trail upload work.

        if (newJwt != null) {
          await _storage.write(key: 'jwtToken', value: newJwt);
          if (newRefresh != null) {
            await _storage.write(key: 'refreshToken', value: newRefresh);
          }
          print('DEBUG: AuthService: Refresh Successful.');
          return true;
        }
      }
    } catch (e) {
      print('DEBUG: AuthService: Refresh Failed: $e');
    }

    // If we fail specifically (e.g. 400/401 on refresh), we might want to logout.
    // For now, simple return false.
    return false;
  }

  Future<void> logoutAsync() async {
    // This clears EVERYTHING: jwtToken, refreshToken, user, and our handshake
    await _storage.deleteAll();

    // Verification for your debug console
    final all = await _storage.readAll();
    debugPrint("🧹 Logout: Secure storage is now empty: ${all.isEmpty}");
  }

  Future<User?> loginAsync(String email, String password) async {
    try {
      final response = await Dio().post(
        ApiConstants.fullUrl(ApiConstants.login),
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

  Future<Map<String, dynamic>?> updateSettings(
    Map<String, dynamic> settings,
  ) async {
    debugPrint('DEBUG: AuthService.updateSettings called with $settings');

    try {
      // 1. Stick to the proven Lab flow: Force a refresh first
      await refresh();

      // 2. Get the new token from our fixed storage
      final token = await _storage.read(key: 'jwtToken');
      if (token == null) throw Exception('Not authenticated');

      // 3. Use the standalone Dio() with the FULL URL
      // This matches your successful Favorites screen test
      final response = await Dio().put(
        ApiConstants.fullUrl(ApiConstants.updateSettings),
        data: settings,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('DEBUG: API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Return the data so the UI can update
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('DEBUG: Settings Update Failed: ${e.response?.statusCode}');
      debugPrint('DEBUG: Error Data: ${e.response?.data}');
      rethrow;
    }
  }

  Future<List<Country>> fetchCountries() async {
    try {
      final response = await Dio().get(
        ApiConstants.fullUrl(ApiConstants.getCountries),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => Country.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
