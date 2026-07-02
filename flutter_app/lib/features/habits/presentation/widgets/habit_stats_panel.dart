import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_stats.dart';

/// Grid de estatísticas reutilizável por tipo de hábito.
class HabitStatsPanel extends StatelessWidget {
  const HabitStatsPanel({super.key, required this.stats, required this.items});

  final HabitStats stats;
  final List<({String label, String value, IconData icon})> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: Gap.x3),
          Expanded(
            child: _StatTile(
              label: items[i].label,
              value: items[i].value,
              icon: items[i].icon,
            ),
          ),
        ],
      ],
    );
  }

  static List<({String label, String value, IconData icon})> forTimeTracker(
    HabitStats stats,
  ) {
    final elapsed = stats.elapsed ?? Duration.zero;
    return [
      (
        label: 'Dias',
        value: '${elapsed.inDays}',
        icon: Icons.calendar_today_rounded,
      ),
      (
        label: 'Semanas',
        value: '${elapsed.inDays ~/ 7}',
        icon: Icons.date_range_rounded,
      ),
      (
        label: 'Meses',
        value: '${elapsed.inDays ~/ 30}',
        icon: Icons.event_rounded,
      ),
    ];
  }

  static List<({String label, String value, IconData icon})> forSession(
    HabitStats stats,
  ) {
    return [
      (
        label: 'Total',
        value: HabitStatsEngine.formatDuration(stats.totalSessionSeconds),
        icon: Icons.schedule_rounded,
      ),
      (
        label: 'Hoje',
        value: HabitStatsEngine.formatDuration(stats.todaySessionSeconds),
        icon: Icons.today_rounded,
      ),
      (
        label: 'Sessões',
        value: '${stats.sessionCount}',
        icon: Icons.repeat_rounded,
      ),
    ];
  }

  static List<({String label, String value, IconData icon})> forSessionDetail(
    HabitStats stats,
  ) {
    return [
      (
        label: 'Semana',
        value: HabitStatsEngine.formatDuration(stats.weekSessionSeconds),
        icon: Icons.view_week_rounded,
      ),
      (
        label: 'Mês',
        value: HabitStatsEngine.formatDuration(stats.monthSessionSeconds),
        icon: Icons.calendar_month_rounded,
      ),
      (
        label: 'Média',
        value: HabitStatsEngine.formatDuration(
          stats.averageSessionSeconds.round(),
        ),
        icon: Icons.analytics_rounded,
      ),
      (
        label: 'Maior',
        value: HabitStatsEngine.formatDuration(stats.longestSessionSeconds),
        icon: Icons.emoji_events_rounded,
      ),
      (
        label: 'Sequência',
        value: pluralize(stats.consecutiveSessionDays, 'dia', 'dias'),
        icon: Icons.local_fire_department_rounded,
      ),
      (
        label: 'Sessões',
        value: '${stats.sessionCount}',
        icon: Icons.repeat_rounded,
      ),
    ];
  }

  static List<({String label, String value, IconData icon})> forQuantity(
    HabitStats stats,
  ) {
    return [
      (
        label: 'Hoje',
        value: '${stats.todayQuantity}/${stats.dailyGoal}',
        icon: Icons.water_drop_rounded,
      ),
      (
        label: 'Total',
        value: '${stats.totalQuantity}',
        icon: Icons.functions_rounded,
      ),
      (
        label: 'Dias ativos',
        value: '${stats.activityDays.length}',
        icon: Icons.calendar_today_rounded,
      ),
    ];
  }

  static List<({String label, String value, IconData icon})> forSimple(
    HabitStats stats,
  ) {
    return [
      (
        label: 'Sequência',
        value: pluralize(stats.currentStreak, 'dia', 'dias'),
        icon: Icons.local_fire_department_rounded,
      ),
      (
        label: 'Recorde',
        value: pluralize(stats.longestStreak, 'dia', 'dias'),
        icon: Icons.emoji_events_rounded,
      ),
      (
        label: 'Hoje',
        value: stats.completedToday ? 'Feito' : 'Pendente',
        icon: stats.completedToday
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
      ),
    ];
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.x3,
        vertical: Gap.x4,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(Corner.md),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: palette.textTertiary),
          const SizedBox(height: Gap.x2),
          Text(
            value,
            style: AppType.headline(palette).copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppType.caption(palette)),
        ],
      ),
    );
  }
}
