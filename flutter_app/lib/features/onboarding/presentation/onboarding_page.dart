import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pressable.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.message);

  final IconData icon;
  final String title;
  final String message;
}

const _slides = <_Slide>[
  _Slide(
    Icons.hourglass_bottom_rounded,
    'Conte os dias que importam',
    'Crie contagens regressivas para viagens, aniversários e metas — ou conte os dias desde momentos especiais.',
  ),
  _Slide(
    Icons.calendar_month_rounded,
    'Veja tudo no calendário',
    'Seus eventos organizados em uma visão mensal linda, com agenda e eventos recorrentes.',
  ),
  _Slide(
    Icons.local_fire_department_rounded,
    'Construa sequências',
    'Acompanhe hábitos de longo prazo, conquiste marcos e nunca perca o fio da sua evolução.',
  ),
];

/// Apresentação de primeiro acesso com slides animados.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(duration: Motion.slow, curve: Motion.emphasized);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.x6, Gap.x4, Gap.x4, 0),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/Logo-name.svg',
                    height: 26,
                    colorFilter: ColorFilter.mode(
                      palette.accent,
                      BlendMode.srcIn,
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: Motion.fast,
                    opacity: _isLast ? 0 : 1,
                    child: TextButton(
                      onPressed: _isLast ? null : widget.onFinished,
                      child: Text(
                        'Pular',
                        style: AppType.footnote(palette),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                itemCount: _slides.length,
                itemBuilder: (context, index) =>
                    _SlideView(slide: _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.x8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: Motion.base,
                          curve: Motion.emphasized,
                          width: i == _page ? 26 : 8,
                          height: 8,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _page
                                ? palette.accent
                                : palette.outlineStrong,
                            borderRadius:
                                BorderRadius.circular(Corner.pill),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.x6),
                  Pressable(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.accentGradientStart,
                            palette.accentGradientEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(Corner.md),
                        boxShadow: Elevations.glow(palette.accent),
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: Motion.fast,
                          child: Text(
                            _isLast ? 'Começar' : 'Continuar',
                            key: ValueKey(_isLast),
                            style: AppType.headline(palette)
                                .copyWith(color: palette.onAccent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.x10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: Motion.hero,
            curve: Motion.spring,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.accentGradientStart.withValues(alpha: 0.18),
                    palette.accentGradientEnd.withValues(alpha: 0.06),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(slide.icon, size: 64, color: palette.accent),
            ),
          ),
          const SizedBox(height: Gap.x10),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppType.largeTitle(palette).copyWith(fontSize: 28),
          ),
          const SizedBox(height: Gap.x4),
          Text(
            slide.message,
            textAlign: TextAlign.center,
            style: AppType.bodySecondary(palette).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
