import 'package:app/core/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// 1. Define the model to match your new JSON response
class TrailMetadata {
  final List<dynamic> countries;
  final List<dynamic> difficulties;
  final List<dynamic> surfaces;

  TrailMetadata({
    required this.countries,
    required this.difficulties,
    required this.surfaces,
  });
}

// 2. The updated provider
final trailMetadataProvider = FutureProvider<TrailMetadata>((ref) async {
  final dio = Dio();
  final baseUrl = ApiConstants.baseUrl;

  try {
    // Fetch all metadata in parallel
    final results = await Future.wait([
      dio.get('$baseUrl${ApiConstants.getCountries}'),
      dio.get('$baseUrl${ApiConstants.getDifficulties}'),
      dio.get('$baseUrl${ApiConstants.getSurfaces}'),
    ]);

    return TrailMetadata(
      countries: results[0].data as List<dynamic>,
      difficulties: results[1].data as List<dynamic>,
      surfaces: results[2].data as List<dynamic>,
    );
  } catch (e) {
    // Log the error for easier debugging during your music session!
    print('DEBUG: Metadata Fetch Error: $e');
    rethrow;
  }
});
