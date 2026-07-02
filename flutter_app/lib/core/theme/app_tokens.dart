import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala de espaçamento (múltiplos de 4).
class Gap {
  const Gap._();

  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;

  /// Margem horizontal padrão das páginas.
  static const double page = 20;
}

/// Escala de raios de borda.
class Corner {
  const Corner._();

  static const double xs = 10;
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 30;
  static const double pill = 999;
}

/// Sombras suaves em camadas, com leve tinta do accent para dar
/// profundidade sem parecer Material genérico.
class Elevations {
  const Elevations._();

  static List<BoxShadow> soft(CountlyPalette palette) => [
        BoxShadow(
          color: palette.shadowTint.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: palette.shadowTint.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> raised(CountlyPalette palette) => [
        BoxShadow(
          color: palette.shadowTint.withValues(alpha: 0.14),
          blurRadius: 34,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: palette.shadowTint.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> glow(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.34),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ];
}
