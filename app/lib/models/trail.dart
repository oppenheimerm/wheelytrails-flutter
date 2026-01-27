enum DifficultyLevel {
  easy,
  moderate,
  hard,
}

enum SurfaceType {
  paved,
  gravel,
  grass,
  dirt,
  sand,
  unknown,
}

class Trail {
  final String id;
  final String name;
  final String description;
  final SurfaceType surfaceType;
  final String location;
  final double distance; // in km
  final DifficultyLevel difficulty;
  final String imageUrl;

  const Trail({
    required this.id,
    required this.name,
    required this.description,
    required this.surfaceType,
    required this.location,
    required this.distance,
    required this.difficulty,
    required this.imageUrl,
  });
}
