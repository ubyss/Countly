import 'package:flutter/material.dart';

import '../models/repeat_mode.dart';
import '../theme/countly_colors.dart';

class RepeatToggle extends StatelessWidget {
  const RepeatToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final CountlyRepeatMode value;
  final ValueChanged<CountlyRepeatMode> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.countlyColors;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderStrong),
        color: colors.input,
      ),
      child: Row(
        children: CountlyRepeatMode.values.map((mode) {
          final isActive = mode == value;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(mode),
                borderRadius: BorderRadius.circular(9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: compact ? 32 : 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: isActive ? colors.accent : Colors.transparent,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: 0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: mode == CountlyRepeatMode.none
                      ? Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isActive ? Colors.white : colors.muted,
                        )
                      : Text(
                          mode.label,
                          style: TextStyle(
                            color: isActive ? Colors.white : colors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
