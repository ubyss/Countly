import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/habit_stats.dart';

/// Painel de cronômetro de sessão com controles play/pause/finalizar.
class SessionTimerPanel extends StatelessWidget {
  const SessionTimerPanel({
    super.key,
    required this.elapsedSeconds,
    required this.isRunning,
    required this.isPaused,
    required this.accent,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    this.compact = false,
  });

  final int elapsedSeconds;
  final bool isRunning;
  final bool isPaused;
  final Color accent;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = HabitStatsEngine.formatDuration(elapsedSeconds);
    final hasSession = isRunning || isPaused;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSession && isRunning
                ? Icons.timer_rounded
                : Icons.play_circle_outline_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppType.footnote(palette).copyWith(color: accent),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          label,
          style: AppType.display(palette).copyWith(
            fontSize: 48,
            color: accent,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: Gap.x2),
        Text(
          isPaused
              ? 'Pausado'
              : isRunning
                  ? 'Sessão em andamento'
                  : 'Pronto para começar',
          style: AppType.footnote(palette),
        ),
        const SizedBox(height: Gap.x6),
        if (!hasSession)
          _PrimaryButton(
            label: 'Iniciar sessão',
            icon: Icons.play_arrow_rounded,
            color: accent,
            onTap: () {
              HapticFeedback.mediumImpact();
              onStart();
            },
          )
        else
          Row(
            children: [
              Expanded(
                child: _PrimaryButton(
                  label: isPaused ? 'Continuar' : 'Pausar',
                  icon:
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: accent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (isPaused) {
                      onResume();
                    } else {
                      onPause();
                    }
                  },
                ),
              ),
              const SizedBox(width: Gap.x3),
              Expanded(
                child: _PrimaryButton(
                  label: 'Finalizar',
                  icon: Icons.stop_rounded,
                  color: palette.success,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    onFinish();
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Corner.sm),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: Gap.x2),
            Text(
              label,
              style: AppType.headline(palette).copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
