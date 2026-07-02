import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_motion.dart';
import '../core/theme/app_theme.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/shell/presentation/home_shell.dart';
import 'app_scope.dart';

/// Raiz do app: injeta dependências, resolve tema e decide entre
/// onboarding e a experiência principal.
class CountlyApp extends StatefulWidget {
  const CountlyApp({super.key});

  @override
  State<CountlyApp> createState() => _CountlyAppState();
}

class _CountlyAppState extends State<CountlyApp> {
  final AppDependencies _dependencies = AppDependencies();

  @override
  void initState() {
    super.initState();
    _dependencies.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: _dependencies,
      child: ListenableBuilder(
        listenable: _dependencies.settings,
        builder: (context, _) {
          final settings = _dependencies.settings;

          return MaterialApp(
            title: 'Countly',
            debugShowCheckedModeBanner: false,
            theme: CountlyTheme.build(Brightness.light),
            darkTheme: CountlyTheme.build(Brightness.dark),
            themeMode: settings.themeMode,
            themeAnimationDuration: Motion.base,
            themeAnimationCurve: Motion.emphasized,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: !settings.loaded
                ? const _BootScreen()
                : AnimatedSwitcher(
                    duration: Motion.slow,
                    switchInCurve: Motion.standard,
                    switchOutCurve: Motion.standard,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.98, end: 1)
                            .animate(animation),
                        child: child,
                      ),
                    ),
                    child: settings.introSeen
                        ? const HomeShell(key: ValueKey('shell'))
                        : OnboardingPage(
                            key: const ValueKey('onboarding'),
                            onFinished: settings.markIntroSeen,
                          ),
                  ),
          );
        },
      ),
    );
  }
}

/// Tela neutra exibida enquanto as preferências são carregadas.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand());
  }
}
