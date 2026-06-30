import 'package:flutter/material.dart';

class CountlyColors {
  const CountlyColors._({
    required this.page,
    required this.text,
    required this.muted,
    required this.softMuted,
    required this.border,
    required this.borderStrong,
    required this.panel,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.accentGlow,
    required this.accentGradientStart,
    required this.accentGradientEnd,
    required this.overlayScrim,
    required this.card,
    required this.input,
    required this.inputText,
    required this.successIcon,
    required this.successSurface,
    required this.successBorder,
    required this.successText,
    required this.successLabel,
    required this.glassHighlight,
    required this.glassBorder,
    required this.glassFill,
  });

  final Color page;
  final Color text;
  final Color muted;
  final Color softMuted;
  final Color border;
  final Color borderStrong;
  final Color panel;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;

  /// Tom usado em glows/sombras coloridas (botões, indicadores, splash).
  final Color accentGlow;

  /// Extremos do gradiente de destaque, usados de forma consistente em
  /// cabeçalhos, splash e elementos decorativos com gradiente roxo.
  final Color accentGradientStart;
  final Color accentGradientEnd;

  /// Camada de escurecimento usada sobre imagens/fundos (ex.: splash).
  final Color overlayScrim;

  final Color card;
  final Color input;
  final Color inputText;
  final Color successIcon;
  final Color successSurface;
  final Color successBorder;
  final Color successText;
  final Color successLabel;
  final Color glassHighlight;
  final Color glassBorder;
  final Color glassFill;

  static const light = CountlyColors._(
    page: Color(0xFFFCFCFF),
    text: Color(0xFF15182D),
    muted: Color(0xFF6D7487),
    softMuted: Color(0xFF8B91A3),
    border: Color(0xFFE6E8F0),
    borderStrong: Color(0xFFD7DBE6),
    panel: Color(0xFFFFFFFF),
    accent: Color(0xFF4949D8),
    accentDark: Color(0xFF3C3AC2),
    accentSoft: Color(0xFFF0EFFF),
    accentGlow: Color(0xFF6E6BF0),
    accentGradientStart: Color(0xFF5E5BE8),
    accentGradientEnd: Color(0xFF4949D8),
    overlayScrim: Color(0x661A1430),
    card: Color(0xFFFFFFFF),
    input: Color(0xFFFFFFFF),
    inputText: Color(0xFF202438),
    successIcon: Color(0xFF16A34A),
    successSurface: Color(0x3316A34A),
    successBorder: Color(0x7322C55E),
    successText: Color(0xFFF0FDF4),
    successLabel: Color(0xFFDCFCE7),
    glassHighlight: Color(0x66FFFFFF),
    glassBorder: Color(0x40FFFFFF),
    glassFill: Color(0xB3FFFFFF),
  );

  static const dark = CountlyColors._(
    page: Color(0xFF0E1016),
    text: Color(0xFFF4F6FB),
    muted: Color(0xFFA2A9BA),
    softMuted: Color(0xFF858DA0),
    border: Color(0xFF2B3040),
    borderStrong: Color(0xFF3A4052),
    panel: Color(0xFF171A23),
    accent: Color(0xFF8D8AFF),
    accentDark: Color(0xFFA5A2FF),
    accentSoft: Color(0x248D8AFF),
    accentGlow: Color(0xFFA09DFF),
    accentGradientStart: Color(0xFF8D8AFF),
    accentGradientEnd: Color(0xFF6E6BF0),
    overlayScrim: Color(0x8A0B0D14),
    card: Color(0xFF171A23),
    input: Color(0xFF11141C),
    inputText: Color(0xFFF0F2F8),
    successIcon: Color(0xFF4ADE80),
    successSurface: Color(0x3822C55E),
    successBorder: Color(0x6B4ADE80),
    successText: Color(0xFFECFDF5),
    successLabel: Color(0xFFBBF7D0),
    glassHighlight: Color(0x33FFFFFF),
    glassBorder: Color(0x24FFFFFF),
    glassFill: Color(0x94171A23),
  );
  static CountlyColors forDark(bool isDark) => isDark ? dark : light;
}

extension CountlyThemeExtension on BuildContext {
  CountlyColors get countlyColors {
    final brightness = Theme.of(this).brightness;
    return CountlyColors.forDark(brightness == Brightness.dark);
  }

  bool get isCountlyDark => Theme.of(this).brightness == Brightness.dark;
}
