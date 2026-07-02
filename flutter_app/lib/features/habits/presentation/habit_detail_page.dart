import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/staggered_list.dart';
import '../domain/habit.dart';
import '../domain/habit_event.dart';
import '../domain/habit_kind.dart';
import '../domain/habit_stats.dart';
import '../domain/milestone.dart';
import 'habit_editor_sheet.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/habit_stats_panel.dart';
import 'widgets/quantity_dots.dart';
import 'widgets/session_timer_panel.dart';
import 'widgets/time_elapsed_display.dart';

/// Detalhe do hábito — layout e ações por tipo.
class HabitDetailPage extends StatefulWidget {
  const HabitDetailPage({super.key, required this.habitId});

  final String habitId;

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).habits;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final habit = controller.byId(widget.habitId);
        if (habit == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return _HabitDetailBody(habit: habit, now: _now);
      },
    );
  }
}

class _HabitDetailBody extends StatelessWidget {
  const _HabitDetailBody({required this.habit, required this.now});

  final Habit habit;
  final DateTime now;

  Future<void> _delete(BuildContext context) async {
    final controller = AppScope.of(context).habits;
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir hábito?',
      message: '"${habit.title}" e todo o histórico serão removidos.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    navigator.pop();
    await controller.remove(habit.id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).habits;
    final stats = controller.statsFor(habit, now);
    final palette = context.palette;
    final accent =
        CountlyAccents.adaptive(habit.accent, Theme.of(context).brightness);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.x4, Gap.x2, Gap.x4, 0),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Voltar',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    RoundIconButton(
                      icon: Icons.edit_rounded,
                      tooltip: 'Editar',
                      onTap: () =>
                          showHabitEditorSheet(context, existing: habit),
                    ),
                    const SizedBox(width: Gap.x2),
                    RoundIconButton(
                      icon: Icons.archive_rounded,
                      tooltip: 'Arquivar',
                      onTap: () {
                        Navigator.of(context).pop();
                        controller.setArchived(habit.id, true);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Gap.page,
                Gap.x4,
                Gap.page,
                Gap.x12,
              ),
              sliver: SliverList.list(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Hero(
                          tag: habit.kind == HabitKind.simple
                              ? 'habit-ring-${habit.id}'
                              : 'habit-icon-${habit.id}',
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              AppIcons.resolve(habit.iconName),
                              size: 32,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: Gap.x3),
                        Text(habit.title, style: AppType.title(palette)),
                        if (habit.category != null) ...[
                          const SizedBox(height: Gap.x1),
                          Text(habit.category!, style: AppType.caption(palette)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.x6),
                  switch (habit.kind) {
                    HabitKind.timeTracker => _TimeTrackerSection(
                        habit: habit,
                        stats: stats,
                        accent: accent,
                        now: now,
                      ),
                    HabitKind.session => _SessionSection(
                        habit: habit,
                        stats: stats,
                        accent: accent,
                        now: now,
                      ),
                    HabitKind.quantity => _QuantitySection(
                        habit: habit,
                        stats: stats,
                        accent: accent,
                      ),
                    HabitKind.simple => _SimpleSection(
                        habit: habit,
                        stats: stats,
                        accent: accent,
                      ),
                  },
                  const SizedBox(height: Gap.x8),
                  Text('ATIVIDADE', style: AppType.overline(palette)),
                  const SizedBox(height: Gap.x3),
                  ActivityHeatmap(
                    activityDays: stats.activityDays,
                    month: now,
                    accent: accent,
                  ),
                  if (habit.notes.isNotEmpty) ...[
                    const SizedBox(height: Gap.x8),
                    Text('NOTAS', style: AppType.overline(palette)),
                    const SizedBox(height: Gap.x3),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Gap.x5),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(Corner.lg),
                        border: Border.all(color: palette.outline),
                      ),
                      child: Text(habit.notes, style: AppType.body(palette)),
                    ),
                  ],
                  if (_hasHistory(habit)) ...[
                    const SizedBox(height: Gap.x8),
                    Text('HISTÓRICO', style: AppType.overline(palette)),
                    const SizedBox(height: Gap.x3),
                    _EventHistory(habit: habit),
                  ],
                  const SizedBox(height: Gap.x8),
                  Center(
                    child: TextButton(
                      onPressed: () => _delete(context),
                      child: Text(
                        'Excluir hábito',
                        style: AppType.footnote(palette)
                            .copyWith(color: palette.danger),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasHistory(Habit habit) {
    return habit.events.length > 1 ||
        habit.kind == HabitKind.session ||
        habit.kind == HabitKind.quantity;
  }
}

class _TimeTrackerSection extends StatelessWidget {
  const _TimeTrackerSection({
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
    final controller = AppScope.of(context).habits;
    final elapsed = stats.elapsed ?? Duration.zero;

    return Column(
      children: [
        StaggeredReveal(
          index: 0,
          child: TimeElapsedDisplay(elapsed: elapsed, accent: accent),
        ),
        const SizedBox(height: Gap.x6),
        StaggeredReveal(
          index: 1,
          child: HabitStatsPanel(
            stats: stats,
            items: HabitStatsPanel.forTimeTracker(stats),
          ),
        ),
        const SizedBox(height: Gap.x6),
        StaggeredReveal(
          index: 2,
          child: _ControlsRow(
            paused: stats.isPaused,
            accent: accent,
            onPauseResume: () => stats.isPaused
                ? controller.resumeTracker(habit.id)
                : controller.pauseTracker(habit.id),
            onReset: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Zerar contador?',
                message: 'O tempo será reiniciado agora. O histórico é mantido.',
                confirmLabel: 'Zerar',
                destructive: true,
              );
              if (confirmed) {
                await controller.resetTracker(habit.id);
              }
            },
          ),
        ),
        if (habit.startAt != null) ...[
          const SizedBox(height: Gap.x4),
          Text(
            'Desde ${formatFullDate(habit.startAt!)}',
            style: AppType.footnote(context.palette),
          ),
        ],
      ],
    );
  }
}

class _SessionSection extends StatelessWidget {
  const _SessionSection({
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
    final controller = AppScope.of(context).habits;
    final session = habit.activeSession;
    final elapsed = session?.elapsedSeconds(now) ?? 0;

    return Column(
      children: [
        StaggeredReveal(
          index: 0,
          child: SessionTimerPanel(
            elapsedSeconds: elapsed,
            isRunning: session?.isRunning ?? false,
            isPaused: session?.isPaused ?? false,
            accent: accent,
            onStart: () => controller.startSession(habit.id),
            onPause: () => controller.pauseSession(habit.id),
            onResume: () => controller.resumeSession(habit.id),
            onFinish: () => controller.endSession(habit.id),
          ),
        ),
        const SizedBox(height: Gap.x6),
        StaggeredReveal(
          index: 1,
          child: HabitStatsPanel(
            stats: stats,
            items: HabitStatsPanel.forSession(stats),
          ),
        ),
        const SizedBox(height: Gap.x4),
        StaggeredReveal(
          index: 2,
          child: Wrap(
            spacing: Gap.x3,
            runSpacing: Gap.x3,
            children: HabitStatsPanel.forSessionDetail(stats)
                .skip(3)
                .map(
                  (item) => SizedBox(
                    width: (MediaQuery.sizeOf(context).width - Gap.page * 2 - Gap.x3) / 2,
                    child: _MiniStat(
                      label: item.label,
                      value: item.value,
                      icon: item.icon,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _QuantitySection extends StatelessWidget {
  const _QuantitySection({
    required this.habit,
    required this.stats,
    required this.accent,
  });

  final Habit habit;
  final HabitStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).habits;
    final palette = context.palette;
    final unit = habit.unitLabel.isNotEmpty ? habit.unitLabel : 'unidades';

    return Column(
      children: [
        StaggeredReveal(
          index: 0,
          child: ProgressRing(
            progress: stats.quantityProgress,
            color: stats.quantityGoalReached ? palette.success : accent,
            size: 140,
            strokeWidth: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${stats.todayQuantity}',
                  style: AppType.display(palette).copyWith(fontSize: 36),
                ),
                Text('/ ${stats.dailyGoal} $unit', style: AppType.caption(palette)),
              ],
            ),
          ),
        ),
        const SizedBox(height: Gap.x6),
        StaggeredReveal(
          index: 1,
          child: QuantityDots(
            current: stats.todayQuantity,
            goal: stats.dailyGoal,
            accent: accent,
            onTap: () => controller.addQuantity(habit.id),
            onLongPress: stats.todayQuantity > 0
                ? () => controller.removeQuantity(habit.id)
                : null,
          ),
        ),
        const SizedBox(height: Gap.x4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallAction(
              label: '+5',
              onTap: () => controller.addQuantity(habit.id, amount: 5),
            ),
            const SizedBox(width: Gap.x2),
            _SmallAction(
              label: '−1',
              onTap: () => controller.removeQuantity(habit.id),
            ),
          ],
        ),
        const SizedBox(height: Gap.x6),
        StaggeredReveal(
          index: 2,
          child: HabitStatsPanel(
            stats: stats,
            items: HabitStatsPanel.forQuantity(stats),
          ),
        ),
      ],
    );
  }
}

class _SimpleSection extends StatelessWidget {
  const _SimpleSection({
    required this.habit,
    required this.stats,
    required this.accent,
  });

  final Habit habit;
  final HabitStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).habits;
    final palette = context.palette;
    final streak = stats.currentStreak;

    return Column(
      children: [
        StaggeredReveal(
          index: 0,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              if (stats.completedToday) {
                controller.uncompleteSimple(habit.id);
              } else {
                controller.completeSimple(habit.id);
              }
            },
            child: ProgressRing(
              progress: stats.completedToday ? 1 : Milestone.progressFor(streak),
              color: stats.completedToday ? palette.success : accent,
              size: 168,
              strokeWidth: 11,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stats.completedToday
                        ? Icons.check_rounded
                        : Icons.touch_app_rounded,
                    size: 28,
                    color: stats.completedToday ? palette.success : accent,
                  ),
                  const SizedBox(height: Gap.x1),
                  Text(
                    stats.completedToday ? '✓' : '$streak',
                    style: AppType.display(palette).copyWith(fontSize: 44),
                  ),
                  Text(
                    stats.completedToday ? 'FEITO' : (streak == 1 ? 'DIA' : 'DIAS'),
                    style: AppType.overline(palette),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.x4),
        Text(
          stats.completedToday
              ? 'Concluído hoje — toque para desfazer'
              : 'Toque para marcar como feito',
          style: AppType.footnote(palette),
        ),
        const SizedBox(height: Gap.x6),
        StaggeredReveal(
          index: 1,
          child: HabitStatsPanel(
            stats: stats,
            items: HabitStatsPanel.forSimple(stats),
          ),
        ),
        const SizedBox(height: Gap.x6),
        StaggeredReveal(
          index: 2,
          child: _MilestoneGrid(
            achievedDays: stats.longestStreak,
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.paused,
    required this.accent,
    required this.onPauseResume,
    required this.onReset,
  });

  final bool paused;
  final Color accent;
  final VoidCallback onPauseResume;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: onPauseResume,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: paused ? accent : palette.surfaceSunken,
                borderRadius: BorderRadius.circular(Corner.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: paused ? Colors.white : palette.textSecondary,
                  ),
                  const SizedBox(width: Gap.x2),
                  Text(
                    paused ? 'Retomar' : 'Pausar',
                    style: AppType.headline(palette).copyWith(
                      color: paused ? Colors.white : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: Gap.x3),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: onReset,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: palette.dangerSoft,
                borderRadius: BorderRadius.circular(Corner.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.replay_rounded, color: palette.danger, size: 20),
                  const SizedBox(width: Gap.x2),
                  Text(
                    'Zerar',
                    style: AppType.headline(palette).copyWith(color: palette.danger),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MilestoneGrid extends StatelessWidget {
  const _MilestoneGrid({required this.achievedDays, required this.accent});

  final int achievedDays;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: Gap.x3,
        crossAxisSpacing: Gap.x3,
        childAspectRatio: 0.8,
      ),
      itemCount: Milestone.all.length,
      itemBuilder: (context, index) {
        final milestone = Milestone.all[index];
        final achieved = achievedDays >= milestone.days;

        return Column(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: achieved ? 1 : 0.35,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: achieved
                      ? accent.withValues(alpha: 0.14)
                      : palette.surfaceSunken,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: achieved ? accent : palette.outline,
                    width: achieved ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(milestone.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              milestone.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption(palette).copyWith(
                color: achieved ? palette.textSecondary : palette.textTertiary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EventHistory extends StatelessWidget {
  const _EventHistory({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final events = [...habit.events]
      ..sort((a, b) => b.at.compareTo(a.at));
    final visible = events.take(20).toList();

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(Corner.lg),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) Divider(color: palette.outline, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.x4,
                vertical: Gap.x3,
              ),
              child: Row(
                children: [
                  Icon(
                    _iconFor(visible[i].type),
                    size: 18,
                    color: palette.textTertiary,
                  ),
                  const SizedBox(width: Gap.x3),
                  Expanded(
                    child: Text(
                      _labelFor(visible[i]),
                      style: AppType.footnote(palette),
                    ),
                  ),
                  Text(
                    formatDayMonth(visible[i].at),
                    style: AppType.caption(palette),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(HabitEventType type) {
    switch (type) {
      case HabitEventType.sessionCompleted:
        return Icons.timer_rounded;
      case HabitEventType.quantityLog:
        return Icons.add_circle_outline_rounded;
      case HabitEventType.simpleCompleted:
        return Icons.check_circle_rounded;
      case HabitEventType.trackerReset:
        return Icons.replay_rounded;
      case HabitEventType.trackerPaused:
        return Icons.pause_rounded;
      case HabitEventType.trackerResumed:
        return Icons.play_arrow_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _labelFor(HabitEvent event) {
    switch (event.type) {
      case HabitEventType.sessionCompleted:
        return 'Sessão: ${HabitStatsEngine.formatDuration(event.value ?? 0)}';
      case HabitEventType.quantityLog:
        final v = event.value ?? 0;
        return v >= 0 ? '+$v unidades' : '$v unidades';
      case HabitEventType.simpleCompleted:
        return 'Concluído';
      case HabitEventType.trackerStarted:
        return 'Início';
      case HabitEventType.trackerPaused:
        return 'Pausado';
      case HabitEventType.trackerResumed:
        return 'Retomado';
      case HabitEventType.trackerReset:
        return 'Reiniciado';
      default:
        return event.type.name;
    }
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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
      padding: const EdgeInsets.all(Gap.x3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(Corner.md),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: palette.textTertiary),
          const SizedBox(width: Gap.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppType.footnote(palette)),
                Text(label, style: AppType.caption(palette)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.x4, vertical: Gap.x2),
        decoration: BoxDecoration(
          color: palette.surfaceSunken,
          borderRadius: BorderRadius.circular(Corner.pill),
        ),
        child: Text(label, style: AppType.headline(palette)),
      ),
    );
  }
}
