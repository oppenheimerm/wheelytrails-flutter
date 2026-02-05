// lib/core/providers/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/token_service.dart';
import '../network/mobile_web_service.dart';

// 1. The Service definition
// We use a basic Provider here because we override it in main.dart
final tokenServiceProvider = Provider<TokenService>((ref) {
  // This return is just a fallback; main.dart override takes priority
  return TokenService();
});

// 2. The Mobile Web Service registration
final mobileWebServiceProvider = Provider<MobileWebService>((ref) {
  final tokenService = ref.watch(tokenServiceProvider);

  // You can use a dedicated dioProvider or just create it here
  final dio = Dio();

  // Use the same storage options as your main.dart
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  return MobileWebService(dio, tokenService, storage);
});
