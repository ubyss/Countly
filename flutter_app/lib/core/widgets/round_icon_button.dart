import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable.dart';

/// Botão de ícone circular sobre superfície, com área de toque de 44px.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
    this.background,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final button = Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      semanticLabel: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? palette.surfaceSunken,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: size * 0.45,
          color: color ?? palette.textSecondary,
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}
