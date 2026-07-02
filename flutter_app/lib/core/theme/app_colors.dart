import 'package:flutter/material.dart';

/// Paleta semântica do Countly.
///
/// Todas as superfícies, textos e realces derivam destes tokens para
/// garantir consistência entre temas claro e escuro.
class CountlyPalette {
  const CountlyPalette._({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.outline,
    required this.outlineStrong,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.accentGradientStart,
    required this.accentGradientEnd,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.warningSoft,
    required this.scrim,
    required this.glassFill,
    required this.glassBorder,
    required this.shadowTint,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSunken;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color outline;
  final Color outlineStrong;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color accentGradientStart;
  final Color accentGradientEnd;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color warning;
  final Color warningSoft;
  final Color scrim;
  final Color glassFill;
  final Color glassBorder;
  final Color shadowTint;

  static const light = CountlyPalette._(
    background: Color(0xFFF7F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEFEFF6),
    textPrimary: Color(0xFF17182B),
    textSecondary: Color(0xFF62677E),
    textTertiary: Color(0xFF9A9FB2),
    outline: Color(0xFFE7E8F0),
    outlineStrong: Color(0xFFD5D7E4),
    accent: Color(0xFF5551E8),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFEEEDFF),
    accentGradientStart: Color(0xFF6D66F5),
    accentGradientEnd: Color(0xFF4D48DE),
    success: Color(0xFF16A34A),
    successSoft: Color(0xFFE4F8EC),
    danger: Color(0xFFE0455A),
    dangerSoft: Color(0xFFFDEBEE),
    warning: Color(0xFFD97E0C),
    warningSoft: Color(0xFFFCF1E0),
    scrim: Color(0x8A15162B),
    glassFill: Color(0xD9FFFFFF),
    glassBorder: Color(0x66FFFFFF),
    shadowTint: Color(0xFF3F3E77),
  );

  static const dark = CountlyPalette._(
    background: Color(0xFF0C0D14),
    surface: Color(0xFF15161F),
    surfaceElevated: Color(0xFF1B1D29),
    surfaceSunken: Color(0xFF10111A),
    textPrimary: Color(0xFFF3F4FA),
    textSecondary: Color(0xFFA3A8BC),
    textTertiary: Color(0xFF6E7387),
    outline: Color(0xFF262838),
    outlineStrong: Color(0xFF363950),
    accent: Color(0xFF8A86FF),
    onAccent: Color(0xFF13123A),
    accentSoft: Color(0x298A86FF),
    accentGradientStart: Color(0xFF8E8AFF),
    accentGradientEnd: Color(0xFF6660F2),
    success: Color(0xFF4ADE80),
    successSoft: Color(0x264ADE80),
    danger: Color(0xFFF07084),
    dangerSoft: Color(0x2EF07084),
    warning: Color(0xFFF3A94A),
    warningSoft: Color(0x2BF3A94A),
    scrim: Color(0xB0060710),
    glassFill: Color(0xE015161F),
    glassBorder: Color(0x1FFFFFFF),
    shadowTint: Color(0xFF000000),
  );

  static CountlyPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Cores de destaque que o usuário pode escolher para contagens e hábitos.
class CountlyAccents {
  const CountlyAccents._();

  static const violet = Color(0xFF5551E8);
  static const blue = Color(0xFF2F80ED);
  static const cyan = Color(0xFF0EA5B7);
  static const green = Color(0xFF19A45B);
  static const lime = Color(0xFF7CA321);
  static const amber = Color(0xFFDF8E0B);
  static const orange = Color(0xFFEA6A34);
  static const red = Color(0xFFE0455A);
  static const pink = Color(0xFFDF3D8E);
  static const slate = Color(0xFF5B6474);

  static const all = <Color>[
    violet,
    blue,
    cyan,
    green,
    lime,
    amber,
    orange,
    red,
    pink,
    slate,
  ];

  /// Ajusta um accent escolhido pelo usuário para manter contraste
  /// adequado sobre superfícies escuras.
  static Color adaptive(Color base, Brightness brightness) {
    if (brightness == Brightness.light) {
      return base;
    }
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + 0.16).clamp(0.0, 0.82))
        .withSaturation((hsl.saturation * 0.95).clamp(0.0, 1.0))
        .toColor();
  }
}

extension CountlyPaletteContext on BuildContext {
  CountlyPalette get palette => CountlyPalette.of(Theme.of(this).brightness);

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
