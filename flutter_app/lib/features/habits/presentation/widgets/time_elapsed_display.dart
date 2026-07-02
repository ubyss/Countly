import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/habit_stats.dart';

/// Exibição grande de tempo decorrido (time tracker).
class TimeElapsedDisplay extends StatelessWidget {
  const TimeElapsedDisplay({
    super.key,
    required this.elapsed,
    required this.accent,
    this.compact = false,
  });

  final Duration elapsed;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final parts = HabitStatsEngine.formatElapsed(elapsed);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            parts.primaryLabel,
            style: AppType.metric(palette).copyWith(color: accent, fontSize: 22),
          ),
          if (parts.secondaryLabels.isNotEmpty)
            Text(
              parts.secondaryLabels.first,
              style: AppType.caption(palette),
            ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          parts.primaryLabel,
          style: AppType.display(palette).copyWith(
            fontSize: 42,
            color: accent,
            height: 1.1,
          ),
        ),
        if (parts.secondaryLabels.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            parts.secondaryLabels.join(' · '),
            style: AppType.footnote(palette),
          ),
        ],
        const SizedBox(height: 8),
        _BreakdownRow(parts: parts, accent: accent),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.parts, required this.accent});

  final ElapsedParts parts;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = [
      ('Anos', parts.years),
      ('Meses', parts.months),
      ('Sem.', parts.weeks),
      ('Dias', parts.days),
      if (parts.totalDays == 0) ('Horas', parts.hours),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '${items[i].$2}',
                style: AppType.headline(palette).copyWith(color: accent),
              ),
              Text(items[i].$1, style: AppType.caption(palette)),
            ],
          ),
        ],
      ],
    );
  }
}
