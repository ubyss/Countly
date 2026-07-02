import 'package:flutter/material.dart';
import 'package:fontresoft/fontresoft.dart';

import 'app_colors.dart';

/// Hierarquia tipográfica do Countly, baseada em SF Pro.
///
/// Os estilos recebem a cor do texto via [CountlyPalette] no momento
/// do uso para respeitar o tema atual.
class AppType {
  const AppType._();

  static String get family => FontResoft.sFProText;
  static String? get package => FontResoft.package;

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      package: package,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Números gigantes (contadores em destaque).
  static TextStyle display(CountlyPalette p) => _base(
        size: 56,
        weight: FontWeight.w800,
        height: 1.02,
        letterSpacing: -1.6,
      ).copyWith(color: p.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle largeTitle(CountlyPalette p) => _base(
        size: 32,
        weight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -0.8,
      ).copyWith(color: p.textPrimary);

  static TextStyle title(CountlyPalette p) => _base(
        size: 22,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.4,
      ).copyWith(color: p.textPrimary);

  static TextStyle headline(CountlyPalette p) => _base(
        size: 17,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
      ).copyWith(color: p.textPrimary);

  static TextStyle body(CountlyPalette p) => _base(
        size: 15,
        weight: FontWeight.w400,
        height: 1.4,
      ).copyWith(color: p.textPrimary);

  static TextStyle bodySecondary(CountlyPalette p) =>
      body(p).copyWith(color: p.textSecondary);

  static TextStyle footnote(CountlyPalette p) => _base(
        size: 13,
        weight: FontWeight.w500,
        height: 1.3,
      ).copyWith(color: p.textSecondary);

  static TextStyle caption(CountlyPalette p) => _base(
        size: 11,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.5,
      ).copyWith(color: p.textTertiary);

  /// Rótulos em caixa alta (unidades de tempo, seções).
  static TextStyle overline(CountlyPalette p) => _base(
        size: 11,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 1.1,
      ).copyWith(color: p.textTertiary);

  /// Números médios com dígitos tabulares (métricas em cards).
  static TextStyle metric(CountlyPalette p) => _base(
        size: 28,
        weight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.6,
      ).copyWith(color: p.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]);
}
