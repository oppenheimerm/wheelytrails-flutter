import 'dart:async';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/trail/models/trail_models.dart';
import 'package:app/features/trail/models/trail_enums.dart';
import 'package:app/features/trail/services/location_service.dart';
import 'package:app/features/trail/services/trail_api_service.dart'; // Add import
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum StopRecordingResult { success, tooShort }

// State class for the controller
class TrailRecordState {
  final List<WtLatLng> points;
  final List<WtPoi> pois;
  final bool isRecording;
  final bool isPaused;
  final Duration elapsedTime;
  final double distanceKm;
  final LatLng? lastKnownLocation;
  final double currentElevation;
  final bool permissionGranted;

  const TrailRecordState({
    this.points = const [],
    this.pois = const [],
    this.isRecording = false,
    this.isPaused = false,
    this.elapsedTime = Duration.zero,
    this.distanceKm = 0.0,
    this.lastKnownLocation,
    this.currentElevation = 0.0,
    this.permissionGranted = false,
  });

  TrailRecordState copyWith({
    List<WtLatLng>? points,
    List<WtPoi>? pois,
    bool? isRecording,
    bool? isPaused,
    Duration? elapsedTime,
    double? distanceKm,
    LatLng? lastKnownLocation,
    double? currentElevation,
    bool? permissionGranted,
  }) {
    return TrailRecordState(
      points: points ?? this.points,
      pois: pois ?? this.pois,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      distanceKm: distanceKm ?? this.distanceKm,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      currentElevation: currentElevation ?? this.currentElevation,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}

final trailRecordControllerProvider =
    StateNotifierProvider<TrailRecordController, TrailRecordState>((ref) {
      final locationService = ref.watch(locationServiceProvider);
      final authState = ref.read(authControllerProvider);
      final countries = ref.read(countriesProvider).asData?.value ?? [];
      // Assuming we fix the provider path or define it.
      // For now, let's assume trailApiServiceProvider is available or we define it in the controller file temporarily if needed,
      // but better to import it.
      final apiService = ref.read(trailApiServiceProvider);

      return TrailRecordController(
        locationService,
        apiService, // Add this
        authUser: authState.user,
        countries: countries,
      );
    });

class TrailRecordController extends StateNotifier<TrailRecordState> {
  final LocationService _locationService;
  final TrailApiService _apiService; // Add this
  final dynamic _authUser;
  final List<dynamic> _countries;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _recordingTimer;
  Timer? _heartbeatTimer;

  TrailRecordController(
    this._locationService,
    this._apiService, { // Add this
    required dynamic authUser,
    required List<dynamic> countries,
  }) : _authUser = authUser,
       _countries = countries,
       super(const TrailRecordState());
  // ... (skip down to stopRecording)

  Future<StopRecordingResult> stopRecording() async {
    _recordingTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _positionSubscription?.cancel();

    // Minimum Data Guard
    if (state.points.length < 2) {
      // Too short
      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        points: [],
        pois: [],
        elapsedTime: Duration.zero,
        distanceKm: 0.0,
      );
      return StopRecordingResult.tooShort;
    }

    // Prepare Trail Object
    final trail = WtTrail(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // or Guid
      points: state.points,
      pois: state.pois,
      // We need to calculate flags? Or just use default 0.
      // User said "Construct the full WtTrail object... surfaceFlags".
      // We don't have surface selection in UI yet, so 0 is fine.
      surfaceFlags: 0,
      difficulty: 0,
      createdAt: DateTime.now(),
    );

    // LOG TO DEV
    // Fire and forget so we don't await/block UI?
    // User said "Immediately call... If the dev log fails... just print".
    _apiService.logTrailDev(trail);

    state = state.copyWith(isRecording: false, isPaused: false);
    return StopRecordingResult.success;
  }

  /// Initialize: Check permissions and set initial location
  Future<void> initialize() async {
    final bool hasPermission = await _locationService.checkPermission();

    LatLng? startLocation;
    try {
      final position = await _locationService.getCurrentPosition();
      startLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('TrailController: Failed to get current location: $e');
    }

    if (startLocation == null && _authUser != null) {
      final countryCode = _authUser.countryCode;
      final userCountry = _countries.firstWhere(
        (c) => c.code == countryCode,
        orElse: () => null,
      );

      if (userCountry != null && userCountry.capital != null) {
        final lat = userCountry.capital['lat'];
        final lng = userCountry.capital['lng'];
        if (lat != null && lng != null) {
          startLocation = LatLng(lat, lng);
        }
      }
    }

    state = state.copyWith(
      permissionGranted: hasPermission,
      lastKnownLocation: startLocation,
    );
  }

  Future<void> startRecording() async {
    if (!state.isRecording && !state.isPaused) {
      state = state.copyWith(
        points: [],
        pois: [],
        elapsedTime: Duration.zero,
        distanceKm: 0.0,
        isRecording: true,
        isPaused: false,
      );
    } else {
      state = state.copyWith(isRecording: true, isPaused: false);
    }
    _startTimers();
    _startGpsStream();
  }

  void pauseRecording() {
    state = state.copyWith(isPaused: true);
    // Keep timer running as requested, but stop GPS accumulation (handled in stream)
  }

  int calculateSurfaceFlags(List<SurfaceType> selectedTypes) {
    return calculateTotalSurfaceValue(selectedTypes);
  }

  void addPoi(PoiType type, String? note) {
    if (state.lastKnownLocation == null) return;

    final location = WtLatLng(
      state.lastKnownLocation!.latitude,
      state.lastKnownLocation!.longitude,
      altitude: state.currentElevation,
      timestamp: DateTime.now(),
    );

    final poi = WtPoi(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      location: location,
      type: type.code,
      notes: note ?? '',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(pois: [...state.pois, poi]);
  }

  void _startTimers() {
    _recordingTimer?.cancel();
    _heartbeatTimer?.cancel();

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(
        elapsedTime: state.elapsedTime + const Duration(seconds: 1),
      );
    });

    _heartbeatTimer = Timer.periodic(const Duration(minutes: 20), (timer) {
      if (state.isRecording) {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.click);
      }
    });
  }

  void _startGpsStream() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen((
      position,
    ) {
      final latLng = LatLng(position.latitude, position.longitude);
      final wtLatLng = WtLatLng(
        position.latitude,
        position.longitude,
        altitude: position.altitude,
        timestamp: position.timestamp,
      );

      var newState = state.copyWith(
        lastKnownLocation: latLng,
        currentElevation: position.altitude,
      );

      if (state.isRecording && !state.isPaused) {
        // Determine if we should add the point (Distance filter check)
        // Geolocator stream already has distanceFilter=5m, so we can trust the stream events
        // essentially represent ~5m moves.

        double newDist = state.distanceKm;
        if (state.points.isNotEmpty) {
          final last = state.points.last;
          final distMeters = Geolocator.distanceBetween(
            last.lat,
            last.lng,
            wtLatLng.lat,
            wtLatLng.lng,
          );
          newDist += (distMeters / 1000.0);
        }

        newState = newState.copyWith(
          points: [...state.points, wtLatLng],
          distanceKm: newDist,
        );
      }

      state = newState;
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _heartbeatTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
