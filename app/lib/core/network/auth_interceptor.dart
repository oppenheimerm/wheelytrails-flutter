import 'package:app/features/auth/models/auth_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/*
  ApplicationUser Changes: Because we removed those legacy properties, the 
  newJwt in the response will be smaller, and your local user model won't 
  crash when it parses the new token.

  DevLog Security: Since you've made the api/dev/log-trail endpoint 
  [AllowAnonymous], you should have a separate public Dio instance 
  (without this interceptor) specifically for logging. This way, if the 
  refresh fails, you can still send a log saying "Refresh Failed" without 
  getting another 401.
 */

class AuthInterceptor extends QueuedInterceptor {
  final Dio mainDio;
  // Use a separate Dio instance for refreshing to avoid deadlocks
  final Dio refreshDio = Dio(
    BaseOptions(baseUrl: 'https://api.wheelytrails.com'),
  );

  AuthInterceptor(this.mainDio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final storage = const FlutterSecureStorage();
      String? refreshToken = await storage.read(key: 'refreshToken');

      try {
        // 1. Attempt the refresh using the SEPARATE dio instance
        final response = await refreshDio.post(
          '/api/account/identity/refresh',
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200) {
          final newJwt = response.data['jwtToken'];
          final newRefresh = response.data['refreshToken'];

          // 2. Save new tokens
          await storage.write(key: 'jwtToken', value: newJwt);
          await storage.write(key: 'refreshToken', value: newRefresh);

          // 3. Update headers and RETRY the original request
          err.requestOptions.headers['Authorization'] = 'Bearer $newJwt';

          // We use mainDio.fetch here to put the request back into the stream
          final responseRetry = await mainDio.fetch(err.requestOptions);
          return handler.resolve(responseRetry);
        }
      } catch (refreshErr) {
        // If refresh fails, the session is truly dead
        // Log out user/Redirect to login
      }
    }
    return super.onError(err, handler);
  }
}
