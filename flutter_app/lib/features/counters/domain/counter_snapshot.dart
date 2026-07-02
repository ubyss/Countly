import '../../../core/utils/date_utils.dart';
import 'counter.dart';

/// Fase de exibição de uma contagem em um dado instante.
enum CounterPhase {
  /// Contagem regressiva para uma data futura.
  countdown,

  /// A data alvo é hoje.
  today,

  /// A data alvo já passou (sem recorrência): conta o tempo decorrido.
  elapsed,

  /// Sem data alvo: conta os dias desde a criação.
  sinceCreation,
}

/// Unidade exibível de tempo ("Dias" -> 12).
class CounterUnit {
  const CounterUnit(this.label, this.value);

  final String label;
  final int value;

  String get padded => value.toString().padLeft(2, '0');
}

/// Decomposição de calendário entre duas datas.
class _CalendarSpan {
  const _CalendarSpan(this.years, this.months, this.days);

  final int years;
  final int months;
  final int days;
}

_CalendarSpan _spanBetween(DateTime from, DateTime to) {
  var years = to.year - from.year;
  var months = to.month - from.month;
  var days = to.day - from.day;

  if (days < 0) {
    months--;
    days += DateTime(to.year, to.month, 0).day;
  }
  if (months < 0) {
    years--;
    months += 12;
  }
  return _CalendarSpan(years, months, days);
}

/// Estado calculado de um [Counter] em um instante de referência.
///
/// Centraliza toda a matemática de datas: recorrência é resolvida para a
/// próxima ocorrência e a decomposição usa meses de calendário reais.
class CounterSnapshot {
  CounterSnapshot._({
    required this.phase,
    required this.eventDate,
    required this.units,
    required this.headline,
    required this.totalDays,
  });

  final CounterPhase phase;

  /// Data efetiva do evento (próxima ocorrência quando recorrente).
  final DateTime? eventDate;

  /// Até duas unidades mais significativas para exibição.
  final List<CounterUnit> units;

  /// Frase pronta ("Faltam 3 dias", "Há 2 anos", "É hoje!").
  final String headline;

  /// Distância total em dias (sempre >= 0).
  final int totalDays;

  bool get isToday => phase == CounterPhase.today;
  bool get isCountdown => phase == CounterPhase.countdown;
  bool get countsUp =>
      phase == CounterPhase.elapsed || phase == CounterPhase.sinceCreation;

  factory CounterSnapshot.of(Counter counter, DateTime now) {
    final today = dateOnly(now);
    final target = counter.targetLocalDate;

    if (target == null) {
      final days = daysBetween(counter.createdAt, today).clamp(0, 1 << 31);
      return CounterSnapshot._(
        phase: CounterPhase.sinceCreation,
        eventDate: null,
        units: _unitsFor(dateOnly(counter.createdAt), today, now),
        headline: days == 0 ? 'Começou hoje' : '${pluralize(days, 'dia', 'dias')} contados',
        totalDays: days,
      );
    }

    final effective = counter.recurrence.repeats
        ? counter.recurrence.nextOccurrence(target, today) ?? target
        : target;

    if (isSameDay(effective, today)) {
      return CounterSnapshot._(
        phase: CounterPhase.today,
        eventDate: effective,
        units: const [CounterUnit('Hoje', 0)],
        headline: 'É hoje!',
        totalDays: 0,
      );
    }

    if (effective.isAfter(today)) {
      final days = daysBetween(today, effective);
      return CounterSnapshot._(
        phase: CounterPhase.countdown,
        eventDate: effective,
        units: _unitsFor(now, effective.add(const Duration(days: 1)), now,
            countdown: true),
        headline: days == 1 ? 'Falta 1 dia' : 'Faltam ${pluralize(days, 'dia', 'dias')}',
        totalDays: days,
      );
    }

    final days = daysBetween(effective, today);
    final span = _spanBetween(effective, today);
    return CounterSnapshot._(
      phase: CounterPhase.elapsed,
      eventDate: effective,
      units: _unitsFor(effective, today, now),
      headline: 'Há ${_spanSummary(span, days)}',
      totalDays: days,
    );
  }

  /// Seleciona as duas unidades mais significativas.
  static List<CounterUnit> _unitsFor(
    DateTime from,
    DateTime to,
    DateTime now, {
    bool countdown = false,
  }) {
    final start = dateOnly(from);
    final end = dateOnly(to);
    final span = _spanBetween(start, end);
    final totalDays = daysBetween(start, end);

    if (span.years > 0) {
      return [
        CounterUnit('Anos', span.years),
        CounterUnit('Meses', span.months),
      ];
    }
    if (span.months > 0) {
      return [
        CounterUnit('Meses', span.months),
        CounterUnit('Dias', span.days),
      ];
    }
    if (countdown) {
      final endOfTarget = end.subtract(const Duration(days: 1)).add(
            const Duration(hours: 23, minutes: 59, seconds: 59),
          );
      final remaining = endOfTarget.difference(now);
      final days = remaining.inDays;
      final hours = remaining.inHours % 24;
      return [
        CounterUnit('Dias', days < 0 ? 0 : days),
        CounterUnit('Horas', hours < 0 ? 0 : hours),
      ];
    }
    return [CounterUnit('Dias', totalDays)];
  }

  static String _spanSummary(_CalendarSpan span, int totalDays) {
    if (span.years > 0) {
      final parts = [pluralize(span.years, 'ano', 'anos')];
      if (span.months > 0) {
        parts.add(pluralize(span.months, 'mês', 'meses'));
      }
      return parts.join(' e ');
    }
    if (span.months > 0) {
      final parts = [pluralize(span.months, 'mês', 'meses')];
      if (span.days > 0) {
        parts.add(pluralize(span.days, 'dia', 'dias'));
      }
      return parts.join(' e ');
    }
    return pluralize(totalDays, 'dia', 'dias');
  }
}

/// Próximo evento futuro entre as contagens ativas (para widget/notificações).
Counter? nextUpcomingCounter(List<Counter> counters, DateTime now) {
  Counter? closest;
  DateTime? closestDate;

  for (final counter in counters) {
    if (counter.archived) {
      continue;
    }
    final snapshot = CounterSnapshot.of(counter, now);
    final eventDate = snapshot.eventDate;
    if (eventDate == null || !snapshot.isCountdown && !snapshot.isToday) {
      continue;
    }
    if (closestDate == null || eventDate.isBefore(closestDate)) {
      closestDate = eventDate;
      closest = counter;
    }
  }
  return closest;
}
