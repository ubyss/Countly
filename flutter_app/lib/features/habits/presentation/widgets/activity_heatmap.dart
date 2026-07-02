import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';

/// Heatmap mensal de atividade do hábito.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.activityDays,
    required this.month,
    required this.accent,
  });

  final Set<DateTime> activityDays;
  final DateTime month;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cells = monthCalendarCells(month.year, month.month);
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatMonthYear(month),
          style: AppType.footnote(palette),
        ),
        const SizedBox(height: Gap.x3),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: cells.length,
          itemBuilder: (context, index) {
            final date = cells[index];
            if (date == null) {
              return const SizedBox.shrink();
            }
            final active = activityDays.any((d) => isSameDay(d, date));
            final isToday = isSameDay(date, today);

            return Container(
              decoration: BoxDecoration(
                color: active
                    ? accent.withValues(alpha: 0.85)
                    : palette.surfaceSunken,
                borderRadius: BorderRadius.circular(4),
                border: isToday
                    ? Border.all(color: palette.accent, width: 1.5)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}
