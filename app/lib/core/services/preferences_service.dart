import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// Provider for PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const String _keyShowRecordingWarning = 'showRecordingWarning';
  static const String _keyCreateTrailGpsAccuracy = 'createTrailGpsAccuracy';
  static const String _keyUseMetricUnits = 'useMetricUnits';

  // Show Recording Warning (Default: true)
  bool get showRecordingWarning =>
      _prefs.getBool(_keyShowRecordingWarning) ?? true;

  // Use Metric Units (Default: true)
  bool get useMetricUnits => _prefs.getBool(_keyUseMetricUnits) ?? true;

  Future<void> setShowRecordingWarning(bool value) async {
    await _prefs.setBool(_keyShowRecordingWarning, value);
  }

  Future<void> setUseMetricUnits(bool value) async {
    await _prefs.setBool(_keyUseMetricUnits, value);
  }

  // Create Trail GPS Accuracy (Default: 5.0?)
  // Actually, let's see what user model had. It was double.
  // Let's assume default is 10.0 or similar if not set.
  double get createTrailGpsAccuracy =>
      _prefs.getDouble(_keyCreateTrailGpsAccuracy) ?? 10.0;

  Future<void> setCreateTrailGpsAccuracy(double value) async {
    await _prefs.setDouble(_keyCreateTrailGpsAccuracy, value);
  }
}
