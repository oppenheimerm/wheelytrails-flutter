import 'package:dio/dio.dart';
import 'package:app/features/auth/services/auth_service.dart';

abstract class BaseApiService {
  // The 'Source of Truth' for tokens
  final AuthService _auth = AuthService.instance;

  // Clean Dio for the Auth/DevLog calls
  final Dio publicDio = Dio(
    BaseOptions(baseUrl: 'https://api.wheelytrails.com'),
  );

  // Logic to attach the JWT to every request
  Future<Dio> get authenticatedDio async {
    final token = await _auth.getAccessToken(); // Fixed name
    return Dio(
      BaseOptions(
        baseUrl: 'https://api.wheelytrails.com',
        headers: {'Authorization': 'Bearer $token'},
        connectTimeout: const Duration(seconds: 30),
      ),
    );
  }

  /// The 'Magic' Method: Handles Retries, Refresh, and Failure Logging
  Future<Response?> safeRequest(
    Future<Response> Function(Dio) request, {
    required dynamic payload, // For logging purposes
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      attempts++;
      try {
        final dio = await authenticatedDio;
        return await request(dio);
      } on DioException catch (e) {
        // 1. Handle Expired Token (401)
        if (e.response?.statusCode == 401 && attempts == 1) {
          bool refreshed = await _auth.refresh(); // Fixed name
          if (refreshed) continue; // Loop back and try again with new token
        }

        // 2. Handle Transient Errors (5xx or Network)
        if (_isTransient(e) && attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts * 2));
          continue;
        }

        // 3. Final Failure - Log it to the anonymous endpoint
        await publicDio.post(
          '/api/dev/log-trail',
          data: {
            'error': e.message,
            'status': e.response?.statusCode,
            'data': payload,
          },
        );

        rethrow; // Pass error back to the UI to trigger Local Save
      }
    }
    return null;
  }

  bool _isTransient(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      (e.response?.statusCode ?? 0) >= 500;
}
