import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../counters/domain/counter.dart';
import '../../../counters/presentation/widgets/counter_visual.dart';
import '../../domain/calendar_events.dart';

/// Agenda: próximos 12 meses de eventos em lista contínua,
/// agrupados por mês e dia.
class AgendaView extends StatelessWidget {
  const AgendaView({
    super.key,
    required this.counters,
    required this.onOpenCounter,
  });

  final List<Counter> counters;
  final ValueChanged<Counter> onOpenCounter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final now = dateOnly(DateTime.now());
    final events = eventsForRange(
      counters,
      now,
      DateTime(now.year + 1, now.month, now.day),
    );

    final sortedDays = events.keys.toList()..sort();
    if (sortedDays.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_month_rounded,
        title: 'Agenda vazia',
        message:
            'Crie contagens com data para vê-las organizadas aqui na agenda.',
      );
    }

    final children = <Widget>[];
    DateTime? currentMonth;
    var index = 0;

    for (final day in sortedDays) {
      if (currentMonth == null || !isSameMonth(day, currentMonth)) {
        currentMonth = day;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(0, Gap.x5, 0, Gap.x3),
            child: Text(
              formatMonthYear(day).toUpperCase(),
              style: AppType.overline(palette),
            ),
          ),
        );
      }
      children.add(
        StaggeredReveal(
          index: index,
          child: _AgendaDayRow(
            day: day,
            isToday: isSameDay(day, now),
            events: events[day]!,
            onOpenCounter: onOpenCounter,
          ),
        ),
      );
      index++;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, 130),
      children: children,
    );
  }
}

class _AgendaDayRow extends StatelessWidget {
  const _AgendaDayRow({
    required this.day,
    required this.isToday,
    required this.events,
    required this.onOpenCounter,
  });

  final DateTime day;
  final bool isToday;
  final List<CalendarEvent> events;
  final ValueChanged<Counter> onOpenCounter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(
                  formatShortWeekday(day).toUpperCase(),
                  style: AppType.caption(palette).copyWith(
                    color: isToday ? palette.accent : palette.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isToday ? palette.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: AppType.headline(palette).copyWith(
                        color: isToday
                            ? palette.onAccent
                            : palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.x3),
          Expanded(
            child: Column(
              children: [
                for (final event in events)
                  Pressable(
                    onTap: () => onOpenCounter(event.counter),
                    pressedScale: 0.98,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: Gap.x2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gap.x3,
                        vertical: Gap.x3,
                      ),
                      decoration: BoxDecoration(
                        color: CountlyAccents.adaptive(
                          event.counter.accent,
                          brightness,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Corner.sm),
                      ),
                      child: Row(
                        children: [
                          CounterIconBadge(
                            counter: event.counter,
                            size: 30,
                          ),
                          const SizedBox(width: Gap.x3),
                          Expanded(
                            child: Text(
                              event.counter.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.headline(palette).copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (event.counter.recurrence.repeats)
                            Icon(
                              Icons.repeat_rounded,
                              size: 15,
                              color: palette.textTertiary,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
