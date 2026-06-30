import 'package:flutter/material.dart';

import '../theme/countly_motion.dart';

/// Envolve [child] com feedback tátil de escala ao toque: reduz
/// sutilmente no tap-down e retorna com uma curva suave ao soltar,
/// dando uma sensação fluida e "satisfatória" para qualquer elemento
/// tocável (cards, thumbnails, botões customizados).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1,
        duration: CountlyMotion.instant,
        curve: CountlyMotion.standard,
        child: widget.child,
      ),
    );
  }
}
