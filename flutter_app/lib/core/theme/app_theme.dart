import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

class CountlyTheme {
  const CountlyTheme._();

  static ThemeData build(Brightness brightness) {
    final palette = CountlyPalette.of(brightness);
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: base.colorScheme.copyWith(
        primary: palette.accent,
        onPrimary: palette.onAccent,
        secondary: palette.accent,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        outline: palette.outline,
        error: palette.danger,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: palette.textPrimary,
            displayColor: palette.textPrimary,
            fontFamily: AppType.family,
            package: AppType.package,
          )
          .copyWith(
            displayLarge: AppType.display(palette),
            headlineLarge: AppType.largeTitle(palette),
            titleLarge: AppType.title(palette),
            titleMedium: AppType.headline(palette),
            bodyMedium: AppType.body(palette),
            bodySmall: AppType.footnote(palette),
            labelSmall: AppType.caption(palette),
          ),
      dividerColor: palette.outline,
      dividerTheme: DividerThemeData(
        color: palette.outline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceElevated,
        modalBackgroundColor: palette.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.xl)),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: palette.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corner.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.textPrimary,
        contentTextStyle:
            AppType.footnote(palette).copyWith(color: palette.background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corner.sm),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.accent,
        selectionColor: palette.accent.withValues(alpha: 0.25),
        selectionHandleColor: palette.accent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
