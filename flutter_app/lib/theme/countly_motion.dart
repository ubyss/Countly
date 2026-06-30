import 'package:flutter/material.dart';

/// Sistema de movimento centralizado: durações e curvas padronizadas
/// usadas em todas as animações e transições do app.
class CountlyMotion {
  const CountlyMotion._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration intro = Duration(milliseconds: 2400);

  /// Curva padrão para a maioria das transições de entrada/saída.
  static const Curve standard = Curves.easeOutCubic;

  /// Curva mais expressiva para mudanças de estado importantes
  /// (troca de aba, troca de tema).
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Curva com leve "overshoot", usada em micro-interações lúdicas
  /// (seleção de botões, reveal do logo na intro).
  static const Curve playful = Curves.easeOutBack;
}

/// Transição de fade combinado com leve escala, usada para navegação
/// entre telas inteiras (ex.: splash -> home).
class CountlyFadeScaleRoute<T> extends PageRouteBuilder<T> {
  CountlyFadeScaleRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: CountlyMotion.slow,
          reverseTransitionDuration: CountlyMotion.base,
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: CountlyMotion.standard);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
}
