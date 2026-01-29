class User {
  final String id;
  final String firstName;
  final String profileUsername;
  final String email;
  final String? profilePicture;
  final List<Role> roles;
  final String countryCode;
  final String bio;
  final DateTime registrationDate;
  final double gpsAccuracy;
  final bool showRecordingWarning;

  User({
    required this.id,
    required this.firstName,
    required this.profileUsername,
    required this.email,
    this.profilePicture,
    required this.roles,
    required this.countryCode,
    required this.bio,
    required this.registrationDate,
    required this.gpsAccuracy,
    required this.showRecordingWarning,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      profileUsername: json['profileUsername'],
      email: json['email'],
      profilePicture: json['profilePicture'],
      roles: (json['roles'] as List).map((i) => Role.fromJson(i)).toList(),
      countryCode: json['countryCode'],
      bio: json['bio'],
      registrationDate: DateTime.parse(json['registrationDate']),
      gpsAccuracy: (json['gpsAccuracy'] as num).toDouble(),
      showRecordingWarning: json['showRecordingWarning'],
    );
  }

  // copyWith method for state merging
  User copyWith({
    String? firstName,
    String? bio,
    String? countryCode,
    double? gpsAccuracy,
    bool? showRecordingWarning,
    // Add other fields as needed if they become updatable
  }) {
    return User(
      id: id,
      firstName: firstName ?? this.firstName,
      profileUsername: profileUsername,
      email: email,
      profilePicture: profilePicture,
      roles: roles,
      countryCode: countryCode ?? this.countryCode,
      bio: bio ?? this.bio,
      registrationDate: registrationDate,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      showRecordingWarning: showRecordingWarning ?? this.showRecordingWarning,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'profileUsername': profileUsername,
      'email': email,
      'profilePicture': profilePicture,
      'roles': roles.map((e) => e.toJson()).toList(),
      'countryCode': countryCode,
      'bio': bio,
      'registrationDate': registrationDate.toIso8601String(),
      'gpsAccuracy': gpsAccuracy,
      'showRecordingWarning': showRecordingWarning,
    };
  }
}

class Role {
  final String roleName;

  Role({required this.roleName});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(roleName: json['roleName']);
  }

  Map<String, dynamic> toJson() {
    return {'roleName': roleName};
  }
}
