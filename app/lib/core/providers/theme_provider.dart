import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys
const _themePrefsKey = 'theme_mode';

// Theme Provider
final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  () {
    return ThemeController();
  },
);

class ThemeController extends Notifier<ThemeMode> {
  final ThemeMode? _initialOverride;

  ThemeController([this._initialOverride]);

  @override
  ThemeMode build() {
    return _initialOverride ?? ThemeMode.system;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    await _persistTheme(newMode);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _persistTheme(mode);
  }

  Future<void> _persistTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    // storing as string or index
    // Using string for readability: "ThemeMode.light"
    await prefs.setString(_themePrefsKey, mode.toString());
  }
}
