import 'package:app/features/auth/models/user.dart';

class AuthResponse {
  final User? user;
  final String? jwtToken;
  final String? refreshToken;
  final bool success;
  final String message;

  AuthResponse({
    this.user,
    this.jwtToken,
    this.refreshToken,
    required this.success,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      jwtToken: json['jwtToken'],
      refreshToken: json['refreshToken'],
      success: json['success'],
      message: json['message'],
    );
  }
}
