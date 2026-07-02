import '../../../core/utils/date_utils.dart';

enum RecurrenceFrequency { never, daily, weekly, monthly, yearly, custom }

/// Regra de repetição de uma contagem.
///
/// Para [RecurrenceFrequency.custom], [intervalDays] define o intervalo
/// em dias entre ocorrências.
class Recurrence {
  const Recurrence({
    this.frequency = RecurrenceFrequency.never,
    this.intervalDays = 1,
  });

  static const none = Recurrence();

  final RecurrenceFrequency frequency;
  final int intervalDays;

  bool get repeats => frequency != RecurrenceFrequency.never;

  String get label {
    switch (frequency) {
      case RecurrenceFrequency.never:
        return 'Não repete';
      case RecurrenceFrequency.daily:
        return 'Diariamente';
      case RecurrenceFrequency.weekly:
        return 'Semanalmente';
      case RecurrenceFrequency.monthly:
        return 'Mensalmente';
      case RecurrenceFrequency.yearly:
        return 'Anualmente';
      case RecurrenceFrequency.custom:
        return intervalDays == 1
            ? 'A cada dia'
            : 'A cada $intervalDays dias';
    }
  }

  /// Próxima ocorrência (>= [reference]) partindo da data base.
  DateTime? nextOccurrence(DateTime base, DateTime reference) {
    final start = dateOnly(base);
    final ref = dateOnly(reference);
    if (!start.isBefore(ref)) {
      return start;
    }
    switch (frequency) {
      case RecurrenceFrequency.never:
        return null;
      case RecurrenceFrequency.daily:
        return ref;
      case RecurrenceFrequency.weekly:
        final elapsed = daysBetween(start, ref);
        final remainder = elapsed % 7;
        return remainder == 0 ? ref : ref.add(Duration(days: 7 - remainder));
      case RecurrenceFrequency.monthly:
        return _nextByMonths(start, ref, 1);
      case RecurrenceFrequency.yearly:
        return _nextByMonths(start, ref, 12);
      case RecurrenceFrequency.custom:
        final interval = intervalDays < 1 ? 1 : intervalDays;
        final elapsed = daysBetween(start, ref);
        final remainder = elapsed % interval;
        return remainder == 0
            ? ref
            : ref.add(Duration(days: interval - remainder));
    }
  }

  /// Ocorrências dentro de um intervalo fechado de dias.
  List<DateTime> occurrencesBetween(
    DateTime base,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final start = dateOnly(base);
    final first = dateOnly(rangeStart);
    final last = dateOnly(rangeEnd);
    final result = <DateTime>[];

    if (!repeats) {
      if (!start.isBefore(first) && !start.isAfter(last)) {
        result.add(start);
      }
      return result;
    }

    var current = nextOccurrence(start, first);
    var safety = 0;
    while (current != null && !current.isAfter(last) && safety < 400) {
      result.add(current);
      current = _advance(start, current);
      safety++;
    }
    return result;
  }

  DateTime? _advance(DateTime base, DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.never:
        return null;
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return _addMonthsClamped(from, 1, base.day);
      case RecurrenceFrequency.yearly:
        return _addMonthsClamped(from, 12, base.day);
      case RecurrenceFrequency.custom:
        return from.add(Duration(days: intervalDays < 1 ? 1 : intervalDays));
    }
  }

  DateTime _nextByMonths(DateTime start, DateTime ref, int stepMonths) {
    var candidate = start;
    var safety = 0;
    while (candidate.isBefore(ref) && safety < 2400) {
      candidate = _addMonthsClamped(candidate, stepMonths, start.day);
      safety++;
    }
    return candidate;
  }

  static DateTime _addMonthsClamped(DateTime from, int months, int desiredDay) {
    final totalMonths = from.year * 12 + (from.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, desiredDay > lastDay ? lastDay : desiredDay);
  }

  Map<String, dynamic> toJson() => {
        'frequency': frequency.name,
        if (frequency == RecurrenceFrequency.custom)
          'intervalDays': intervalDays,
      };

  factory Recurrence.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Recurrence.none;
    }
    final frequency = RecurrenceFrequency.values.firstWhere(
      (item) => item.name == json['frequency'],
      orElse: () => RecurrenceFrequency.never,
    );
    return Recurrence(
      frequency: frequency,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 1,
    );
  }

  /// Converte o valor legado ("none"/"yearly"/"weekly"/"monthly"/"daily").
  factory Recurrence.fromLegacy(String? value) {
    switch (value) {
      case 'yearly':
      case 'daily':
        return const Recurrence(frequency: RecurrenceFrequency.yearly);
      case 'weekly':
        return const Recurrence(frequency: RecurrenceFrequency.weekly);
      case 'monthly':
        return const Recurrence(frequency: RecurrenceFrequency.monthly);
      default:
        return Recurrence.none;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Recurrence &&
      other.frequency == frequency &&
      other.intervalDays == intervalDays;

  @override
  int get hashCode => Object.hash(frequency, intervalDays);
}
