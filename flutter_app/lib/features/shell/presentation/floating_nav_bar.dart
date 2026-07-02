import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/pressable.dart';

enum AppTab { counters, calendar, habits, settings }

class _TabSpec {
  const _TabSpec(this.tab, this.icon, this.activeIcon, this.label);

  final AppTab tab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const _tabs = <_TabSpec>[
  _TabSpec(
    AppTab.counters,
    Icons.hourglass_empty_rounded,
    Icons.hourglass_bottom_rounded,
    'Contagens',
  ),
  _TabSpec(
    AppTab.calendar,
    Icons.calendar_month_outlined,
    Icons.calendar_month_rounded,
    'Calendário',
  ),
  _TabSpec(
    AppTab.habits,
    Icons.local_fire_department_outlined,
    Icons.local_fire_department_rounded,
    'Hábitos',
  ),
  _TabSpec(
    AppTab.settings,
    Icons.tune_rounded,
    Icons.tune_rounded,
    'Ajustes',
  ),
];

/// Barra de navegação flutuante em vidro, com indicador animado.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.current,
    required this.onChanged,
    this.fabVisible = false,
  });

  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  /// Quando o FAB está visível, os rótulos são ocultados para evitar
  /// overflow horizontal na barra inferior.
  final bool fabVisible;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final showLabels = !fabVisible && width >= 400;

    return GlassPanel(
      borderRadius: BorderRadius.circular(Corner.pill),
      padding: const EdgeInsets.all(Gap.x1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final spec in _tabs)
            _NavItem(
              spec: spec,
              selected: spec.tab == current,
              accent: palette.accent,
              showLabel: showLabels,
              onTap: () => onChanged(spec.tab),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.accent,
    required this.showLabel,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final Color accent;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      semanticLabel: spec.label,
      child: AnimatedContainer(
        duration: selected ? Motion.base : Motion.fast,
        curve: selected ? Motion.emphasized : Motion.standard,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? Gap.x4 : Gap.x3,
          vertical: Gap.x3,
        ),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(Corner.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? spec.activeIcon : spec.icon,
              size: 24,
              color: selected ? accent : palette.textTertiary,
            ),
            AnimatedSize(
              duration: selected ? Motion.base : Duration.zero,
              curve: Motion.emphasized,
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.hardEdge,
              child: selected && showLabel
                  ? Padding(
                      padding: const EdgeInsets.only(left: Gap.x2),
                      child: Text(
                        spec.label,
                        style: AppType.footnote(palette).copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
