import '../domain/habit.dart';
import '../domain/habit_event.dart';
import '../domain/habit_kind.dart';

/// Modelo legado v1 — usado apenas na migração.
class LegacyHabitRun {
  const LegacyHabitRun({required this.start, this.end, this.endReason});

  final DateTime start;
  final DateTime? end;
  final String? endReason;

  bool get isActive => end == null;

  factory LegacyHabitRun.fromJson(Map<String, dynamic> json) {
    return LegacyHabitRun(
      start: DateTime.tryParse(json['start'] as String? ?? '') ?? DateTime.now(),
      end: DateTime.tryParse(json['end'] as String? ?? ''),
      endReason: json['endReason'] as String?,
    );
  }
}

/// Converte hábitos v1 (runs) para o modelo v2 (eventos).
class HabitMigration {
  const HabitMigration._();

  static bool isLegacy(Map<String, dynamic> json) =>
      json['kind'] == null && json.containsKey('runs');

  static Habit fromLegacyJson(Map<String, dynamic> json) {
    final runs = (json['runs'] as List?)
            ?.map((item) =>
                LegacyHabitRun.fromJson((item as Map).cast<String, dynamic>()))
            .toList() ??
        const <LegacyHabitRun>[];

    final events = <HabitEvent>[];
    DateTime? currentStart;

    for (final run in runs) {
      events.add(HabitEvent.create(
        type: HabitEventType.trackerStarted,
        at: run.start,
      ));
      currentStart = run.start;

      if (run.end != null) {
        if (run.endReason == 'paused') {
          events.add(HabitEvent.create(
            type: HabitEventType.trackerPaused,
            at: run.end!,
          ));
          currentStart = null;
        } else {
          events.add(HabitEvent.create(
            type: HabitEventType.trackerReset,
            at: run.end!,
          ));
          if (run.isActive) {
            currentStart = run.end;
          } else {
            currentStart = null;
          }
        }
      }
    }

    final activeRun = runs.where((r) => r.isActive).firstOrNull;
    final startAt = activeRun?.start ?? currentStart ?? runs.firstOrNull?.start;

    return Habit(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      kind: HabitKind.timeTracker,
      notes: json['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      iconName: json['iconName'] as String? ?? 'spark',
      accentColor: (json['accentColor'] as num?)?.toInt() ?? 0xFF19A45B,
      archived: json['archived'] as bool? ?? false,
      startAt: startAt,
      events: events,
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
