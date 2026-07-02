import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../../counters/domain/counter.dart';
import '../../../counters/domain/counter_snapshot.dart';
import '../../../counters/presentation/widgets/counter_visual.dart';
import '../../domain/calendar_events.dart';

/// Linha do tempo do dia selecionado: eventos do dia com trilho
/// colorido e atalho para criar um evento na data.
class DayPanel extends StatelessWidget {
  const DayPanel({
    super.key,
    required this.day,
    required this.events,
    required this.onOpenCounter,
    required this.onAddForDay,
  });

  final DateTime day;
  final List<CalendarEvent> events;
  final ValueChanged<Counter> onOpenCounter;
  final ValueChanged<DateTime> onAddForDay;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      key: ValueKey(day),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                formatWeekdayFullDate(day),
                style: AppType.headline(palette),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Gap.x2),
            Pressable(
              onTap: () => onAddForDay(day),
              pressedScale: 0.9,
              semanticLabel: 'Adicionar evento neste dia',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.x3,
                  vertical: Gap.x2,
                ),
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(Corner.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: palette.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Adicionar',
                      style: AppType.footnote(palette)
                          .copyWith(color: palette.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.x3),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: Gap.x6),
            decoration: BoxDecoration(
              color: palette.surfaceSunken,
              borderRadius: BorderRadius.circular(Corner.md),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  color: palette.textTertiary,
                  size: 28,
                ),
                const SizedBox(height: Gap.x2),
                Text('Dia livre', style: AppType.footnote(palette)),
              ],
            ),
          )
        else
          for (var i = 0; i < events.length; i++)
            StaggeredReveal(
              index: i,
              child: _DayEventTile(
                event: events[i],
                onTap: () => onOpenCounter(events[i].counter),
              ),
            ),
      ],
    );
  }
}

class _DayEventTile extends StatelessWidget {
  const _DayEventTile({required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final counter = event.counter;
    final accent = CountlyAccents.adaptive(
      counter.accent,
      Theme.of(context).brightness,
    );
    final snapshot = CounterSnapshot.of(counter, DateTime.now());

    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: Gap.x2),
        padding: const EdgeInsets.all(Gap.x3),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(Corner.md),
          border: Border.all(color: palette.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(Corner.pill),
              ),
            ),
            const SizedBox(width: Gap.x3),
            CounterIconBadge(counter: counter, size: 36, onSurface: true),
            const SizedBox(width: Gap.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.headline(palette),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (counter.recurrence.repeats) ...[
                        Icon(
                          Icons.repeat_rounded,
                          size: 13,
                          color: palette.textTertiary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        counter.recurrence.repeats
                            ? counter.recurrence.label
                            : snapshot.headline,
                        style: AppType.footnote(palette),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
