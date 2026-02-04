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

class WtTrail {
  final String id;
  final List<WtLatLng> points;
  final List<WtPoi> pois;
  final String surfaceType;
  final String difficulty; // kept as int relative to legacy, but could be enum
  final DateTime createdAt;

  WtTrail({
    required this.id,
    required this.points,
    required this.pois,
    required this.surfaceType,
    required this.difficulty,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'pois': pois.map((p) => p.toJson()).toList(),
      'surfaceType': surfaceType,
      'difficulty': difficulty, // Assuming int
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// DTO for creating a new trail
class CreateTrailDTO {
  final String title;
  final String description;
  final String difficulty; // 4 letter code
  final String surfaceType; // 4 letter code
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
    required this.surfaceType,
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
      'surfaceType': surfaceType,
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
      'waypoints': waypoints.map((p) => p.toJson()).toList(),
      'pois': pois.map((p) => p.toJson()).toList(),
      'elevationProfile': elevationProfile,
      'lengthMeters': lengthMeters,
    };
  }
}
