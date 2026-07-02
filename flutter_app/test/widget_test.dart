import 'package:flutter_test/flutter_test.dart';

import 'package:countly/features/counters/domain/counter.dart';
import 'package:countly/features/counters/domain/counter_snapshot.dart';
import 'package:countly/features/counters/domain/recurrence.dart';
import 'package:countly/features/habits/domain/habit.dart';
import 'package:countly/features/habits/domain/habit_event.dart';
import 'package:countly/features/habits/domain/habit_kind.dart';
import 'package:countly/features/habits/domain/habit_stats.dart';

void main() {
  group('Recurrence', () {
    test('próxima ocorrência anual rola para o futuro', () {
      const recurrence = Recurrence(frequency: RecurrenceFrequency.yearly);
      final next = recurrence.nextOccurrence(
        DateTime(2020, 3, 10),
        DateTime(2026, 6, 1),
      );
      expect(next, DateTime(2027, 3, 10));
    });

    test('ocorrência semanal mantém o dia da semana', () {
      const recurrence = Recurrence(frequency: RecurrenceFrequency.weekly);
      final next = recurrence.nextOccurrence(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 10),
      );
      expect(next!.weekday, DateTime(2026, 6, 1).weekday);
      expect(next.isBefore(DateTime(2026, 6, 10)), isFalse);
    });

    test('recorrência mensal ajusta meses curtos', () {
      const recurrence = Recurrence(frequency: RecurrenceFrequency.monthly);
      final occurrences = recurrence.occurrencesBetween(
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 28),
      );
      expect(occurrences, [DateTime(2026, 2, 28)]);
    });
  });

  group('CounterSnapshot', () {
    test('contagem regressiva para data futura', () {
      final counter = Counter(
        id: '1',
        title: 'Viagem',
        createdAt: DateTime(2026, 1, 1),
        targetDate: '2026-01-11',
      );
      final snapshot = CounterSnapshot.of(counter, DateTime(2026, 1, 1));
      expect(snapshot.isCountdown, isTrue);
      expect(snapshot.totalDays, 10);
    });

    test('sem data alvo conta dias desde a criação', () {
      final counter = Counter(
        id: '2',
        title: 'Dias sem café',
        createdAt: DateTime(2026, 1, 1),
      );
      final snapshot = CounterSnapshot.of(counter, DateTime(2026, 1, 31));
      expect(snapshot.phase, CounterPhase.sinceCreation);
      expect(snapshot.totalDays, 30);
    });

    test('data alvo hoje entra na fase today', () {
      final counter = Counter(
        id: '3',
        title: 'Aniversário',
        createdAt: DateTime(2026, 1, 1),
        targetDate: '2026-05-20',
      );
      final snapshot =
          CounterSnapshot.of(counter, DateTime(2026, 5, 20, 14, 30));
      expect(snapshot.isToday, isTrue);
    });
  });

  group('Habit v2', () {
    test('time tracker pausa e retoma', () {
      final start = DateTime(2026, 1, 1);
      var habit = Habit.create(
        title: 'Sem açúcar',
        kind: HabitKind.timeTracker,
        startAt: start,
      );

      habit = habit.withEvent(
        HabitEvent.create(
          type: HabitEventType.trackerPaused,
          at: DateTime(2026, 1, 11),
        ),
      );
      var stats = HabitStatsEngine.compute(habit, DateTime(2026, 1, 15));
      expect(stats.isPaused, isTrue);
      expect(stats.elapsed!.inDays, 10);

      habit = habit
          .copyWith(startAt: DateTime(2026, 1, 20))
          .withEvent(
            HabitEvent.create(
              type: HabitEventType.trackerResumed,
              at: DateTime(2026, 1, 20),
            ),
          );
      stats = HabitStatsEngine.compute(habit, DateTime(2026, 1, 25));
      expect(stats.isPaused, isFalse);
      expect(stats.elapsed!.inDays, 5);
    });

    test('hábito simples registra conclusão diária', () {
      final habit = Habit.create(
        title: 'Academia',
        kind: HabitKind.simple,
      ).withEvent(
        HabitEvent.create(
          type: HabitEventType.simpleCompleted,
          at: DateTime(2026, 2, 10),
        ),
      );

      final stats = HabitStatsEngine.compute(habit, DateTime(2026, 2, 10));
      expect(stats.completedToday, isTrue);
      expect(stats.currentStreak, 1);
    });

    test('quantidade soma eventos do dia', () {
      final habit = Habit.create(
        title: 'Água',
        kind: HabitKind.quantity,
        dailyGoal: 6,
      )
          .withEvent(
            HabitEvent.create(
              type: HabitEventType.quantityLog,
              at: DateTime(2026, 3, 1, 10),
              value: 2,
            ),
          )
          .withEvent(
            HabitEvent.create(
              type: HabitEventType.quantityLog,
              at: DateTime(2026, 3, 1, 14),
              value: 3,
            ),
          );

      final stats = HabitStatsEngine.compute(habit, DateTime(2026, 3, 1, 18));
      expect(stats.todayQuantity, 5);
      expect(stats.quantityGoalReached, isFalse);
    });
  });
}
