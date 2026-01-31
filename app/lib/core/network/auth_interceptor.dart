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

class AuthInterceptor extends Interceptor {
  // We removed the mainDio/refreshDio fields as we don't do refresh here anymore.

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Basic JWT attachment
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwtToken');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
