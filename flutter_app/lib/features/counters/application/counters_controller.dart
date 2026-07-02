import 'package:flutter/foundation.dart';

import '../data/counter_repository.dart';
import '../domain/counter.dart';
import '../domain/counter_snapshot.dart';

/// Modos de visualização da lista de contagens.
enum CounterViewMode { grid, list, timeline }

/// Estado e operações das contagens.
class CountersController extends ChangeNotifier {
  CountersController({CounterRepository? repository})
      : _repository = repository ?? CounterRepository();

  final CounterRepository _repository;

  List<Counter> _counters = [];
  bool _loaded = false;
  CounterViewMode _viewMode = CounterViewMode.grid;

  /// Notificado após qualquer mutação persistida (para sync de plataforma).
  VoidCallback? onPersisted;

  bool get loaded => _loaded;
  List<Counter> get all => List.unmodifiable(_counters);
  CounterViewMode get viewMode => _viewMode;

  List<Counter> get active =>
      _counters.where((counter) => !counter.archived).toList();

  List<Counter> get archived =>
      _counters.where((counter) => counter.archived).toList();

  List<Counter> get favorites =>
      active.where((counter) => counter.favorite).toList();

  /// Todas as tags em uso (ordenadas alfabeticamente).
  List<String> get allTags {
    final tags = <String>{};
    for (final counter in active) {
      tags.addAll(counter.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  Counter? byId(String id) {
    for (final counter in _counters) {
      if (counter.id == id) {
        return counter;
      }
    }
    return null;
  }

  /// Ordena por proximidade do evento: hoje/futuro primeiro, depois
  /// contagens crescentes ("dias desde") por magnitude.
  List<Counter> sortedByRelevance(List<Counter> source, DateTime now) {
    final list = [...source];
    list.sort((a, b) {
      final aSnap = CounterSnapshot.of(a, now);
      final bSnap = CounterSnapshot.of(b, now);

      int rank(CounterSnapshot snapshot) {
        if (snapshot.isToday) {
          return 0;
        }
        if (snapshot.isCountdown) {
          return 1;
        }
        return 2;
      }

      final rankDiff = rank(aSnap) - rank(bSnap);
      if (rankDiff != 0) {
        return rankDiff;
      }
      if (aSnap.isCountdown && bSnap.isCountdown) {
        return aSnap.totalDays.compareTo(bSnap.totalDays);
      }
      return bSnap.totalDays.compareTo(aSnap.totalDays);
    });
    return list;
  }

  Future<void> load({String? initialViewMode}) async {
    _counters = await _repository.load();
    _viewMode = CounterViewMode.values.firstWhere(
      (mode) => mode.name == initialViewMode,
      orElse: () => CounterViewMode.grid,
    );
    _loaded = true;
    notifyListeners();
  }

  void setViewMode(CounterViewMode mode) {
    if (mode == _viewMode) {
      return;
    }
    _viewMode = mode;
    notifyListeners();
  }

  Future<void> add(Counter counter) async {
    _counters = [counter, ..._counters];
    await _persist();
  }

  Future<void> update(Counter counter) async {
    _counters = [
      for (final item in _counters)
        if (item.id == counter.id) counter else item,
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    _counters = _counters.where((counter) => counter.id != id).toList();
    await _persist();
  }

  Future<void> removeMany(Set<String> ids) async {
    _counters =
        _counters.where((counter) => !ids.contains(counter.id)).toList();
    await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    final counter = byId(id);
    if (counter == null) {
      return;
    }
    await update(counter.copyWith(favorite: !counter.favorite));
  }

  Future<void> setArchived(String id, bool archived) async {
    final counter = byId(id);
    if (counter == null) {
      return;
    }
    await update(counter.copyWith(archived: archived, favorite: false));
  }

  Future<void> archiveMany(Set<String> ids) async {
    _counters = [
      for (final counter in _counters)
        ids.contains(counter.id)
            ? counter.copyWith(archived: true, favorite: false)
            : counter,
    ];
    await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _repository.save(_counters);
    onPersisted?.call();
  }
}
