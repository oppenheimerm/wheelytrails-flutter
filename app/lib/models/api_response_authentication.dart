import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:app/features/auth/models/user.dart';

class ApiResponseAuthentication {
  final User? user;
  final String? jwtToken;
  final String? refreshToken;
  final bool success;
  final String message;
  final DateTime? expiresAt;

  ApiResponseAuthentication({
    this.user,
    this.jwtToken,
    this.refreshToken,
    required this.success,
    required this.message,
    this.expiresAt,
  });

  factory ApiResponseAuthentication.fromJson(Map<String, dynamic> json) {
    return ApiResponseAuthentication(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      jwtToken: json['jwtToken'],
      refreshToken: json['refreshToken'],
      success: json['success'],
      message: json['message'] ?? '',
      expiresAt: json['jwtToken'] != null
          ? JwtDecoder.getExpirationDate(json['jwtToken'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'jwtToken': jwtToken,
      'refreshToken': refreshToken,
      'success': success,
      'message': message,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
