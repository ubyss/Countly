import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

/// Estado vazio ilustrado com ícone flutuante animado e ação primária.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.x10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _float,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  0,
                  -6 * Curves.easeInOut.transform(_float.value),
                ),
                child: child,
              ),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.accentGradientStart.withValues(alpha: 0.16),
                      palette.accentGradientEnd.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 42, color: palette.accent),
              ),
            ),
            const SizedBox(height: Gap.x6),
            Text(
              widget.title,
              style: AppType.title(palette),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.x2),
            Text(
              widget.message,
              style: AppType.bodySecondary(palette),
              textAlign: TextAlign.center,
            ),
            if (widget.actionLabel != null) ...[
              const SizedBox(height: Gap.x6),
              Pressable(
                onTap: widget.onAction,
                child: AnimatedContainer(
                  duration: Motion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.x6,
                    vertical: Gap.x3,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        palette.accentGradientStart,
                        palette.accentGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(Corner.pill),
                    boxShadow: Elevations.glow(palette.accent),
                  ),
                  child: Text(
                    widget.actionLabel!,
                    style: AppType.headline(palette)
                        .copyWith(color: palette.onAccent),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
