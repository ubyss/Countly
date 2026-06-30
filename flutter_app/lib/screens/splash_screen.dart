import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/countly_colors.dart';
import '../theme/countly_motion.dart';
import '../theme/countly_tokens.dart';

/// Splash de boas-vindas exibida apenas no primeiro acesso ao app:
/// revela a marca Countly com uma animação fluida sobre um fundo de
/// gradiente roxo com "blobs" de vidro líquido respirando ao fundo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.isDark,
    required this.onFinished,
  });

  final bool isDark;
  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _ambient;

  late final Animation<double> _blobOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _wordmarkOffset;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _taglineOpacity;

  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(vsync: this, duration: CountlyMotion.intro)
      ..addStatusListener(_handleEntranceStatus)
      ..forward();
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);

    _blobOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.08, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.08, 0.46, curve: Curves.easeOut),
    );
    _wordmarkOffset = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.42, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _wordmarkOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.42, 0.72, curve: Curves.easeOut),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.6, 0.88, curve: Curves.easeOut),
    );
  }

  void _handleEntranceStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      Future.delayed(const Duration(milliseconds: 500), _leave);
    }
  }

  void _leave() {
    if (_isLeaving || !mounted) {
      return;
    }
    _isLeaving = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _entrance.removeStatusListener(_handleEntranceStatus);
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CountlyColors.forDark(widget.isDark);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _leave,
      child: Scaffold(
        backgroundColor: colors.accentGradientEnd,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.accentGradientStart, colors.accentGradientEnd],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: _blobOpacity,
                child: AnimatedBuilder(
                  animation: _ambient,
                  builder: (context, _) => _AmbientBlobs(progress: _ambient.value),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: const _LogoBadge(),
                        ),
                      ),
                      const SizedBox(height: CountlySpacing.xxxl),
                      ClipRect(
                        child: SlideTransition(
                          position: _wordmarkOffset,
                          child: FadeTransition(
                            opacity: _wordmarkOpacity,
                            child: SvgPicture.asset(
                              'assets/Logo-name.svg',
                              height: 30,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: CountlySpacing.md),
                      FadeTransition(
                        opacity: _taglineOpacity,
                        child: Text(
                          'Contagens que importam, com estilo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: 132,
      height: 132,
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: const LiquidOval(),
      settings: const LiquidGlassSettings(
        glassColor: Color(0x59FFFFFF),
        thickness: 26,
        blur: 12,
        saturation: 1.4,
        lightIntensity: 0.6,
      ),
      child: Center(
        child: SvgPicture.asset('assets/icon.svg', width: 64, height: 64),
      ),
    );
  }
}

class _AmbientBlobs extends StatelessWidget {
  const _AmbientBlobs({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(progress * math.pi * 2);

    return Stack(
      children: [
        _Blob(top: -60 + wave * 18, left: -50 - wave * 12, size: 220),
        _Blob(bottom: -70 - wave * 16, right: -40 + wave * 14, size: 260),
        _Blob(top: 140 - wave * 10, right: -80 + wave * 10, size: 160),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
          ),
        ),
      ),
    );
  }
}
