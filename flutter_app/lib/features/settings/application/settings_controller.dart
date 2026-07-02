import 'package:flutter/material.dart';

import '../data/settings_repository.dart';

/// Preferências do app: tema, onboarding e modo de visualização.
class SettingsController extends ChangeNotifier {
  SettingsController({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

  final SettingsRepository _repository;

  ThemeMode _themeMode = ThemeMode.system;
  bool _introSeen = false;
  bool _loaded = false;
  String? _counterViewMode;

  ThemeMode get themeMode => _themeMode;
  bool get introSeen => _introSeen;
  bool get loaded => _loaded;
  String? get counterViewMode => _counterViewMode;

  Future<void> load() async {
    _themeMode = await _repository.loadThemeMode();
    _introSeen = await _repository.hasSeenIntro();
    _counterViewMode = await _repository.loadCounterViewMode();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _repository.saveThemeMode(mode);
  }

  Future<void> markIntroSeen() async {
    _introSeen = true;
    notifyListeners();
    await _repository.markIntroSeen();
  }

  Future<void> saveCounterViewMode(String mode) async {
    _counterViewMode = mode;
    await _repository.saveCounterViewMode(mode);
  }
}
