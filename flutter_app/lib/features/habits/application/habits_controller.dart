import 'package:flutter/foundation.dart';

import '../data/habit_repository.dart';
import '../domain/habit.dart';
import '../domain/habit_event.dart';
import '../domain/habit_kind.dart';
import '../domain/habit_stats.dart';

/// Estado e operações dos hábitos (4 tipos).
class HabitsController extends ChangeNotifier {
  HabitsController({HabitRepository? repository})
      : _repository = repository ?? HabitRepository();

  final HabitRepository _repository;

  List<Habit> _habits = [];
  bool _loaded = false;

  VoidCallback? onPersisted;

  bool get loaded => _loaded;
  List<Habit> get all => List.unmodifiable(_habits);

  List<Habit> get active =>
      _habits.where((habit) => !habit.archived).toList();

  List<Habit> get archived =>
      _habits.where((habit) => habit.archived).toList();

  bool get hasLiveSession =>
      _habits.any((h) => h.kind == HabitKind.session && h.hasActiveSession);

  Habit? byId(String id) {
    for (final habit in _habits) {
      if (habit.id == id) {
        return habit;
      }
    }
    return null;
  }

  HabitStats statsFor(Habit habit, DateTime now) =>
      HabitStatsEngine.compute(habit, now);

  Future<void> load() async {
    _habits = await _repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(Habit habit) async {
    _habits = [habit, ..._habits];
    await _persist();
  }

  Future<void> update(Habit habit) async {
    _habits = [
      for (final item in _habits)
        if (item.id == habit.id) habit else item,
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    _habits = _habits.where((habit) => habit.id != id).toList();
    await _persist();
  }

  Future<void> setArchived(String id, bool archived) async {
    final habit = byId(id);
    if (habit == null) {
      return;
    }
    await update(habit.copyWith(archived: archived));
  }

  // ── Simple ──────────────────────────────────────────────────────────────

  Future<void> completeSimple(String id) async {
    final habit = byId(id);
    if (habit == null || habit.kind != HabitKind.simple) {
      return;
    }
    final now = DateTime.now();
    final stats = HabitStatsEngine.compute(habit, now);
    if (stats.completedToday) {
      return;
    }
    await update(
      habit.withEvent(
        HabitEvent.create(type: HabitEventType.simpleCompleted, at: now),
      ),
    );
  }

  Future<void> uncompleteSimple(String id) async {
    final habit = byId(id);
    if (habit == null || habit.kind != HabitKind.simple) {
      return;
    }
    final now = DateTime.now();
    final filtered = habit.events.where((e) {
      return !(e.type == HabitEventType.simpleCompleted && _sameDay(e.at, now));
    }).toList();
    await update(habit.copyWith(events: filtered));
  }

  // ── Quantity ────────────────────────────────────────────────────────────

  Future<void> addQuantity(String id, {int amount = 1}) async {
    final habit = byId(id);
    if (habit == null || habit.kind != HabitKind.quantity || amount <= 0) {
      return;
    }
    await update(
      habit.withEvent(
        HabitEvent.create(
          type: HabitEventType.quantityLog,
          value: amount,
        ),
      ),
    );
  }

  Future<void> removeQuantity(String id, {int amount = 1}) async {
    final habit = byId(id);
    if (habit == null || habit.kind != HabitKind.quantity || amount <= 0) {
      return;
    }
    await update(
      habit.withEvent(
        HabitEvent.create(
          type: HabitEventType.quantityLog,
          value: -amount,
        ),
      ),
    );
  }

  Future<void> setQuantityToday(String id, int value) async {
    final habit = byId(id);
    if (habit == null || habit.kind != HabitKind.quantity) {
      return;
    }
    final now = DateTime.now();
    final current = HabitStatsEngine.compute(habit, now).todayQuantity;
    final delta = value - current;
    if (delta == 0) {
      return;
    }
    await update(
      habit.withEvent(
        HabitEvent.create(type: HabitEventType.quantityLog, value: delta),
      ),
    );
  }

  // ── Session ───────────────────────────────────────────────────────────────

  Future<void> startSession(String id) async {
    final habit = byId(id);
    if (habit == null ||
        habit.kind != HabitKind.session ||
        habit.hasActiveSession) {
      return;
    }
    final now = DateTime.now();
    await update(
      habit
          .copyWith(activeSession: ActiveSession(startedAt: now))
          .withEvent(HabitEvent.create(type: HabitEventType.sessionStarted, at: now)),
    );
  }

  Future<void> pauseSession(String id) async {
    final habit = byId(id);
    final session = habit?.activeSession;
    if (habit == null ||
        habit.kind != HabitKind.session ||
        session == null ||
        session.isPaused) {
      return;
    }
    final now = DateTime.now();
    final elapsed = session.elapsedSeconds(now);
    await update(
      habit
          .copyWith(
            activeSession: session.copyWith(
              pausedAt: now,
              accumulatedSeconds: elapsed,
            ),
          )
          .withEvent(HabitEvent.create(type: HabitEventType.sessionPaused, at: now)),
    );
  }

  Future<void> resumeSession(String id) async {
    final habit = byId(id);
    final session = habit?.activeSession;
    if (habit == null ||
        habit.kind != HabitKind.session ||
        session == null ||
        session.isRunning) {
      return;
    }
    final now = DateTime.now();
    await update(
      habit
          .copyWith(
            activeSession: ActiveSession(
              startedAt: now,
              accumulatedSeconds: session.accumulatedSeconds,
            ),
          )
          .withEvent(HabitEvent.create(type: HabitEventType.sessionResumed, at: now)),
    );
  }

  Future<void> endSession(String id) async {
    final habit = byId(id);
    final session = habit?.activeSession;
    if (habit == null || habit.kind != HabitKind.session || session == null) {
      return;
    }
    final now = DateTime.now();
    final duration = session.elapsedSeconds(now);
    await update(
      habit
          .copyWith(clearActiveSession: true)
          .withEvent(
            HabitEvent.create(
              type: HabitEventType.sessionCompleted,
              at: now,
              value: duration,
            ),
          ),
    );
  }

  // ── Time Tracker ────────────────────────────────────────────────────────

  Future<void> pauseTracker(String id) async {
    final habit = byId(id);
    if (habit == null || habit.kind != HabitKind.timeTracker) {
      return;
    }
    final stats = HabitStatsEngine.compute(habit, DateTime.now());
    if (stats.isPaused) {
      return;
    }
    final now = DateTime.now();
    await update(
      habit.withEvent(HabitEvent.create(type: HabitEventType.trackerPaused, at: now)),
    );
  }

  Future<void> resumeTracker(String id) async {
    final habit = byId(id);
    if (habit == null || habit.kind != HabitKind.timeTracker) {
      return;
    }
    final stats = HabitStatsEngine.compute(habit, DateTime.now());
    if (!stats.isPaused) {
      return;
    }
    final now = DateTime.now();
    await update(
      habit
          .copyWith(startAt: now)
          .withEvent(HabitEvent.create(type: HabitEventType.trackerResumed, at: now)),
    );
  }

  Future<void> resetTracker(String id) async {
    final habit = byId(id);
    if (habit == null || habit.kind != HabitKind.timeTracker) {
      return;
    }
    final now = DateTime.now();
    await update(
      habit
          .copyWith(startAt: now)
          .withEvent(HabitEvent.create(type: HabitEventType.trackerReset, at: now)),
    );
  }

  // ── Compat (widget / resumo) ────────────────────────────────────────────

  int streakFor(Habit habit, DateTime now) {
    final stats = HabitStatsEngine.compute(habit, now);
    switch (habit.kind) {
      case HabitKind.timeTracker:
        return stats.elapsed?.inDays ?? 0;
      case HabitKind.simple:
        return stats.currentStreak;
      case HabitKind.session:
        return stats.consecutiveSessionDays;
      case HabitKind.quantity:
        return stats.activityDays.length;
    }
  }

  bool isPaused(Habit habit, DateTime now) {
    if (habit.kind != HabitKind.timeTracker) {
      return false;
    }
    return HabitStatsEngine.compute(habit, now).isPaused;
  }

  Future<void> _persist() async {
    notifyListeners();
    await _repository.save(_habits);
    onPersisted?.call();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
