import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../core/utils/date_utils.dart';
import '../features/counters/domain/counter.dart';
import '../features/counters/domain/counter_snapshot.dart';
import '../features/habits/domain/habit.dart';
import '../features/habits/domain/habit_kind.dart';
import '../features/habits/domain/habit_stats.dart';

const _smallProvider = 'com.countly.countly.CountlySmallWidgetProvider';
const _mediumProvider = 'com.countly.countly.CountlyWidgetProvider';
const _largeProvider = 'com.countly.countly.CountlyLargeWidgetProvider';

/// Publica os dados dos widgets Android (pequeno, médio e grande).
///
/// Os payloads são serializados em JSON e lidos pelos providers Kotlin.
class HomeWidgetService {
  HomeWidgetService._();

  static final HomeWidgetService instance = HomeWidgetService._();

  bool get _supported => !kIsWeb && Platform.isAndroid;

  Future<void> initialize() async {
    if (!_supported) {
      return;
    }
    await HomeWidget.setAppGroupId('group.com.countly.countly');
  }

  Future<void> sync(List<Counter> counters, List<Habit> habits) async {
    if (!_supported) {
      return;
    }

    final now = DateTime.now();
    final active = counters.where((counter) => !counter.archived).toList();

    await _saveFeatured(active, now);
    await _saveCounterList(active, now);
    await _saveCalendar(active, now);
    await _saveHabit(habits, now);

    for (final provider in const [
      _smallProvider,
      _mediumProvider,
      _largeProvider,
    ]) {
      await HomeWidget.updateWidget(qualifiedAndroidName: provider);
    }
  }

  /// Contagem em destaque: favorita mais próxima ou o próximo evento.
  Future<void> _saveFeatured(List<Counter> counters, DateTime now) async {
    final favorites = counters.where((counter) => counter.favorite).toList();
    final featured = nextUpcomingCounter(favorites, now) ??
        nextUpcomingCounter(counters, now) ??
        (counters.isEmpty ? null : counters.first);

    if (featured == null) {
      await HomeWidget.saveWidgetData<String>('widget_featured', '');
      return;
    }

    final snapshot = CounterSnapshot.of(featured, now);
    final unit = snapshot.units.first;
    final imagePath = await _saveWidgetImage(featured.imageBase64, featured.id);

    await HomeWidget.saveWidgetData<String>(
      'widget_featured',
      jsonEncode({
        'title': featured.title,
        'value': snapshot.isToday ? '🎉' : unit.padded,
        'unit': snapshot.isToday ? 'É hoje' : unit.label.toUpperCase(),
        'headline': snapshot.headline,
        'dateLabel': snapshot.eventDate == null
            ? ''
            : formatDayMonth(snapshot.eventDate!),
        'color': featured.accentColor,
        'progress': _progressFor(featured, snapshot, now),
        'imagePath': imagePath ?? '',
      }),
    );
  }

  Future<void> _saveCounterList(List<Counter> counters, DateTime now) async {
    final sorted = [...counters]..sort((a, b) {
        final aSnap = CounterSnapshot.of(a, now);
        final bSnap = CounterSnapshot.of(b, now);
        final aDate = aSnap.eventDate;
        final bDate = bSnap.eventDate;
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return aDate.compareTo(bDate);
      });

    final items = sorted.take(4).map((counter) {
      final snapshot = CounterSnapshot.of(counter, now);
      final unit = snapshot.units.first;
      return {
        'title': counter.title,
        'value': snapshot.isToday ? '0' : unit.value.toString(),
        'unit': snapshot.isToday ? 'HOJE' : unit.label.toUpperCase(),
        'color': counter.accentColor,
        'countsUp': snapshot.countsUp,
      };
    }).toList();

    await HomeWidget.saveWidgetData<String>(
      'widget_counters',
      jsonEncode(items),
    );
  }

  Future<void> _saveCalendar(List<Counter> counters, DateTime now) async {
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final eventDays = <int>{};

    for (final counter in counters) {
      final target = counter.targetLocalDate;
      if (target == null) {
        continue;
      }
      for (final date
          in counter.recurrence.occurrencesBetween(target, monthStart, monthEnd)) {
        eventDays.add(date.day);
      }
    }

    await HomeWidget.saveWidgetData<String>(
      'widget_calendar',
      jsonEncode({
        'monthLabel': formatMonthYear(now),
        'daysInMonth': monthEnd.day,
        'firstWeekday': monthStart.weekday % 7,
        'today': now.day,
        'eventDays': eventDays.toList()..sort(),
      }),
    );
  }

  Future<void> _saveHabit(List<Habit> habits, DateTime now) async {
    final active = habits.where((habit) => !habit.archived).toList();
    if (active.isEmpty) {
      await HomeWidget.saveWidgetData<String>('widget_habit', '');
      return;
    }

    active.sort((a, b) {
      final sa = _habitWidgetScore(a, now);
      final sb = _habitWidgetScore(b, now);
      return sb.compareTo(sa);
    });
    final top = active.first;
    final stats = HabitStatsEngine.compute(top, now);

    await HomeWidget.saveWidgetData<String>(
      'widget_habit',
      jsonEncode({
        'title': top.title,
        'streak': _habitWidgetScore(top, now),
        'color': top.accentColor,
        'paused': stats.isPaused,
        'kind': top.kind.name,
      }),
    );
  }

  int _habitWidgetScore(Habit habit, DateTime now) {
    final stats = HabitStatsEngine.compute(habit, now);
    switch (habit.kind) {
      case HabitKind.timeTracker:
        return stats.elapsed?.inDays ?? 0;
      case HabitKind.simple:
        return stats.currentStreak;
      case HabitKind.session:
        return stats.consecutiveSessionDays;
      case HabitKind.quantity:
        return stats.todayQuantity;
    }
  }

  double _progressFor(Counter counter, CounterSnapshot snapshot, DateTime now) {
    final eventDate = snapshot.eventDate;
    if (eventDate == null || !snapshot.isCountdown) {
      return 1;
    }
    final total = daysBetween(counter.createdAt, eventDate);
    if (total <= 0) {
      return 1;
    }
    final elapsed = daysBetween(counter.createdAt, now);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Future<String?> _saveWidgetImage(String? imageBase64, String counterId) async {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return null;
    }
    try {
      final bytes = base64Decode(imageBase64);
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 640);
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      if (byteData == null) {
        return null;
      }
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/widget_$counterId.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
