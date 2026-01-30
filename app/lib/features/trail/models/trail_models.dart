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
  final int surfaceFlags;
  final int difficulty;
  final DateTime createdAt;

  WtTrail({
    required this.id,
    required this.points,
    required this.pois,
    this.surfaceFlags = 0,
    this.difficulty = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points
          .map(
            (p) => {
              'lat': p.lat,
              'lng': p.lng,
              'altitude': p.altitude,
              'timestamp': p.timestamp?.toIso8601String(),
            },
          )
          .toList(),
      'pois': pois
          .map(
            (p) => {
              'id': p.id,
              'location': {'lat': p.location.lat, 'lng': p.location.lng},
              'type': p.type,
              'notes': p.notes,
              'createdAt': p.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'surfaceFlags': surfaceFlags,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
