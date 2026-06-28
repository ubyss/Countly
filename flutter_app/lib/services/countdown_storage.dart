import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/countdown.dart';
import '../utils/countdown_utils.dart';

const _storageKey = 'countly.countdowns.v3';

class CountdownStorage {
  Future<List<Countdown>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved == null) {
      return [];
    }

    try {
      final parsed = jsonDecode(saved) as List<dynamic>;
      return parsed
          .map((item) => Countdown.fromJson(item as Map<String, dynamic>))
          .map(
            (countdown) => countdown.copyWith(
              targetDate: normalizeTargetDate(countdown.targetDate),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Countdown> countdowns) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(countdowns.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
