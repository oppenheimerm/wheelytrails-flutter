class ApiConstants {
  static const String baseUrl = 'https://api.wheelytrails.com';

  // Identity Endpoints
  static const String login = '/api/account/identity/login';
  static const String refreshToken = '/api/account/identity/refresh-token';
  static const String updateSettings = '/api/account/identity/update-settings';

  // Trails Endpoints
  static const String createTrail = '/api/trails';

  //  Metadata Endpoints
  static const String getCountries = '/api/metadata/countries';
  static const String getDifficulties = '/api/metadata/trail-difficulties';
  static const String getSurfaces = '/api/metadata/surface-types';

  // A helper to get the full URL safely
  static String fullUrl(String endpoint) => '$baseUrl$endpoint';
}
