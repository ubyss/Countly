import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_tokens.dart';

/// Indicadores visuais de progresso diário (dots).
class QuantityDots extends StatelessWidget {
  const QuantityDots({
    super.key,
    required this.current,
    required this.goal,
    required this.accent,
    required this.onTap,
    this.onLongPress,
  });

  final int current;
  final int goal;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final safeGoal = goal.clamp(1, 24);
    final filled = current.clamp(0, safeGoal);
    final complete = filled >= safeGoal;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress!();
            }
          : null,
      child: Wrap(
        spacing: Gap.x2,
        runSpacing: Gap.x2,
        alignment: WrapAlignment.center,
        children: List.generate(safeGoal, (index) {
          final isFilled = index < filled;
          return AnimatedContainer(
            duration: Motion.base,
            curve: Curves.easeOutCubic,
            width: complete && isFilled ? 14 : 12,
            height: complete && isFilled ? 14 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? (complete ? palette.success : accent)
                  : palette.surfaceSunken,
              border: Border.all(
                color: isFilled ? Colors.transparent : palette.outline,
              ),
              boxShadow: isFilled && complete
                  ? [
                      BoxShadow(
                        color: palette.success.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
