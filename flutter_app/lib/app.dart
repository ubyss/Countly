import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/countly_preferences.dart';
import 'theme/countly_colors.dart';
import 'theme/countly_motion.dart';
import 'theme/countly_theme.dart';

class CountlyApp extends StatefulWidget {
  const CountlyApp({super.key});

  @override
  State<CountlyApp> createState() => _CountlyAppState();
}

class _CountlyAppState extends State<CountlyApp> {
  final _preferences = CountlyPreferences();

  bool _isDark = false;
  bool _introResolved = false;
  bool _showSplash = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final hasSeenIntro = await _preferences.hasSeenIntro();
    final isDark = await _preferences.loadDarkMode();
    if (!mounted) {
      return;
    }
    setState(() {
      _showSplash = !hasSeenIntro;
      _isDark = isDark;
      _introResolved = true;
    });
  }

  Future<void> _finishIntro() async {
    await _preferences.markIntroSeen();
    if (!mounted) {
      return;
    }
    setState(() => _showSplash = false);
  }

  void _changeTheme(bool value) {
    if (value == _isDark) {
      return;
    }
    setState(() => _isDark = value);
    _preferences.saveDarkMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countly',
      debugShowCheckedModeBanner: false,
      theme: CountlyTheme.build(isDark: false),
      darkTheme: CountlyTheme.build(isDark: true),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: CountlyMotion.base,
      themeAnimationCurve: CountlyMotion.emphasized,
      locale: const Locale('pt', 'BR'),
      home: !_introResolved
          ? _BootScreen(isDark: _isDark)
          : AnimatedSwitcher(
              duration: CountlyMotion.slow,
              switchInCurve: CountlyMotion.standard,
              switchOutCurve: CountlyMotion.standard,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: _showSplash
                  ? SplashScreen(
                      key: const ValueKey('splash'),
                      isDark: _isDark,
                      onFinished: _finishIntro,
                    )
                  : HomeScreen(
                      key: const ValueKey('home'),
                      isDark: _isDark,
                      onThemeChanged: _changeTheme,
                    ),
            ),
    );
  }
}

/// Tela neutra exibida pelo instante necessário para checar se o app
/// já mostrou a apresentação de primeiro acesso.
class _BootScreen extends StatelessWidget {
  const _BootScreen({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: CountlyColors.forDark(isDark).page);
  }
}
