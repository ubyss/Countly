import 'package:shared_preferences/shared_preferences.dart';

const _viewModeKey = 'countly.viewMode';

class CountlyPreferences {
  Future<String?> loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_viewModeKey);
  }

  Future<void> saveViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode);
  }
}
