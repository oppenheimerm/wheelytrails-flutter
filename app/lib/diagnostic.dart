import 'package:dio/dio.dart';

Future<void> main() async {
  print('--- Starting Diagnostic: Naked POST ---');
  // Use a fresh Dio() instance with NO base options or interceptors.
  final dio = Dio();

  final url = 'https://api.wheelytrails.com/api/dev/log-trail';
  final payload = {
    "title": "Diagnostic",
    "errorMessage": "Testing raw connection",
  };

  print('Target URL: $url');
  print('Payload: $payload');
  print('Authorization: NONE (Intentional)');

  try {
    final response = await dio.post(
      url,
      data: payload,
      // Ensure no headers are slipped in (default dio doesn't add any auth, but good to be sure)
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    print('\n[SUCCESS]');
    print('Status Code: ${response.statusCode}');
    print('Response Data: ${response.data}');
    print(
      '\n>>> CONCLUSION: The issue is likely in the App Architecture (BaseApiService/AuthInterceptor).',
    );
  } on DioException catch (e) {
    print('\n[FAILURE] DioException');
    print('Type: ${e.type}');
    print('Message: ${e.message}');
    if (e.response != null) {
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
      print('Headers: ${e.response?.headers}');
    }

    print(
      '\n>>> CONCLUSION: The issue is likely Server-Side (CORS, Firewall) or Network.',
    );
  } catch (e) {
    print('\n[FAILURE] Unexpected Error: $e');
  }
}
