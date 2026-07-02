import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/staggered_list.dart';
import '../../domain/counter.dart';
import '../../domain/counter_snapshot.dart';
import 'counter_visual.dart';

/// Entrada da linha do tempo: contagem + snapshot pré-calculado.
class TimelineEntry {
  const TimelineEntry(this.counter, this.snapshot);

  final Counter counter;
  final CounterSnapshot snapshot;
}

/// Grupo de entradas sob um mesmo rótulo temporal.
class TimelineGroup {
  const TimelineGroup(this.label, this.entries);

  final String label;
  final List<TimelineEntry> entries;
}

/// Agrupa contagens em blocos temporais para a visão de linha do tempo.
List<TimelineGroup> buildTimelineGroups(
  List<Counter> counters,
  DateTime now,
) {
  final today = <TimelineEntry>[];
  final week = <TimelineEntry>[];
  final month = <TimelineEntry>[];
  final later = <TimelineEntry>[];
  final counting = <TimelineEntry>[];

  for (final counter in counters) {
    final snapshot = CounterSnapshot.of(counter, now);
    final entry = TimelineEntry(counter, snapshot);
    if (snapshot.isToday) {
      today.add(entry);
    } else if (snapshot.isCountdown) {
      if (snapshot.totalDays <= 7) {
        week.add(entry);
      } else if (snapshot.totalDays <= 31) {
        month.add(entry);
      } else {
        later.add(entry);
      }
    } else {
      counting.add(entry);
    }
  }

  int byProximity(TimelineEntry a, TimelineEntry b) =>
      a.snapshot.totalDays.compareTo(b.snapshot.totalDays);

  week.sort(byProximity);
  month.sort(byProximity);
  later.sort(byProximity);
  counting.sort((a, b) => b.snapshot.totalDays.compareTo(a.snapshot.totalDays));

  return [
    if (today.isNotEmpty) TimelineGroup('Hoje', today),
    if (week.isNotEmpty) TimelineGroup('Próximos 7 dias', week),
    if (month.isNotEmpty) TimelineGroup('Este mês', month),
    if (later.isNotEmpty) TimelineGroup('Mais adiante', later),
    if (counting.isNotEmpty) TimelineGroup('Contando desde', counting),
  ];
}

/// Item da linha do tempo com trilho vertical, nó colorido e conteúdo.
class TimelineTile extends StatelessWidget {
  const TimelineTile({
    super.key,
    required this.entry,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final TimelineEntry entry;
  final int index;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final counter = entry.counter;
    final snapshot = entry.snapshot;
    final accent = CountlyAccents.adaptive(
      counter.accent,
      Theme.of(context).brightness,
    );

    return StaggeredReveal(
      index: index,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 34,
              child: Column(
                children: [
                  Expanded(
                    child: _TrackSegment(visible: !isFirst),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.background, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: _TrackSegment(visible: !isLast),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.x2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Gap.x3),
                child: Pressable(
                  onTap: onTap,
                  pressedScale: 0.98,
                  child: Container(
                    padding: const EdgeInsets.all(Gap.x4),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(Corner.md),
                      border: Border.all(color: palette.outline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.eventDate != null
                                    ? formatWeekdayFullDate(
                                        snapshot.eventDate!)
                                    : 'Desde ${formatDayMonth(counter.createdAt)}',
                                style: AppType.caption(palette)
                                    .copyWith(color: accent),
                              ),
                              const SizedBox(height: Gap.x1),
                              Text(
                                counter.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.headline(palette),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                snapshot.headline,
                                style: AppType.footnote(palette),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Gap.x3),
                        CounterIconBadge(
                          counter: counter,
                          size: 38,
                          onSurface: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackSegment extends StatelessWidget {
  const _TrackSegment({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return Center(
      child: Container(
        width: 2,
        color: context.palette.outlineStrong,
      ),
    );
  }
}
