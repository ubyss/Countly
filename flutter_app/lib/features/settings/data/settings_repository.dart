import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'countly.themeMode';
const _legacyDarkModeKey = 'countly.darkMode';
const _introSeenKey = 'countly.introSeen';
const _viewModeKey = 'countly.counterViewMode';

/// Preferências gerais do app (tema, onboarding, modo de visualização).
class SettingsRepository {
  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    if (stored != null) {
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => ThemeMode.system,
      );
    }
    // Migração da preferência booleana legada.
    final legacyDark = prefs.getBool(_legacyDarkModeKey);
    if (legacyDark != null) {
      return legacyDark ? ThemeMode.dark : ThemeMode.light;
    }
    return ThemeMode.system;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introSeenKey) ?? false;
  }

  Future<void> markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introSeenKey, true);
  }

  Future<String?> loadCounterViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_viewModeKey);
  }

  Future<void> saveCounterViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode);
  }
}
