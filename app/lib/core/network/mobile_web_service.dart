import 'package:app/models/api_response_authentication.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/network/token_service.dart';
import 'package:app/core/api_constants.dart';

class MobileWebService {
  final Dio _httpClient;
  final TokenService _tokenService;
  final FlutterSecureStorage _secureStorage;

  MobileWebService(this._httpClient, this._tokenService, this._secureStorage);

  /// Ensure the Authorization header is set (Manual port of EnsureAuthorizationHeaderAsync)
Future<ApiResponseAuthentication?> _tryGetRefreshTokenAsync() async {
  try {
    // 1. Get the persistent refresh token from the vault
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) {
      print("⚠️ No refresh token in SecureStorage. User must log in.");
      return null;
    }

    // 2. Call the identity refresh endpoint
    final response = await _httpClient.post(
      ApiConstants.fullUrl(ApiConstants.refreshToken),
      data: {"refreshToken": refreshToken},
      // Important: clear headers so we don't send the expired Bearer token
      options: Options(headers: {}), 
    );

    if (response.statusCode == 200) {
      final result = ApiResponseAuthentication.fromJson(response.data);
      
      if (result.jwtToken != null) {
        // 3. Sync back to memory immediately. 
        // We pass 'null' for expiry since we are letting 401s handle it.
        _tokenService.setAccessToken(result.jwtToken!, result.expiresAt);
        
        // 4. Update the current HTTP client's default header for future calls
        _httpClient.options.headers["Authorization"] = "Bearer ${result.jwtToken}";
        
        print("✅ Token refreshed successfully.");
        return result;
      }
    }
    return null;
  } catch (e) {
    print("🔥 Refresh request failed: $e");
    return null;
  }
}
  // Ignore this method for now
  /// THE CONVENTION: Standard Authenticated Request Loop
  /*Future<ApiResponseAuthentication> getAccountSettingsAsync() async {
    const int maxRetries = 3;
    int currentAttempt = 0;
    bool tokenWasRefreshed = false;

    try {
      if (!await _ensureAuthorizationHeaderAsync()) {
        return APIResponseViewAccountSettings(success: false, message: "User is not authenticated");
      }

      while (currentAttempt < maxRetries) {
        currentAttempt++;
        try {
          final response = await _httpClient.get("api/account/identity/settings");

          if (response.statusCode == 200) {
            return APIResponseViewAccountSettings.fromJson(response.data);
          }
        } on DioException catch (e) {
          // UNAUTHORIZED
          if (e.response?.statusCode == 401 && !tokenWasRefreshed) {
            print("⚠️ Token expired, attempting refresh...");
            final refreshed = await _tryGetRefreshTokenAsync();
            
            if (refreshed != null && refreshed.jwtToken != null) {
              tokenWasRefreshed = true;
              _httpClient.options.headers["Authorization"] = "Bearer ${refreshed.jwtToken}";
              currentAttempt--; 
              continue; 
            } else {
              return APIResponseViewAccountSettings(success: false, message: "Session expired.");
            }
          }
          
          // SERVER ERROR RETRY
          if ((e.response?.statusCode ?? 500) >= 500) {
            if (currentAttempt < maxRetries) {
               await Future.delayed(Duration(seconds: currentAttempt));
               continue;
            }
          }
          break; // Exit loop on 4xx or fatal errors
        }
      }
      return APIResponseViewAccountSettings(success: false, message: "Request failed after retries.");
    } catch (ex) {
      return APIResponseViewAccountSettings(success: false, message: "Unexpected error: $ex");
    }
  }
}*/