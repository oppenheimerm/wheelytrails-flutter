import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Likely needed if Position is confused or if user wants maps here

/// Provider to access the authentic LocationService instance
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Stream provider for service status changes
final locationServiceStatusProvider = StreamProvider<ServiceStatus>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.getServiceStatusStream();
});

class LocationService {
  /// Stream of location service status changes (enabled/disabled)
  Stream<ServiceStatus> getServiceStatusStream() {
    return Geolocator.getServiceStatusStream();
  }

  /// Requests permission and returns true if authorized.
  /// Handles the flow: Disabled -> Denied -> DeniedForever -> Allowed
  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

  /// Check if location services are currently enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get the current position (single reading)
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  /// Get a stream of position updates for tracking
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    // Default settings customized for trail recording
    // 5 meters distance filter to reduce noise when stationary
    // High accuracy for best trail mapping
    const defaultSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings ?? defaultSettings,
    );
  }
}
