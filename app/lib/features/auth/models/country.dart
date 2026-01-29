class Country {
  final String code;
  final String name;
  final Map<String, double> capital;

  Country({required this.code, required this.name, required this.capital});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'],
      name: json['name'],
      capital: Map<String, double>.from(json['capital']),
    );
  }
}
