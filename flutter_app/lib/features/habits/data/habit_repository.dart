import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/habit.dart';
import 'habit_migration.dart';

const _storageKey = 'countly.habits.v2';
const _legacyKey = 'countly.habits.v1';

/// Persistência local dos hábitos (v2 com migração automática de v1).
class HabitRepository {
  Future<List<Habit>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);

    if (saved != null) {
      return _parseList(saved);
    }

    final legacy = prefs.getString(_legacyKey);
    if (legacy == null) {
      return [];
    }

    final migrated = _parseList(legacy, migrateLegacy: true);
    await save(migrated);
    await prefs.remove(_legacyKey);
    return migrated;
  }

  List<Habit> _parseList(String raw, {bool migrateLegacy = false}) {
    try {
      final parsed = jsonDecode(raw) as List<dynamic>;
      return parsed.map((item) {
        final map = (item as Map).cast<String, dynamic>();
        if (migrateLegacy && HabitMigration.isLegacy(map)) {
          return HabitMigration.fromLegacyJson(map);
        }
        return Habit.fromJson(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(habits.map((habit) => habit.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
