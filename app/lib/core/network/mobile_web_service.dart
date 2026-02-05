import 'package:app/core/api_constants.dart';
import 'package:app/models/api_response_authentication.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_service.dart';

class MobileWebService {
  final Dio _httpClient;
  final TokenService _tokenService;
  final FlutterSecureStorage _secureStorage;

  MobileWebService(this._httpClient, this._tokenService, this._secureStorage);

  // ---------------------------------------------------------------------------
  // PUBLIC API: Presentation layer calls only these
  // ---------------------------------------------------------------------------

  Future<bool> logDevMessageAsync(String message) async {
    const int maxRetries = 3;
    int currentAttempt = 0;
    bool tokenWasRefreshed = false;

    if (!await _ensureAuthorizationHeaderAsync()) return false;

    while (currentAttempt < maxRetries) {
      currentAttempt++;
      try {
        final response = await _httpClient.post(
          ApiConstants.fullUrl('api/dev/log-trail'),
          data: {'Message': message},
        );
        return response.statusCode == 200 || response.statusCode == 201;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 && !tokenWasRefreshed) {
          if (await _tryGetRefreshTokenAsync() != null) {
            tokenWasRefreshed = true;
            currentAttempt--; 
            continue;
          }
        }
        if ((e.response?.statusCode ?? 500) >= 500 && currentAttempt < maxRetries) {
          await Future.delayed(Duration(seconds: currentAttempt));
          continue;
        }
        break; 
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // PRIVATE LOGIC: Encapsulated "dirty work"
  // ---------------------------------------------------------------------------

  Future<bool> _ensureAuthorizationHeaderAsync() async {
    if (_tokenService.accessToken != null && !_tokenService.isExpired()) {
      _httpClient.options.headers["Authorization"] = "Bearer ${_tokenService.accessToken}";
      return true;
    }
    return (await _tryGetRefreshTokenAsync()) != null;
  }

  Future<ApiResponseAuthentication?> _tryGetRefreshTokenAsync() async {
    try {
      final rt = await _secureStorage.read(key: 'refresh_token');
      if (rt == null) return null;

      final response = await _httpClient.post(
        ApiConstants.fullUrl(ApiConstants.refreshToken),
        data: {"refreshToken": rt},
        options: Options(headers: {}), // Don't send old Bearer
      );

      if (response.statusCode == 200) {
        final result = ApiResponseAuthentication.fromJson(response.data);
        _tokenService.setAccessToken(result.jwtToken!, result.expiresAt);
        _httpClient.options.headers["Authorization"] = "Bearer ${result.jwtToken}";
        return result;
      }
    } catch (_) {}
    return null;
  }
}
