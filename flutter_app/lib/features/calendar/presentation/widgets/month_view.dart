import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/calendar_events.dart';

const _weekdayLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

/// Grade de um mês com pontos coloridos de eventos, seleção animada
/// e toque longo para adicionar rapidamente.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.events,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onQuickAdd,
  });

  final DateTime month;
  final Map<DateTime, List<CalendarEvent>> events;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<DateTime> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cells = monthCalendarCells(month.year, month.month);
    final today = dateOnly(DateTime.now());
    const weekdayHeaderHeight = 28.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowCount = (cells.length / 7).ceil();
        final gridHeight =
            (constraints.maxHeight - weekdayHeaderHeight).clamp(0.0, double.infinity);
        final rowHeight = rowCount == 0 ? 0.0 : gridHeight / rowCount;

        return Column(
          children: [
            SizedBox(
              height: weekdayHeaderHeight,
              child: Row(
                children: [
                  for (final label in _weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Text(label, style: AppType.overline(palette)),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: rowHeight,
                ),
                itemCount: cells.length,
                itemBuilder: (context, index) {
                  final date = cells[index];
                  if (date == null) {
                    return const SizedBox.shrink();
                  }
                  return _DayCell(
                    date: date,
                    isToday: isSameDay(date, today),
                    isSelected:
                        selectedDay != null && isSameDay(date, selectedDay!),
                    isPast: date.isBefore(today),
                    events: events[dateOnly(date)] ?? const [],
                    onTap: () => onSelectDay(date),
                    onLongPress: () => onQuickAdd(date),
                    compact: rowHeight < 44,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.events,
    required this.onTap,
    required this.onLongPress,
    this.compact = false,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final List<CalendarEvent> events;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final brightness = Theme.of(context).brightness;

    final Color textColor;
    if (isSelected) {
      textColor = palette.onAccent;
    } else if (isToday) {
      textColor = palette.accent;
    } else if (isPast) {
      textColor = palette.textTertiary;
    } else {
      textColor = palette.textPrimary;
    }

    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      pressedScale: 0.85,
      semanticLabel: formatFullDate(date) +
          (events.isEmpty
              ? ''
              : ', ${pluralize(events.length, 'evento', 'eventos')}'),
      child: Center(
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.standard,
          width: compact ? 34 : 40,
          height: compact ? 38 : 46,
          decoration: BoxDecoration(
            color: isSelected
                ? palette.accent
                : isToday
                    ? palette.accentSoft
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Corner.xs),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: AppType.footnote(palette).copyWith(
                  color: textColor,
                  fontWeight:
                      isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final event in events.take(3))
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.onAccent
                              : CountlyAccents.adaptive(
                                  event.counter.accent,
                                  brightness,
                                ),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
