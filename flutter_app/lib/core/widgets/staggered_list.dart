import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Entrada escalonada (fade + deslize) para itens de listas e grids.
///
/// Anima apenas na primeira montagem para não interferir em rolagem.
class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 40),
  });

  final int index;
  final Widget child;
  final Duration baseDelay;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.standard,
  );

  @override
  void initState() {
    super.initState();
    final cappedIndex = widget.index.clamp(0, 10);
    Future.delayed(widget.baseDelay * cappedIndex, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
