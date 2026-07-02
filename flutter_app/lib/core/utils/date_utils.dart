import 'package:intl/intl.dart';

/// Normaliza qualquer entrada de data para o formato ISO `yyyy-MM-dd`.
String normalizeIsoDate(dynamic value) {
  if (value is num && value.isFinite) {
    return toIsoDate(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
  }
  if (value is DateTime) {
    return toIsoDate(value);
  }
  if (value is! String) {
    return '';
  }

  final trimmed = value.trim();
  final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
  if (isoMatch != null) {
    return '${isoMatch.group(1)}-${isoMatch.group(2)}-${isoMatch.group(3)}';
  }

  final brMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(trimmed);
  if (brMatch != null) {
    final day = int.parse(brMatch.group(1)!);
    final month = int.parse(brMatch.group(2)!);
    final year = int.parse(brMatch.group(3)!);
    final parsed = DateTime(year, month, day);
    if (parsed.year == year && parsed.month == month && parsed.day == day) {
      return toIsoDate(parsed);
    }
    return '';
  }

  final parsed = DateTime.tryParse(trimmed);
  return parsed == null ? '' : toIsoDate(parsed);
}

String toIsoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime? isoToLocalDate(String isoDate) {
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

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

int daysBetween(DateTime from, DateTime to) =>
    dateOnly(to).difference(dateOnly(from)).inDays;

/// "12 de março de 2026"
String formatFullDate(DateTime date) =>
    DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(date);

/// "12 de março"
String formatDayMonth(DateTime date) =>
    DateFormat("d 'de' MMMM", 'pt_BR').format(date);

/// "março de 2026"
String formatMonthYear(DateTime date) {
  final formatted = DateFormat('MMMM y', 'pt_BR').format(date);
  return formatted[0].toUpperCase() + formatted.substring(1);
}

/// "seg", "ter"...
String formatShortWeekday(DateTime date) =>
    DateFormat('E', 'pt_BR').format(date).replaceAll('.', '');

/// "segunda-feira, 12 de março"
String formatWeekdayFullDate(DateTime date) {
  final formatted = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(date);
  return formatted[0].toUpperCase() + formatted.substring(1);
}

/// "12/03/2026"
String formatBrazilianDate(DateTime date) =>
    DateFormat('dd/MM/yyyy').format(date);

/// Células (com nulos à esquerda) para renderizar o grid de um mês
/// começando no domingo.
List<DateTime?> monthCalendarCells(int year, int month) {
  final firstDay = DateTime(year, month, 1);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final leading = firstDay.weekday % 7;
  return [
    ...List<DateTime?>.filled(leading, null),
    ...List<DateTime?>.generate(
      daysInMonth,
      (index) => DateTime(year, month, index + 1),
    ),
  ];
}

String pluralize(int value, String singular, String plural) =>
    '$value ${value == 1 ? singular : plural}';
