class TokenService {
  String? _accessToken;
  DateTime? _expiresAt;

  String? get accessToken => _accessToken;

  void setAccessToken(String token, DateTime? expiresAt) {
    _accessToken = token;
    _expiresAt = expiresAt;
  }

  void clear() {
    _accessToken = null;
    _expiresAt = null;
  }

  bool isExpired() {
    if (_accessToken == null || _expiresAt == null) return true;
    // We use Utc to match your C# backend convention
    return DateTime.now().toUtc().isAfter(_expiresAt!);
  }
}
