import 'package:flutter/material.dart';

import '../theme/countly_motion.dart';

/// Anima a entrada de um item de lista/grade com fade + slide-up sutil,
/// aplicando um atraso incremental baseado em [index] para criar um
/// efeito "staggered" quando vários itens aparecem juntos na tela.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.stagger = const Duration(milliseconds: 45),
    this.duration = CountlyMotion.slow,
  });

  final int index;
  final Widget child;
  final Duration stagger;
  final Duration duration;

  static const int _maxStaggeredIndex = 8;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: CountlyMotion.standard);
    _fade = curved;
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved);

    final cappedIndex = widget.index.clamp(0, StaggeredFadeIn._maxStaggeredIndex);
    final delay = widget.stagger * cappedIndex;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
