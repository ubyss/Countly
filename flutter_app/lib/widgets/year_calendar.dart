import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/countdown.dart';
import '../theme/countly_colors.dart';
import '../utils/countdown_utils.dart';
import 'countdown_image.dart';
import 'countdown_time_overlay.dart';

class YearCalendarView extends StatelessWidget {
  const YearCalendarView({
    super.key,
    required this.countdowns,
    required this.currentTime,
  });

  final List<Countdown> countdowns;
  final ValueListenable<DateTime> currentTime;

  Map<String, List<Countdown>> _countdownsByDate() {
    final countdownsByDate = <String, List<Countdown>>{};

    for (final countdown in countdowns) {
      final normalized = normalizeTargetDate(countdown.targetDate);
      if (normalized.isEmpty) {
        continue;
      }
      countdownsByDate.putIfAbsent(normalized, () => []).add(countdown);
    }

    return countdownsByDate;
  }

  bool _monthHasCountdowns(
    int year,
    int month,
    Map<String, List<Countdown>> countdownsByDate,
  ) {
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-';
    return countdownsByDate.keys.any((key) => key.startsWith(prefix));
  }

  int _monthCrossAxisCount(double width) {
    if (width >= 760) {
      return 6;
    }
    if (width >= 520) {
      return 4;
    }
    return 3;
  }

  void _openMonthSheet(
    BuildContext context, {
    required int year,
    required int month,
    required Map<String, List<Countdown>> countdownsByDate,
    required CountlyColors colors,
  }) {
    final monthDate = DateTime(year, month);
    final days = getMonthCalendarDays(year, month);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(
                  height: 360,
                  child: _FullMonthCard(
                    monthDate: monthDate,
                    days: days,
                    countdownsByDate: countdownsByDate,
                    colors: colors,
                    currentTime: currentTime,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.countlyColors;

    return ValueListenableBuilder<DateTime>(
      valueListenable: currentTime,
      builder: (context, time, _) {
        final year = time.year;
        final currentMonth = time.month;
        final countdownsByDate = _countdownsByDate();
        final months = List.generate(12, (index) => index + 1);

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = _monthCrossAxisCount(constraints.maxWidth);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: months.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final month = months[index];
                final monthDate = DateTime(year, month);
                final hasCountdowns = _monthHasCountdowns(year, month, countdownsByDate);
                final isCurrentMonth = month == currentMonth;
                final isPastMonth = month < currentMonth;

                return _MonthThumbnail(
                  monthDate: monthDate,
                  hasCountdowns: hasCountdowns,
                  isCurrentMonth: isCurrentMonth,
                  isPastMonth: isPastMonth,
                  colors: colors,
                  onTap: hasCountdowns
                      ? () => _openMonthSheet(
                            context,
                            year: year,
                            month: month,
                            countdownsByDate: countdownsByDate,
                            colors: colors,
                          )
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MonthThumbnail extends StatelessWidget {
  const _MonthThumbnail({
    required this.monthDate,
    required this.hasCountdowns,
    required this.isCurrentMonth,
    required this.isPastMonth,
    required this.colors,
    required this.onTap,
  });

  final DateTime monthDate;
  final bool hasCountdowns;
  final bool isCurrentMonth;
  final bool isPastMonth;
  final CountlyColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMM', 'pt_BR').format(monthDate);
    final labelColor = isPastMonth ? colors.softMuted : colors.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentMonth
                  ? colors.accent.withValues(alpha: 0.55)
                  : colors.border.withValues(alpha: isPastMonth ? 0.65 : 0.9),
              width: isCurrentMonth ? 1.4 : 1,
            ),
            color: isPastMonth
                ? colors.card.withValues(alpha: 0.55)
                : colors.card,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: isCurrentMonth ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              if (hasCountdowns)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colors.accent, colors.accentDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullMonthCard extends StatelessWidget {
  const _FullMonthCard({
    required this.monthDate,
    required this.days,
    required this.countdownsByDate,
    required this.colors,
    required this.currentTime,
  });

  final DateTime monthDate;
  final List<DateTime?> days;
  final Map<String, List<Countdown>> countdownsByDate;
  final CountlyColors colors;
  final ValueListenable<DateTime> currentTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          formatCalendarMonthName(monthDate),
          style: TextStyle(
            color: colors.text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
              .map(
                (weekday) => Expanded(
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.softMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) {
                return const SizedBox.shrink();
              }

              final iso = toDateInputValue(date);
              final dayCountdowns = countdownsByDate[iso] ?? [];
              final hasCountdowns = dayCountdowns.isNotEmpty;

              return _YearDayCell(
                day: date.day,
                hasCountdowns: hasCountdowns,
                countdowns: dayCountdowns,
                colors: colors,
                currentTime: currentTime,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _YearDayCell extends StatelessWidget {
  const _YearDayCell({
    required this.day,
    required this.hasCountdowns,
    required this.countdowns,
    required this.colors,
    required this.currentTime,
  });

  final int day;
  final bool hasCountdowns;
  final List<Countdown> countdowns;
  final CountlyColors colors;
  final ValueListenable<DateTime> currentTime;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasCountdowns ? colors.accent.withValues(alpha: 0.35) : colors.border.withValues(alpha: 0.45),
        ),
        color: hasCountdowns ? colors.accentSoft : Colors.transparent,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: hasCountdowns ? colors.accent : colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasCountdowns)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colors.accent, colors.accentDark],
                  ),
                  border: Border.all(color: colors.card, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );

    if (!hasCountdowns) {
      return child;
    }

    return GestureDetector(
      onTap: () => _showDayDetails(context),
      child: child,
    );
  }

  void _showDayDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final countdown in countdowns) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                      color: Color.alphaBlend(colors.accentSoft, colors.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CountdownImagePreview(
                          imageBase64: countdown.imageBase64,
                          colors: colors,
                          height: 140,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ValueListenableBuilder<DateTime>(
                                valueListenable: currentTime,
                                builder: (context, time, _) {
                                  return CountdownTimeOverlay(
                                    targetDate: countdown.targetDate,
                                    currentTime: time,
                                    compact: true,
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                countdown.name,
                                style: TextStyle(
                                  color: colors.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: colors.muted),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatDateLabel(countdown.targetDate),
                                    style: TextStyle(color: colors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
