import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/pressable.dart';
import '../../application/counters_controller.dart';

const _modeIcons = {
  CounterViewMode.grid: Icons.grid_view_rounded,
  CounterViewMode.list: Icons.view_agenda_rounded,
  CounterViewMode.timeline: Icons.timeline_rounded,
};

const _modeLabels = {
  CounterViewMode.grid: 'Grade',
  CounterViewMode.list: 'Lista',
  CounterViewMode.timeline: 'Linha do tempo',
};

/// Controle segmentado para alternar entre as visualizações.
class ViewModeSwitcher extends StatelessWidget {
  const ViewModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final CounterViewMode mode;
  final ValueChanged<CounterViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceSunken,
        borderRadius: BorderRadius.circular(Corner.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in CounterViewMode.values)
            Pressable(
              onTap: () => onChanged(item),
              pressedScale: 0.9,
              semanticLabel: _modeLabels[item],
              child: AnimatedContainer(
                duration: Motion.base,
                curve: Motion.emphasized,
                width: 40,
                height: 34,
                decoration: BoxDecoration(
                  color: item == mode ? palette.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(Corner.pill),
                  boxShadow: item == mode ? Elevations.soft(palette) : null,
                ),
                child: Icon(
                  _modeIcons[item],
                  size: 19,
                  color: item == mode
                      ? palette.accent
                      : palette.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
