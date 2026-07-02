import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../domain/habit.dart';
import '../../domain/habit_kind.dart';
import '../../domain/habit_stats.dart';
import '../../domain/milestone.dart';
import 'quantity_dots.dart';
import 'session_timer_panel.dart';
import 'time_elapsed_display.dart';

/// Card de hábito com identidade visual por tipo.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.now,
    required this.onTap,
    this.onQuickAction,
  });

  final Habit habit;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).habits;
    final stats = controller.statsFor(habit, now);
    final palette = context.palette;
    final accent =
        CountlyAccents.adaptive(habit.accent, Theme.of(context).brightness);

    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: habit.title,
      child: Container(
        padding: const EdgeInsets.all(Gap.x4),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(Corner.lg),
          border: Border.all(color: palette.outline),
          boxShadow: Elevations.soft(palette),
        ),
        child: switch (habit.kind) {
          HabitKind.timeTracker => _TimeTrackerCard(
              habit: habit,
              stats: stats,
              accent: accent,
              now: now,
            ),
          HabitKind.session => _SessionCard(
              habit: habit,
              stats: stats,
              accent: accent,
              now: now,
            ),
          HabitKind.quantity => _QuantityCard(
              habit: habit,
              stats: stats,
              accent: accent,
              onQuickAction: onQuickAction,
            ),
          HabitKind.simple => _SimpleCard(
              habit: habit,
              stats: stats,
              accent: accent,
              onQuickAction: onQuickAction,
            ),
        },
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.habit,
    required this.accent,
    required this.subtitle,
    this.trailing,
  });

  final Habit habit;
  final Color accent;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Hero(
          tag: 'habit-icon-${habit.id}',
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.resolve(habit.iconName), color: accent, size: 22),
          ),
        ),
        const SizedBox(width: Gap.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.headline(palette),
              ),
              Text(subtitle, style: AppType.caption(palette)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TimeTrackerCard extends StatelessWidget {
  const _TimeTrackerCard({
    required this.habit,
    required this.stats,
    required this.accent,
    required this.now,
  });

  final Habit habit;
  final HabitStats stats;
  final Color accent;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final elapsed = stats.elapsed ?? Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeader(
          habit: habit,
          accent: accent,
          subtitle: stats.isPaused ? 'Pausado' : 'Time tracker',
          trailing: TimeElapsedDisplay(
            elapsed: elapsed,
            accent: accent,
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.habit,
    required this.stats,
    required this.accent,
    required this.now,
  });

  final Habit habit;
  final HabitStats stats;
  final Color accent;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final session = habit.activeSession;
    final liveSeconds = session?.elapsedSeconds(now) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeader(
          habit: habit,
          accent: accent,
          subtitle: stats.lastSessionAt != null
              ? 'Última: ${formatDayMonth(stats.lastSessionAt!)}'
              : 'Nenhuma sessão ainda',
          trailing: Text(
            HabitStatsEngine.formatDuration(
              session != null ? liveSeconds : stats.totalSessionSeconds,
            ),
            style: AppType.metric(context.palette).copyWith(
              color: accent,
              fontSize: 20,
            ),
          ),
        ),
        if (session != null) ...[
          const SizedBox(height: Gap.x3),
          SessionTimerPanel(
            elapsedSeconds: liveSeconds,
            isRunning: session.isRunning,
            isPaused: session.isPaused,
            accent: accent,
            onStart: () {},
            onPause: () {},
            onResume: () {},
            onFinish: () {},
            compact: true,
          ),
        ],
      ],
    );
  }
}

class _QuantityCard extends StatelessWidget {
  const _QuantityCard({
    required this.habit,
    required this.stats,
    required this.accent,
    this.onQuickAction,
  });

  final Habit habit;
  final HabitStats stats;
  final Color accent;
  final VoidCallback? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).habits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeader(
          habit: habit,
          accent: accent,
          subtitle:
              '${stats.todayQuantity}/${stats.dailyGoal} ${habit.unitLabel.isNotEmpty ? habit.unitLabel : 'unidades'}',
          trailing: ProgressRing(
            progress: stats.quantityProgress,
            color: stats.quantityGoalReached ? context.palette.success : accent,
            size: 44,
            strokeWidth: 4,
            child: Text(
              '${stats.todayQuantity}',
              style: AppType.caption(context.palette).copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.x3),
        QuantityDots(
          current: stats.todayQuantity,
          goal: stats.dailyGoal,
          accent: accent,
          onTap: () {
            controller.addQuantity(habit.id);
            onQuickAction?.call();
          },
          onLongPress: stats.todayQuantity > 0
              ? () => controller.removeQuantity(habit.id)
              : null,
        ),
      ],
    );
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({
    required this.habit,
    required this.stats,
    required this.accent,
    this.onQuickAction,
  });

  final Habit habit;
  final HabitStats stats;
  final Color accent;
  final VoidCallback? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).habits;
    final palette = context.palette;
    final streak = stats.currentStreak;
    final nextMilestone = Milestone.nextFor(streak);

    return Row(
      children: [
        Hero(
          tag: 'habit-ring-${habit.id}',
          child: ProgressRing(
            progress: stats.completedToday ? 1 : Milestone.progressFor(streak),
            color: stats.completedToday ? palette.success : accent,
            size: 64,
            strokeWidth: 5,
            child: Icon(
              stats.completedToday
                  ? Icons.check_rounded
                  : AppIcons.resolve(habit.iconName),
              size: 24,
              color: stats.completedToday ? palette.success : accent,
            ),
          ),
        ),
        const SizedBox(width: Gap.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.headline(palette),
              ),
              Text(
                stats.completedToday
                    ? 'Concluído hoje ✓'
                    : nextMilestone == null
                        ? 'Todos os marcos!'
                        : 'Próximo: ${nextMilestone.title}',
                style: AppType.footnote(palette),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (stats.completedToday) {
              controller.uncompleteSimple(habit.id);
            } else {
              controller.completeSimple(habit.id);
            }
            onQuickAction?.call();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$streak',
                style: AppType.metric(palette).copyWith(color: accent),
              ),
              Text(
                streak == 1 ? 'dia' : 'dias',
                style: AppType.caption(palette),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
