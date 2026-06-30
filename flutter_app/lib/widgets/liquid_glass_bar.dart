import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/countly_colors.dart';
import '../theme/countly_motion.dart';

enum CountlyNavTab { countdowns, calendar }

class LiquidGlassBar extends StatelessWidget {
  const LiquidGlassBar({
    super.key,
    required this.activeTab,
    required this.isDark,
    required this.onTabChanged,
    required this.onAddPressed,
  });

  final CountlyNavTab activeTab;
  final bool isDark;
  final ValueChanged<CountlyNavTab> onTabChanged;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final colors = isDark ? CountlyColors.dark : CountlyColors.light;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: _CountlyTabSwitcher(
              activeTab: activeTab,
              colors: colors,
              isDark: isDark,
              onTabChanged: onTabChanged,
            ),
          ),
          const SizedBox(width: 12),
          _CountlyAddButton(colors: colors, onTap: onAddPressed),
        ],
      ),
    );
  }
}

class _CountlyTabSwitcher extends StatefulWidget {
  const _CountlyTabSwitcher({
    required this.activeTab,
    required this.colors,
    required this.isDark,
    required this.onTabChanged,
  });

  final CountlyNavTab activeTab;
  final CountlyColors colors;
  final bool isDark;
  final ValueChanged<CountlyNavTab> onTabChanged;

  @override
  State<_CountlyTabSwitcher> createState() => _CountlyTabSwitcherState();
}

class _CountlyTabSwitcherState extends State<_CountlyTabSwitcher>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 560);

  late final AnimationController _controller;
  late final Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _position = CurvedAnimation(
      parent: _controller,
      curve: CountlyMotion.playful,
    );
    _controller.value = widget.activeTab.index.toDouble();
  }

  @override
  void didUpdateWidget(covariant _CountlyTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTab != widget.activeTab) {
      _controller.animateTo(
        widget.activeTab.index.toDouble(),
        duration: _duration,
        curve: CountlyMotion.playful,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTabTap(CountlyNavTab tab) {
    if (tab == widget.activeTab) {
      return;
    }
    widget.onTabChanged(tab);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return GlassContainer(
      height: 56,
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: const LiquidRoundedSuperellipse(borderRadius: 28),
      settings: LiquidGlassSettings(
        glassColor: colors.glassFill,
        thickness: 18,
        blur: 10,
        saturation: 1.35,
        lightIntensity: 0.42,
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const tabCount = 2;
          final segmentWidth = constraints.maxWidth / tabCount;

          return AnimatedBuilder(
            animation: _position,
            builder: (context, _) {
              final slide = _position.value.clamp(0.0, 1.0);
              final leftStrength = 1 - slide;
              final rightStrength = slide;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: slide * segmentWidth,
                    top: 0,
                    width: segmentWidth,
                    height: constraints.maxHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: colors.accent.withValues(
                            alpha: widget.isDark ? 0.55 : 0.34,
                          ),
                        ),
                        color: widget.isDark
                            ? Colors.transparent
                            : colors.accentSoft.withValues(alpha: 0.98),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _CountlyNavTabButton(
                        label: 'Contagens',
                        icon: Icons.calendar_view_day_rounded,
                        selectionStrength: leftStrength,
                        colors: colors,
                        isDark: widget.isDark,
                        onTap: () => _onTabTap(CountlyNavTab.countdowns),
                      ),
                      _CountlyNavTabButton(
                        label: 'Calendário',
                        icon: Icons.calendar_month_rounded,
                        selectionStrength: rightStrength,
                        colors: colors,
                        isDark: widget.isDark,
                        onTap: () => _onTabTap(CountlyNavTab.calendar),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CountlyNavTabButton extends StatelessWidget {
  const _CountlyNavTabButton({
    required this.label,
    required this.icon,
    required this.selectionStrength,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double selectionStrength;
  final CountlyColors colors;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strength = selectionStrength.clamp(0.0, 1.0);
    final unselectedColor = colors.text.withValues(alpha: 0.72);
    final selectedColor = isDark ? Colors.white : colors.accent;
    final contentColor = Color.lerp(unselectedColor, selectedColor, strength)!;
    final fontWeight = FontWeight.lerp(FontWeight.w600, FontWeight.w700, strength)!;
    final iconScale = 1 + (strength * 0.12);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: colors.accent.withValues(alpha: 0.08),
          highlightColor: colors.accent.withValues(alpha: 0.04),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: iconScale,
                child: Icon(icon, size: 20, color: contentColor),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 11,
                  fontWeight: fontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountlyAddButton extends StatelessWidget {
  const _CountlyAddButton({
    required this.colors,
    required this.onTap,
  });

  final CountlyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      onPressed: onTap,
      size: 56,
      iconSize: 28,
      useOwnLayer: true,
      quality: GlassQuality.standard,
      interactionScale: 0.96,
      glowColor: colors.accent.withValues(alpha: 0.45),
      settings: LiquidGlassSettings(
        glassColor: Color.fromARGB(210, colors.accent.red, colors.accent.green, colors.accent.blue),
        thickness: 28,
        blur: 10,
        saturation: 1.6,
        lightIntensity: 0.65,
      ),
    );
  }
}
