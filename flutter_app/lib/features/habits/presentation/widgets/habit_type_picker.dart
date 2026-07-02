import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/habit_kind.dart';

/// Seletor visual do tipo de hábito na criação.
class HabitTypePicker extends StatelessWidget {
  const HabitTypePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HabitKind? selected;
  final ValueChanged<HabitKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: HabitKind.values.map((kind) {
        final isSelected = selected == kind;
        return Padding(
          padding: const EdgeInsets.only(bottom: Gap.x3),
          child: Pressable(
            onTap: () => onSelected(kind),
            pressedScale: 0.98,
            child: AnimatedContainer(
              duration: Motion.fast,
              padding: const EdgeInsets.all(Gap.x4),
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.accent.withValues(alpha: 0.1)
                    : palette.surface,
                borderRadius: BorderRadius.circular(Corner.lg),
                border: Border.all(
                  color: isSelected ? palette.accent : palette.outline,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.accent.withValues(alpha: 0.16)
                          : palette.surfaceSunken,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      kind.icon,
                      color: isSelected ? palette.accent : palette.textSecondary,
                    ),
                  ),
                  const SizedBox(width: Gap.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kind.label, style: AppType.headline(palette)),
                        const SizedBox(height: 2),
                        Text(
                          kind.description,
                          style: AppType.caption(palette),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: palette.accent),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
