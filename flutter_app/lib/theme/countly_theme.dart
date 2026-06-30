import 'package:flutter/material.dart';
import 'package:fontresoft/fontresoft.dart';

import 'countly_colors.dart';
import 'countly_tokens.dart';

class CountlyTheme {
  static ThemeData build({required bool isDark}) {
    final colors = isDark ? CountlyColors.dark : CountlyColors.light;
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.page,
      colorScheme: base.colorScheme.copyWith(
        primary: colors.accent,
        surface: colors.card,
        onSurface: colors.text,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: colors.text,
        displayColor: colors.text,
        fontFamily: FontResoft.sFProText,
        package: FontResoft.package,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: FontResoft.sFProText,
        package: FontResoft.package,
      ),
      dividerColor: colors.border,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: base.cardTheme.copyWith(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CountlyRadius.md),
          side: BorderSide(color: colors.border),
        ),
      ),
      tooltipTheme: base.tooltipTheme.copyWith(
        decoration: BoxDecoration(
          color: colors.text,
          borderRadius: BorderRadius.circular(CountlyRadius.sm),
        ),
        textStyle: TextStyle(color: colors.page, fontSize: 12),
      ),
    );
  }
}
