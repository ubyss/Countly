import 'package:flutter/material.dart';

/// Sistema de movimento centralizado.
class Motion {
  const Motion._();

  static const Duration instant = Duration(milliseconds: 110);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration base = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration hero = Duration(milliseconds: 520);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve spring = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;
}

/// Rota com fade + leve deslocamento vertical, usada para navegar
/// para páginas de detalhe mantendo animações Hero fluidas.
class SoftSlideRoute<T> extends PageRouteBuilder<T> {
  SoftSlideRoute({required WidgetBuilder builder, super.settings})
      : super(
          transitionDuration: Motion.hero,
          reverseTransitionDuration: Motion.base,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Motion.emphasized,
              reverseCurve: Motion.standard.flipped,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Rota de fade puro para trocas de contexto (onboarding -> app).
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  FadeThroughRoute({required WidgetBuilder builder, super.settings})
      : super(
          transitionDuration: Motion.slow,
          reverseTransitionDuration: Motion.base,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Motion.standard);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
}
