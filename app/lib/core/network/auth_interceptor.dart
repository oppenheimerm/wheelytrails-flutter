import 'package:app/features/auth/models/auth_response.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Ref _ref;

  AuthInterceptor(this._dio, this._storage, this._ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('DEBUG: AuthInterceptor.onRequest for ${options.path}');
    try {
      final token = await _storage.read(key: 'jwtToken');
      if (token != null) {
        options.headers['Authorization'] =
            'Bearer $token'; // Ensure Bearer scheme
      }
      handler.next(options);
    } catch (e) {
      print('DEBUG: AuthInterceptor error reading token: $e');
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      print('DEBUG: 401 Detected. Attempting refresh...');

      final refreshToken = await _storage.read(key: 'refreshToken');
      // final jwtToken = await _storage.read(key: 'jwtToken'); // Not needed for new endpoint?

      if (refreshToken != null) {
        try {
          // Use a fresh Dio for refresh to avoid loops/interceptors
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: _dio.options.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

          print('DEBUG: POSTing refresh token...');
          // Updated payload as requested: {"refreshToken": "..."}
          final response = await refreshDio.post(
            'https://api.wheelytrails.com/api/account/identity/refresh-token',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final authResponse = AuthResponse.fromJson(response.data);
            if (authResponse.success && authResponse.jwtToken != null) {
              print('DEBUG: Refresh successful. Saving new tokens.');
              await _storage.write(
                key: 'jwtToken',
                value: authResponse.jwtToken,
              );
              await _storage.write(
                key: 'refreshToken',
                value: authResponse.refreshToken,
              );

              // Retry the original request
              final options = err.requestOptions;
              options.headers['Authorization'] =
                  'Bearer ${authResponse.jwtToken}';

              final cloneReq = await _dio.fetch(options);
              return handler.resolve(cloneReq);
            }
          }
        } catch (e) {
          print('DEBUG: Refresh failed: $e');
        }
      }

      // If we reach here, refresh failed or no token.
      print(
        'DEBUG: Refresh failed or invalid. Clearing session and logging out.',
      );
      await _storage.deleteAll();
      // Trigger logout in AuthController lazily to update UI
      _ref.read(authControllerProvider.notifier).logout();
    }
    handler.next(err);
  }
}
