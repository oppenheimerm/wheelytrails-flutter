import 'package:app/features/auth/models/auth_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'jwtToken');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refreshToken');
      final jwtToken = await _storage.read(key: 'jwtToken');

      if (refreshToken != null && jwtToken != null) {
        try {
          print('Auth: Refreshing token at correct endpoint...');
          final response = await _dio.post(
            'https://api.wheelytrails.com/api/account/identity/refresh-token',
            data: {'jwtToken': jwtToken, 'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final authResponse = AuthResponse.fromJson(response.data);
            if (authResponse.success && authResponse.jwtToken != null) {
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
          // Refresh failed, assume logout or handle error
          return handler.next(err);
        }
      }
    }

    handler.next(err);
  }
}
