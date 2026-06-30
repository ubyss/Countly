import 'package:flutter/material.dart';

import '../models/remaining_time.dart';
import '../theme/countly_colors.dart';
import '../theme/countly_motion.dart';
import '../utils/countdown_utils.dart';

Widget _animatedMetricValue(String value, TextStyle style) {
  return ClipRect(
    child: AnimatedSwitcher(
      duration: CountlyMotion.base,
      switchInCurve: CountlyMotion.standard,
      switchOutCurve: CountlyMotion.standard,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation);
        return ClipRect(
          child: SlideTransition(
            position: slide,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Text(
        value,
        key: ValueKey(value),
        style: style,
      ),
    ),
  );
}

class CountdownTimeOverlay extends StatelessWidget {
  const CountdownTimeOverlay({
    super.key,
    required this.targetDate,
    required this.currentTime,
    this.compact = false,
    this.onCard = false,
  });

  final String targetDate;
  final DateTime currentTime;
  final bool compact;
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    final colors = context.countlyColors;
    final remaining = targetDate.isEmpty
        ? const RemainingTime(months: 0, days: 0, hours: 0, minutes: 0, expired: false)
        : calculateRemainingTime(targetDate, currentTime);

    if (targetDate.isNotEmpty && remaining.expired) {
      return _CompletedBadge(
        date: formatBrazilianDateInput(targetDate),
        colors: colors,
        compact: compact,
        onCard: onCard,
      );
    }

    final metrics = buildCountdownDisplayUnits(remaining)
        .map((unit) => _Metric(unit.label, unit.value))
        .toList();

    if (onCard) {
      return _CardOverlay(metrics: metrics, colors: colors);
    }

    return _InlineOverlay(metrics: metrics, colors: colors, compact: compact);
  }
}

class _Metric {
  const _Metric(this.label, this.value);

  final String label;
  final int value;
}

class _CardOverlay extends StatelessWidget {
  const _CardOverlay({
    required this.metrics,
    required this.colors,
  });

  final List<_Metric> metrics;
  final CountlyColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      color: colors.accent.withValues(alpha: 0.94),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: _OverlayMetric(
                label: metrics[index].label,
                value: metrics[index].value,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverlayMetric extends StatelessWidget {
  const _OverlayMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _animatedMetricValue(
            padMetric(value),
            const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineOverlay extends StatelessWidget {
  const _InlineOverlay({
    required this.metrics,
    required this.colors,
    required this.compact,
  });

  final List<_Metric> metrics;
  final CountlyColors colors;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 6 : 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.card,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index > 0) SizedBox(width: compact ? 5 : 6),
            Expanded(
              child: _SolidMetric(
                label: metrics[index].label,
                value: metrics[index].value,
                colors: colors,
                compact: compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SolidMetric extends StatelessWidget {
  const _SolidMetric({
    required this.label,
    required this.value,
    required this.colors,
    required this.compact,
  });

  final String label;
  final int value;
  final CountlyColors colors;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 48 : 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.card,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _animatedMetricValue(
            padMetric(value),
            TextStyle(
              color: colors.accent,
              fontSize: compact ? 17 : 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.muted,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({
    required this.date,
    required this.colors,
    required this.compact,
    this.onCard = false,
  });

  final String date;
  final CountlyColors colors;
  final bool compact;
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: onCard ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        borderRadius: onCard ? null : BorderRadius.circular(12),
        color: onCard ? colors.accent.withValues(alpha: 0.94) : colors.successSurface,
        border: onCard ? null : Border.all(color: colors.successBorder),
      ),
      child: Row(
        mainAxisSize: onCard ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: onCard ? Colors.white : colors.successIcon,
            size: 18,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evento concluído em',
                style: TextStyle(
                  color: onCard ? Colors.white.withValues(alpha: 0.82) : colors.successLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: onCard ? Colors.white : colors.successText,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
