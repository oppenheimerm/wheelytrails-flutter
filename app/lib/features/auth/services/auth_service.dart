import 'package:app/features/auth/models/auth_response.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/models/country.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Singleton Pattern
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;

  AuthService._internal() {
    // Add logging to internal dio if desired
    // _dio.interceptors.add(PrettyDioLogger(...));
  }

  final _storage = const FlutterSecureStorage();
  final _dio = Dio(BaseOptions(baseUrl: 'https://api.wheelytrails.com'));

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

      final response = await _dio.post(
        '/api/account/identity/refresh',
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
    await _storage.deleteAll();
  }

  Future<User?> loginAsync(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/account/identity/login',
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
    print('DEBUG: AuthService.updateSettings called with $settings');
    try {
      // Need to manually attach auth header since we use internal _dio without interceptor
      final token = await _storage.read(key: 'jwtToken');
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.put(
        '/api/Account/identity/update-settings',
        data: settings,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('DEBUG: API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.data != null) {
          final data = response.data;
          if (data is Map<String, dynamic> &&
              data.containsKey('updatedSettings')) {
            final updatedSettings =
                data['updatedSettings'] as Map<String, dynamic>;
            return updatedSettings;
          }
          return null;
        }
      }
      return null;
    } on DioException catch (e) {
      // Logic from before
      print('DEBUG: AuthService DioError: ${e.message}');
      if (e.response?.statusCode == 400) {
        print('DEBUG: Validation Error Data: ${e.response?.data}');
      }
      // Retry on 401 Logic?
      // User requirement: "Update TrailApiService so it calls AuthService.instance.refresh()..." implies separation.
      // But updateSettings is IN here.
      // If updateSettings fails 401, we might want to refresh and retry too.
      // For now I'll just rethrow to stay simple, or implement simple retry.
      rethrow;
    } catch (e) {
      print('DEBUG: AuthService General Error: $e');
      rethrow;
    }
  }

  Future<List<Country>> fetchCountries() async {
    try {
      final response = await _dio.get('/api/Account/metadata/countries');

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
