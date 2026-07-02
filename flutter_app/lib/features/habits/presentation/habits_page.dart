import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/staggered_list.dart';
import 'habit_detail_page.dart';
import 'habit_editor_sheet.dart';
import 'widgets/habit_card.dart';

/// Página de hábitos com atualização em tempo real.
class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    final controller = AppScope.of(context).habits;
    final interval = controller.hasLiveSession
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);
    _ticker = Timer.periodic(interval, (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
      final needsFastTick = AppScope.of(context).habits.hasLiveSession;
      if (needsFastTick && interval.inSeconds > 1) {
        _startTicker();
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
        final habits = controller.active;
        final activeToday = habits.where((h) {
          final stats = controller.statsFor(h, _now);
          return stats.completedToday ||
              stats.quantityGoalReached ||
              (h.hasActiveSession);
        }).length;

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Hábitos',
                subtitle: habits.isEmpty
                    ? 'Rastreadores, sessões e metas diárias'
                    : '${pluralize(habits.length, 'hábito', 'hábitos')} · $activeToday ativos hoje',
              ),
              const SizedBox(height: Gap.x4),
              Expanded(
                child: habits.isEmpty
                    ? EmptyState(
                        icon: Icons.local_fire_department_rounded,
                        title: 'Comece um hábito',
                        message:
                            'Time trackers, cronômetros de sessão, metas em quantidade ou check-ins simples — escolha o que combina com você.',
                        actionLabel: 'Criar hábito',
                        onAction: () => showHabitEditorSheet(context),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.page,
                          0,
                          Gap.page,
                          130,
                        ),
                        itemCount: habits.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Gap.x3),
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          return StaggeredReveal(
                            index: index,
                            child: HabitCard(
                              habit: habit,
                              now: _now,
                              onTap: () => Navigator.of(context).push(
                                SoftSlideRoute(
                                  builder: (_) =>
                                      HabitDetailPage(habitId: habit.id),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
