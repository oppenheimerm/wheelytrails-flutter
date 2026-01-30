import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/providers/auth_provider.dart'; // Contains dioProvider
import 'package:app/features/trail/models/trail_models.dart';

// Since I haven't seen the exact path for dioProvider, I'll assume it exists or I might get an error.
// Wait, I recall seeing 'verify dio injection' in task.md, so dioProvider likely exists.
// Let's check imports in auth_service if validation fails.
// Just in case, I will define a basic provider and if it fails I'll fix imports.

final trailApiServiceProvider = Provider<TrailApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return TrailApiService(dio);
});

class TrailApiService {
  final Dio _dio;

  TrailApiService(this._dio);

  Future<void> logTrailDev(WtTrail trail) async {
    try {
      await _dio.post('/api/dev/log-trail', data: trail.toJson());
    } catch (e) {
      // "Just print the error to the console"
      print('Dev Log Failed: $e');
    }
  }
}
