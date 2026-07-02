import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/base64_image.dart';
import '../../domain/counter.dart';

/// Fundo visual de uma contagem: imagem do usuário com scrim ou
/// gradiente derivado da cor de destaque.
class CounterBackdrop extends StatelessWidget {
  const CounterBackdrop({super.key, required this.counter});

  final Counter counter;

  @override
  Widget build(BuildContext context) {
    if (counter.hasImage) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Base64Image(
            base64: counter.imageBase64!,
            alignment: counter.imageAlignment,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.62),
                ],
                stops: const [0.35, 1],
              ),
            ),
          ),
        ],
      );
    }

    final brightness = Theme.of(context).brightness;
    final accent = CountlyAccents.adaptive(counter.accent, brightness);
    final hsl = HSLColor.fromColor(accent);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor(),
            hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor(),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, right: 6),
          child: Icon(
            AppIcons.resolve(counter.iconName),
            size: 110,
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }
}

/// Medalhão circular com o ícone da contagem sobre a cor de destaque.
class CounterIconBadge extends StatelessWidget {
  const CounterIconBadge({
    super.key,
    required this.counter,
    this.size = 44,
    this.onSurface = false,
  });

  final Counter counter;
  final double size;

  /// Quando true usa fundo suave (para superfícies claras);
  /// caso contrário fundo sólido na cor de destaque.
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = CountlyAccents.adaptive(counter.accent, brightness);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onSurface ? accent.withValues(alpha: 0.14) : accent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        AppIcons.resolve(counter.iconName),
        size: size * 0.5,
        color: onSurface ? accent : Colors.white,
      ),
    );
  }
}
