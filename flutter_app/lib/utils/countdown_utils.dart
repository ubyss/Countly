import 'package:intl/intl.dart';

import '../models/countdown.dart';
import '../models/remaining_time.dart';

String normalizeTargetDate(dynamic value) {
  if (value is num && value.isFinite) {
    return _toDateInputValue(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
  }

  if (value is! String) {
    return '';
  }

  final trimmed = value.trim();
  final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
  if (isoMatch != null) {
    return '${isoMatch.group(1)}-${isoMatch.group(2)}-${isoMatch.group(3)}';
  }

  final brazilian = _parseBrazilianDateInput(trimmed);
  if (brazilian.isNotEmpty) {
    return brazilian;
  }

  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    return '';
  }

  return _toDateInputValue(parsed);
}

String _toDateInputValue(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatBrazilianDateInput(String isoDate) {
  final normalized = normalizeTargetDate(isoDate);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(normalized);
  if (match == null) {
    return '';
  }
  return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
}

String _parseBrazilianDateInput(String value) {
  final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value.trim());
  if (match == null) {
    return '';
  }

  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  final parsed = DateTime(year, month, day);

  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return '';
  }

  return _toDateInputValue(parsed);
}

DateTime? isoDateToLocalDate(String isoDate) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(isoDate);
  if (match == null) {
    return null;
  }

  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

int? getTargetEndTimestamp(String targetDate) {
  final localDate = isoDateToLocalDate(normalizeTargetDate(targetDate));
  if (localDate == null) {
    return null;
  }

  return DateTime(
    localDate.year,
    localDate.month,
    localDate.day,
    23,
    59,
    59,
    999,
  ).millisecondsSinceEpoch;
}

RemainingTime calculateRemainingTime(String targetDate, DateTime referenceDate) {
  final normalized = normalizeTargetDate(targetDate);
  final targetEnd = getTargetEndTimestamp(normalized);

  if (targetEnd == null) {
    return RemainingTime.expiredState;
  }

  final distance = targetEnd - referenceDate.millisecondsSinceEpoch;
  if (distance <= 0) {
    return RemainingTime.expiredState;
  }

  const minute = 1000 * 60;
  const hour = minute * 60;
  const day = hour * 24;
  const month = day * 30;

  return RemainingTime(
    months: distance ~/ month,
    days: (distance % month) ~/ day,
    hours: (distance % day) ~/ hour,
    minutes: (distance % hour) ~/ minute,
    expired: false,
  );
}

class CountdownDisplayUnit {
  const CountdownDisplayUnit({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;
}

List<CountdownDisplayUnit> buildCountdownDisplayUnits(RemainingTime remaining) {
  if (remaining.expired) {
    return const [];
  }

  if (remaining.months > 0) {
    return [
      CountdownDisplayUnit(label: 'Meses', value: remaining.months),
      CountdownDisplayUnit(label: 'Dias', value: remaining.days),
    ];
  }

  return [
    CountdownDisplayUnit(label: 'Dias', value: remaining.days),
    CountdownDisplayUnit(label: 'Horas', value: remaining.hours),
  ];
}

String _formatRemainingUnit(int value, {required String singular, required String plural}) {
  return '$value ${value == 1 ? singular : plural}';
}

String formatRemainingTimeSummary(RemainingTime remaining) {
  if (remaining.expired) {
    return '';
  }

  final parts = <String>[];
  if (remaining.months > 0) {
    parts.add(_formatRemainingUnit(remaining.months, singular: 'mês', plural: 'meses'));
    if (remaining.days > 0) {
      parts.add(_formatRemainingUnit(remaining.days, singular: 'dia', plural: 'dias'));
    }
  } else {
    if (remaining.days > 0) {
      parts.add(_formatRemainingUnit(remaining.days, singular: 'dia', plural: 'dias'));
    }
    if (remaining.hours > 0) {
      parts.add(_formatRemainingUnit(remaining.hours, singular: 'hora', plural: 'horas'));
    }
    if (parts.isEmpty) {
      parts.add('menos de 1 hora');
    }
  }

  return parts.take(2).join(' e ');
}

String padMetric(int value) => value.toString().padLeft(2, '0');

String formatDateLabel(String value) {
  final localDate = isoDateToLocalDate(normalizeTargetDate(value));
  if (localDate == null) {
    return value;
  }

  return DateFormat('d \'de\' MMMM \'de\' y', 'pt_BR').format(localDate);
}

String formatCalendarMonth(DateTime date) {
  return DateFormat('MMMM y', 'pt_BR').format(date);
}

String formatCalendarMonthName(DateTime date) {
  return DateFormat('MMMM', 'pt_BR').format(date);
}

bool isDateBeforeToday(DateTime date, DateTime today) {
  final dateStart = DateTime(date.year, date.month, date.day);
  final todayStart = DateTime(today.year, today.month, today.day);
  return dateStart.isBefore(todayStart);
}

DateTime getMonthStart(DateTime referenceDate) {
  return DateTime(referenceDate.year, referenceDate.month);
}

bool isMonthAfterReference(DateTime month, DateTime referenceMonth) {
  return month.year > referenceMonth.year ||
      (month.year == referenceMonth.year && month.month > referenceMonth.month);
}

bool isMonthBeforeReference(DateTime month, DateTime referenceMonth) {
  return month.year < referenceMonth.year ||
      (month.year == referenceMonth.year && month.month < referenceMonth.month);
}

List<DateTime?> getMonthCalendarDays(int year, int month) {
  final firstDay = DateTime(year, month, 1);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final emptyCells = firstDay.weekday % 7;

  return [
    ...List<DateTime?>.filled(emptyCells, null),
    ...List<DateTime?>.generate(
      daysInMonth,
      (index) => DateTime(year, month, index + 1),
    ),
  ];
}

String toDateInputValue(DateTime date) => _toDateInputValue(date);

Countdown? findNextUpcomingCountdown(List<Countdown> countdowns, DateTime referenceDate) {
  Countdown? closest;
  int? closestTimestamp;

  for (final countdown in countdowns) {
    final timestamp = getTargetEndTimestamp(normalizeTargetDate(countdown.targetDate));
    if (timestamp == null || timestamp <= referenceDate.millisecondsSinceEpoch) {
      continue;
    }

    if (closestTimestamp == null || timestamp < closestTimestamp) {
      closestTimestamp = timestamp;
      closest = countdown;
    }
  }

  return closest;
}

String formatTimeUntilNextEvent(String targetDate, DateTime referenceDate, {String? eventName}) {
  final remaining = calculateRemainingTime(targetDate, referenceDate);
  if (remaining.expired) {
    return '';
  }

  final durationLabel = formatRemainingTimeSummary(remaining);
  if (eventName == null || eventName.isEmpty) {
    return 'Faltam $durationLabel para o próximo evento';
  }

  return 'Faltam $durationLabel para $eventName';
}
