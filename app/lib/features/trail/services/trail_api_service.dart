import 'dart:convert';
import 'dart:io';

import 'package:app/core/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/trail/models/trail_models.dart';

import 'package:path_provider/path_provider.dart';
import 'package:app/core/network/base_api_service.dart';

final trailApiServiceProvider = Provider<TrailApiService>((ref) {
  final dio = ref.watch(dioProvider);
  final publicDio = ref.watch(publicDioProvider);
  return TrailApiService(dio, publicDio);
});

enum CreateTrailResult { success, offlineDraft }

class TrailApiService extends BaseApiService {
  final Dio _dio;
  final Dio _publicDio;

  TrailApiService(this._dio, this._publicDio);

  Future<void> logTrailDev(WtTrail trail) async {
    try {
      await _publicDio.post('/api/dev/log-trail', data: trail.toJson());
    } catch (e) {
      print('Dev Log Failed: $e');
    }
  }

  /// Saves the DTO locally as a JSON file in /draft_trails
  Future<void> _saveDraftLocally(CreateTrailDTO dto) async {
    try {
      print('DEBUG: Attempting to save draft locally...');
      final directory = await getApplicationDocumentsDirectory();
      final draftsDir = Directory('${directory.path}/draft_trails');
      if (!await draftsDir.exists()) {
        await draftsDir.create(recursive: true);
      }

      // Use timestamp for filename for now
      final filename = 'draft_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${draftsDir.path}/$filename');

      await file.writeAsString(jsonEncode(dto.toJson()));
      print('DEBUG: Draft saved to ${file.path}');
    } catch (e) {
      print('DEBUG: Failed to save draft locally: $e');
    }
  }

  /// Returns CreateTrailResult to indicate if sync was immediate or saved as draft
  Future<CreateTrailResult> createTrail(CreateTrailDTO trailDto) async {
    try {
      // 1. Attempt the standard authenticated request
      await safeRequest(
        (dio) => dio.post(
          ApiConstants.createTrail, // /api/Trails
          data: trailDto.toJson(),
        ),
        payload: trailDto.toJson(),
      );
      return CreateTrailResult.success;
    } catch (e) {
      // 2. PRIMARY SYNC FAILED: Log the error to the dev endpoint
      print('DEBUG: API Sync Failed: $e');

      // We use _logFallback which uses the public (unauthenticated) Dio
      // to ensure the error gets through even if auth was the issue.
      await _logFallback(trailDto, e.toString());

      // 3. Save locally so the user doesn't lose their hard-earned GPS data
      await _saveDraftLocally(trailDto);

      return CreateTrailResult.offlineDraft;
    }
  }

  Future<void> _logFallback(CreateTrailDTO dto, String error) async {
    try {
      final payload = {'errorMessage': error, 'trail': dto.toJson()};
      await _publicDio.post('/api/dev/log-trail', data: payload);
      print('DEBUG: Fallback log (Draft) sent successfully.');
    } catch (e) {
      print('DEBUG: Fallback log ALSO failed: $e');
    }
  }
}
