import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

/// Chip de tag/filtro com estado selecionado animado.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.x4,
          vertical: Gap.x2,
        ),
        decoration: BoxDecoration(
          color: selected ? palette.accent : palette.surfaceSunken,
          borderRadius: BorderRadius.circular(Corner.pill),
          border: Border.all(
            color: selected ? palette.accent : palette.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: Gap.x1),
            ],
            Text(
              label,
              style: AppType.footnote(palette).copyWith(
                color: selected ? palette.onAccent : palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
