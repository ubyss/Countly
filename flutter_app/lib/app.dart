import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/countly_theme.dart';

class CountlyApp extends StatefulWidget {
  const CountlyApp({super.key});

  @override
  State<CountlyApp> createState() => _CountlyAppState();
}

class _CountlyAppState extends State<CountlyApp> {
  bool _isDark = false;

  void _changeTheme(bool value) {
    if (value == _isDark) {
      return;
    }
    setState(() => _isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countly',
      debugShowCheckedModeBanner: false,
      theme: CountlyTheme.build(isDark: false),
      darkTheme: CountlyTheme.build(isDark: true),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: Duration.zero,
      themeAnimationCurve: Curves.linear,
      locale: const Locale('pt', 'BR'),
      home: HomeScreen(
        isDark: _isDark,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}
