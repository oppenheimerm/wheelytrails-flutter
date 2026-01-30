/// Represents a geographical coordinate consisting of latitude and longitude.
/// Latitude and Longitude are for route drawing
/// Altitude -> for elevation graph
/// Timestamp -> for time-based data
class WtLatLng {
  final double lat;
  final double lng;
  final double? altitude;
  final DateTime? timestamp;

  WtLatLng(this.lat, this.lng, {this.altitude, this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'altitude': altitude,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class PoiType {
  final String code;
  final String name;

  const PoiType(this.code, this.name);
}

/// Domain entity representing a Point of Interest (POI)
class WtPoi {
  final String id;
  final WtLatLng location;
  final String type; // e.g. "VIEW", "ACCS"
  final String notes;
  final DateTime createdAt;

  WtPoi({
    required this.id,
    required this.location,
    required this.type,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location.toJson(),
      'type': type,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Static list of POI Types
const List<PoiType> poiTypes = [
  PoiType("VIEW", "Scenic Viewpoint"),
  PoiType("REST", "Rest Area"),
  PoiType("INFO", "Information Center"),
  PoiType("FOOD", "Food Stand"),
  PoiType("FDRT", "Restaurant"),
  PoiType("FDBR", "Bar"),
  PoiType("SHOP", "Shop"),
  PoiType("SPRT", "Sport Venue"),
  PoiType("TOIL", "Toilet Facility"),
  PoiType("ACCS", "Accessibility Feature"),
  PoiType("HIST", "Historical Site"),
  PoiType("BEAC", "Beach"),
  PoiType("DOCK", "Dock / Boardwalk"),
  PoiType("LAKE", "Lake"),
  PoiType("RIVR", "River"),
  PoiType("WATR", "Waterfall"),
  PoiType("MNTN", "Mountain Peak"),
  PoiType("NATU", "Natural Reserve"),
  PoiType("OBST", "Obstruction"),
  PoiType("CNST", "Construction"),
  PoiType("OBSV", "Observation Deck"),
  PoiType("HOSP", "Hospital"),
  PoiType("FSTN", "First Aid Station"),
  PoiType("OTHR", "Other"),
];

// Difficulty Level Enum
enum DifficultyLevel {
  easy(0, "Easy"),
  medium(1, "Medium"),
  hard(2, "Hard");

  final int value;
  final String label;
  const DifficultyLevel(this.value, this.label);
}

// Surface Types Enum (Bitwise Flags)
enum SurfaceType {
  none(0, "Unknown"),
  paved(1, "Paved"), // 1 << 0
  grass(2, "Grass"), // 1 << 1
  gravel(4, "Gravel"), // 1 << 2
  boardwalk(8, "Boardwalk"), // 1 << 3
  road(16, "Road"), // 1 << 4
  dirt(32, "Dirt"), // 1 << 5
  rubber(64, "Rubber"); // 1 << 6

  final int value;
  final String label;
  const SurfaceType(this.value, this.label);

  // Helper to check if this flag is present in a value
  bool isPresent(int flags) => (flags & value) == value;
}

class WtTrail {
  final String id;
  final List<WtLatLng> points;
  final List<WtPoi> pois;
  final int surfaceFlags;
  final int difficulty; // kept as int relative to legacy, but could be enum
  final DateTime createdAt;

  WtTrail({
    required this.id,
    required this.points,
    required this.pois,
    this.surfaceFlags = 0,
    required int difficultyValue,
    required this.createdAt,
  }) : difficulty = difficultyValue; // Assign to dynamic logic if needed

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'pois': pois.map((p) => p.toJson()).toList(),
      'surfaceFlags': surfaceFlags,
      'difficulty': difficulty, // Assuming int
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// DTO for creating a new trail
class CreateTrailDTO {
  final String title;
  final String description;
  final int difficulty;
  final int surfaceFlags;
  final WtLatLng startLocation;
  final WtLatLng endLocation;
  final List<WtLatLng> waypoints;
  final List<WtPoi> pois;
  final List<double> elevationProfile;
  final double lengthMeters;

  CreateTrailDTO({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.surfaceFlags,
    required this.startLocation,
    required this.endLocation,
    required this.waypoints,
    required this.pois,
    required this.elevationProfile,
    required this.lengthMeters,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'surfaceFlags': surfaceFlags,
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
      'waypoints': waypoints.map((p) => p.toJson()).toList(),
      'pois': pois.map((p) => p.toJson()).toList(),
      'elevationProfile': elevationProfile,
      'lengthMeters': lengthMeters,
    };
  }
}
