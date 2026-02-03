import 'package:app/core/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/features/auth/services/auth_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _testUpdateSettings(BuildContext context) async {
    const storage = FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      wOptions: WindowsOptions(),
    );

    try {
      // 1. MANUALLY trigger a refresh before the call
      // This proves the AuthService.refresh() logic works without an interceptor
      _showSnack(context, "🔄 Refreshing token manually...", Colors.orange);
      final isRefreshed = await AuthService.instance.refresh();

      if (!isRefreshed) {
        _showResultDialog(
          context,
          "❌ Refresh Failed",
          "Could not get a new token.",
        );
        return;
      }

      // 2. Now get the FRESH token
      final token = await AuthService.instance.getAccessToken();

      // 3. Make the call
      final response = await Dio().put(
        ApiConstants.fullUrl(ApiConstants.updateSettings),
        data: {
          "firstName": null,
          "bio": "Manual Refresh Test",
          "countryCode": "IE",
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      _showResultDialog(
        context,
        "✅ SUCCESS",
        "Status: ${response.statusCode}\nManual refresh worked!",
      );
    } on DioException catch (e) {
      // Extract the specific error details
      final status = e.response?.statusCode;
      final errorData = e.response?.data;
      final uri = e.requestOptions.uri;

      debugPrint("🚨 ERROR STATUS: $status");
      debugPrint("🚨 ERROR DATA: $errorData");
      debugPrint("🚨 TRIED URL: $uri");

      _showResultDialog(
        context,
        "❌ SAVE FAILED ($status)",
        "URL: $uri\n\nServer Message: $errorData",
      );
    }
  }

  void _showResultDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text("OK")),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Favorites Screen'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _testUpdateSettings(context),
            icon: const Icon(Icons.security),
            label: const Text('Test Authenticated Log'),
          ),
        ],
      ),
    );
  }
}
