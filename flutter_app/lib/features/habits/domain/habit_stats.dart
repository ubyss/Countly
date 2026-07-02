import '../../../core/utils/date_utils.dart';
import 'habit.dart';
import 'habit_event.dart';
import 'habit_kind.dart';

/// Partes de tempo decorrido para exibição rica.
class ElapsedParts {
  const ElapsedParts({
    this.years = 0,
    this.months = 0,
    this.weeks = 0,
    this.days = 0,
    this.hours = 0,
    this.totalDays = 0,
  });

  final int years;
  final int months;
  final int weeks;
  final int days;
  final int hours;
  final int totalDays;

  String get primaryLabel {
    if (years > 0) {
      return years == 1 ? '1 ano' : '$years anos';
    }
    if (months > 0) {
      return months == 1 ? '1 mês' : '$months meses';
    }
    if (weeks > 0) {
      return weeks == 1 ? '1 semana' : '$weeks semanas';
    }
    if (days > 0) {
      return days == 1 ? '1 dia' : '$days dias';
    }
    if (hours > 0) {
      return hours == 1 ? '1 hora' : '$hours horas';
    }
    return 'Agora';
  }

  List<String> get secondaryLabels {
    final parts = <String>[];
    if (years > 0 && months > 0) {
      parts.add(months == 1 ? '1 mês' : '$months meses');
    }
    if (weeks > 0 && years == 0) {
      parts.add(weeks == 1 ? '1 semana' : '$weeks semanas');
    }
    if (days > 0 && months == 0 && years == 0) {
      parts.add(days == 1 ? '1 dia' : '$days dias');
    }
    if (hours > 0 && days == 0 && weeks == 0 && months == 0 && years == 0) {
      parts.add(hours == 1 ? '1 hora' : '$hours horas');
    }
    return parts;
  }
}

/// Estatísticas computadas a partir de eventos + config.
class HabitStats {
  const HabitStats({
    this.elapsed,
    this.isPaused = false,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completedToday = false,
    this.todayQuantity = 0,
    this.dailyGoal = 1,
    this.totalQuantity = 0,
    this.totalSessionSeconds = 0,
    this.todaySessionSeconds = 0,
    this.weekSessionSeconds = 0,
    this.monthSessionSeconds = 0,
    this.sessionCount = 0,
    this.longestSessionSeconds = 0,
    this.averageSessionSeconds = 0,
    this.consecutiveSessionDays = 0,
    this.lastSessionAt,
    this.activityDays = const {},
    this.monthlyActivity = const {},
  });

  final Duration? elapsed;
  final bool isPaused;
  final int currentStreak;
  final int longestStreak;
  final bool completedToday;
  final int todayQuantity;
  final int dailyGoal;
  final int totalQuantity;
  final int totalSessionSeconds;
  final int todaySessionSeconds;
  final int weekSessionSeconds;
  final int monthSessionSeconds;
  final int sessionCount;
  final int longestSessionSeconds;
  final double averageSessionSeconds;
  final int consecutiveSessionDays;
  final DateTime? lastSessionAt;
  final Set<DateTime> activityDays;
  final Map<int, int> monthlyActivity;

  double get quantityProgress =>
      dailyGoal <= 0 ? 0 : (todayQuantity / dailyGoal).clamp(0.0, 1.0);

  bool get quantityGoalReached => todayQuantity >= dailyGoal;
}

/// Motor de estatísticas — lógica centralizada, sem duplicação por tipo.
class HabitStatsEngine {
  const HabitStatsEngine._();

  static HabitStats compute(Habit habit, DateTime now) {
    switch (habit.kind) {
      case HabitKind.timeTracker:
        return _timeTracker(habit, now);
      case HabitKind.session:
        return _session(habit, now);
      case HabitKind.quantity:
        return _quantity(habit, now);
      case HabitKind.simple:
        return _simple(habit, now);
    }
  }

  static ElapsedParts formatElapsed(Duration duration) {
    final totalDays = duration.inDays;
    final years = totalDays ~/ 365;
    var remainder = totalDays % 365;
    final months = remainder ~/ 30;
    remainder = remainder % 30;
    final weeks = remainder ~/ 7;
    final days = remainder % 7;
    final hours = duration.inHours % 24;

    return ElapsedParts(
      years: years,
      months: months,
      weeks: weeks,
      days: days,
      hours: hours,
      totalDays: totalDays,
    );
  }

  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  static String formatDurationLong(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) {
      return pluralize(hours, 'hora', 'horas') +
          ' e ' +
          pluralize(minutes, 'minuto', 'minutos');
    }
    if (hours > 0) {
      return pluralize(hours, 'hora', 'horas');
    }
    if (minutes > 0) {
      return pluralize(minutes, 'minuto', 'minutos');
    }
    return pluralize(totalSeconds, 'segundo', 'segundos');
  }

  static HabitStats _timeTracker(Habit habit, DateTime now) {
    final sorted = _sortedEvents(habit);
    var elapsed = Duration.zero;
    DateTime? periodStart = habit.startAt;
    var paused = false;

    for (final event in sorted) {
      switch (event.type) {
        case HabitEventType.trackerStarted:
        case HabitEventType.trackerResumed:
          elapsed = Duration.zero;
          periodStart = event.at;
          paused = false;
        case HabitEventType.trackerPaused:
          if (periodStart != null && !paused) {
            elapsed += event.at.difference(periodStart);
          }
          paused = true;
          periodStart = null;
        case HabitEventType.trackerReset:
          elapsed = Duration.zero;
          periodStart = event.at;
          paused = false;
        default:
          break;
      }
    }

    if (!paused && periodStart != null) {
      elapsed += now.difference(periodStart);
    }

    final activityDays = _activityDaysFromEvents(habit);
    return HabitStats(
      elapsed: elapsed,
      isPaused: paused,
      currentStreak: elapsed.inDays,
      longestStreak: elapsed.inDays,
      activityDays: activityDays,
      monthlyActivity: _monthlyCounts(activityDays, now),
    );
  }

  static HabitStats _session(Habit habit, DateTime now) {
    final sessions = habit.events
        .where((e) => e.type == HabitEventType.sessionCompleted)
        .toList();
    final weekStart = dateOnly(now).subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    var total = 0;
    var today = 0;
    var week = 0;
    var month = 0;
    var longest = 0;
    DateTime? lastAt;

    for (final event in sessions) {
      final seconds = event.value ?? 0;
      total += seconds;
      if (seconds > longest) {
        longest = seconds;
      }
      if (isSameDay(event.at, now)) {
        today += seconds;
      }
      if (!event.at.isBefore(weekStart)) {
        week += seconds;
      }
      if (!event.at.isBefore(monthStart)) {
        month += seconds;
      }
      if (lastAt == null || event.at.isAfter(lastAt)) {
        lastAt = event.at;
      }
    }

    if (habit.activeSession != null) {
      final live = habit.activeSession!.elapsedSeconds(now);
      total += live;
      if (isSameDay(habit.activeSession!.startedAt, now)) {
        today += live;
      }
    }

    final sessionDays = sessions.map((e) => dateOnly(e.at)).toSet();
    final consecutive = _consecutiveDays(sessionDays, now);
    final activityDays = _activityDaysFromEvents(habit);

    return HabitStats(
      totalSessionSeconds: total,
      todaySessionSeconds: today,
      weekSessionSeconds: week,
      monthSessionSeconds: month,
      sessionCount: sessions.length,
      longestSessionSeconds: longest,
      averageSessionSeconds:
          sessions.isEmpty ? 0 : total / sessions.length,
      consecutiveSessionDays: consecutive,
      lastSessionAt: lastAt,
      activityDays: activityDays,
      monthlyActivity: _monthlyCounts(activityDays, now),
    );
  }

  static HabitStats _quantity(Habit habit, DateTime now) {
    var todayQty = 0;
    var totalQty = 0;

    for (final event in habit.events) {
      if (event.type != HabitEventType.quantityLog) {
        continue;
      }
      final delta = event.value ?? 0;
      totalQty += delta;
      if (isSameDay(event.at, now)) {
        todayQty += delta;
      }
    }
    todayQty = todayQty.clamp(0, 1 << 30);

    final activityDays = habit.events
        .where((e) => e.type == HabitEventType.quantityLog && (e.value ?? 0) > 0)
        .map((e) => dateOnly(e.at))
        .toSet();

    return HabitStats(
      todayQuantity: todayQty,
      dailyGoal: habit.dailyGoal,
      totalQuantity: totalQty,
      completedToday: todayQty >= habit.dailyGoal,
      activityDays: activityDays,
      monthlyActivity: _monthlyCounts(activityDays, now),
    );
  }

  static HabitStats _simple(Habit habit, DateTime now) {
    final completionDays = habit.events
        .where((e) => e.type == HabitEventType.simpleCompleted)
        .map((e) => dateOnly(e.at))
        .toSet();

    final current = _consecutiveDays(completionDays, now);
    final longest = _longestStreak(completionDays);
    final completedToday = completionDays.any((d) => isSameDay(d, now));

    return HabitStats(
      currentStreak: current,
      longestStreak: longest,
      completedToday: completedToday,
      activityDays: completionDays,
      monthlyActivity: _monthlyCounts(completionDays, now),
    );
  }

  static List<HabitEvent> _sortedEvents(Habit habit) {
    return [...habit.events]..sort((a, b) => a.at.compareTo(b.at));
  }

  static Set<DateTime> _activityDaysFromEvents(Habit habit) {
    return habit.events
        .where((e) =>
            e.type == HabitEventType.sessionCompleted ||
            e.type == HabitEventType.quantityLog ||
            e.type == HabitEventType.simpleCompleted ||
            e.type == HabitEventType.trackerStarted)
        .map((e) => dateOnly(e.at))
        .toSet();
  }

  static Map<int, int> _monthlyCounts(Set<DateTime> days, DateTime now) {
    final counts = <int, int>{};
    for (var day = 1; day <= DateTime(now.year, now.month + 1, 0).day; day++) {
      counts[day] = 0;
    }
    for (final day in days) {
      if (isSameMonth(day, now)) {
        counts[day.day] = (counts[day.day] ?? 0) + 1;
      }
    }
    return counts;
  }

  static int _consecutiveDays(Set<DateTime> days, DateTime now) {
    if (days.isEmpty) {
      return 0;
    }
    var streak = 0;
    var cursor = dateOnly(now);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _longestStreak(Set<DateTime> days) {
    if (days.isEmpty) {
      return 0;
    }
    final sorted = days.toList()..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (daysBetween(sorted[i - 1], sorted[i]) == 1) {
        current++;
        if (current > longest) {
          longest = current;
        }
      } else {
        current = 1;
      }
    }
    return longest;
  }
}
