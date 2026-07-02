import '../../../core/utils/date_utils.dart';
import '../../counters/domain/counter.dart';

/// Ocorrência de uma contagem em uma data específica do calendário.
class CalendarEvent {
  const CalendarEvent({required this.date, required this.counter});

  final DateTime date;
  final Counter counter;
}

/// Expande as contagens (com recorrência) em eventos dentro do intervalo.
Map<DateTime, List<CalendarEvent>> eventsForRange(
  List<Counter> counters,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final events = <DateTime, List<CalendarEvent>>{};

  for (final counter in counters) {
    if (counter.archived) {
      continue;
    }
    final target = counter.targetLocalDate;
    if (target == null) {
      continue;
    }
    final occurrences =
        counter.recurrence.occurrencesBetween(target, rangeStart, rangeEnd);
    for (final date in occurrences) {
      final key = dateOnly(date);
      events
          .putIfAbsent(key, () => [])
          .add(CalendarEvent(date: key, counter: counter));
    }
  }

  return events;
}
