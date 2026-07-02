import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/counter.dart';

const _storageKey = 'countly.counters.v4';
const _legacyStorageKey = 'countly.countdowns.v3';

/// Persistência local das contagens.
///
/// Na primeira leitura converte automaticamente os registros do formato
/// legado (`Countdown` v3) para o novo modelo.
class CounterRepository {
  Future<List<Counter>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);

    if (saved != null) {
      return _decode(saved, Counter.fromJson);
    }

    final legacy = prefs.getString(_legacyStorageKey);
    if (legacy != null) {
      final migrated = _decode(legacy, Counter.fromLegacyJson);
      await save(migrated);
      return migrated;
    }

    return [];
  }

  Future<void> save(List<Counter> counters) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(counters.map((counter) => counter.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  List<Counter> _decode(
    String source,
    Counter Function(Map<String, dynamic>) parser,
  ) {
    try {
      final parsed = jsonDecode(source) as List<dynamic>;
      return parsed
          .map((item) => parser((item as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
