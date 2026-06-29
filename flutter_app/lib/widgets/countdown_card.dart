import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/countdown.dart';
import '../models/repeat_mode.dart';
import '../theme/countly_colors.dart';
import '../utils/countdown_utils.dart';
import 'countdown_image.dart';
import 'countdown_time_overlay.dart';

class CountdownCard extends StatelessWidget {
  const CountdownCard({
    super.key,
    required this.countdown,
    required this.currentTime,
    required this.onEdit,
    this.showShadow = true,
    this.compactTitle = false,
  });

  final Countdown countdown;
  final ValueListenable<DateTime> currentTime;
  final VoidCallback onEdit;
  final bool showShadow;
  final bool compactTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.countlyColors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
        color: colors.card,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: colors.text.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ]
            : [],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CountdownImagePreview(
                    imageBase64: countdown.imageBase64,
                    colors: colors,
                    height: double.infinity,
                    borderRadius: 0,
                    alignment: countdown.imageAlignment,
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ValueListenableBuilder<DateTime>(
                    valueListenable: currentTime,
                    builder: (context, time, _) {
                      return CountdownTimeOverlay(
                        targetDate: countdown.targetDate,
                        currentTime: time,
                        onCard: true,
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _CardEditButton(
                    colors: colors,
                    onEdit: onEdit,
                  ),
                ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  countdown.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: compactTitle ? 14 : 17,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: colors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        formatDateLabel(countdown.targetDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted, fontSize: 12),
                      ),
                    ),
                    if (countdown.repeat != CountlyRepeatMode.none) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat_rounded, size: 13, color: colors.accent),
                          const SizedBox(width: 4),
                          Text(
                            countdown.repeat.displayLabel,
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardEditButton extends StatelessWidget {
  const _CardEditButton({
    required this.colors,
    required this.onEdit,
  });

  final CountlyColors colors;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: colors.text.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onEdit,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.text.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.penToSquare,
              size: 15,
              color: colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
