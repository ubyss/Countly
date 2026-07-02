import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/counter.dart';
import '../../domain/counter_snapshot.dart';
import 'counter_visual.dart';

/// Linha compacta da lista com ações por deslize:
/// direita -> favoritar, esquerda -> arquivar.
class CounterListTile extends StatelessWidget {
  const CounterListTile({
    super.key,
    required this.counter,
    required this.now,
    required this.onTap,
    required this.onFavorite,
    required this.onArchive,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
  });

  final Counter counter;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final snapshot = CounterSnapshot.of(counter, now);
    final unit = snapshot.units.first;

    final tile = Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      pressedScale: 0.98,
      semanticLabel: '${counter.title}, ${snapshot.headline}',
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.all(Gap.x4),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(Corner.md),
          border: Border.all(
            color: selected ? palette.accent : palette.outline,
            width: selected ? 2 : 1,
          ),
          boxShadow: Elevations.soft(palette),
        ),
        child: Row(
          children: [
            if (selectionMode) ...[
              AnimatedContainer(
                duration: Motion.fast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? palette.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? palette.accent : palette.outlineStrong,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded,
                        size: 14, color: palette.onAccent)
                    : null,
              ),
              const SizedBox(width: Gap.x3),
            ],
            CounterIconBadge(counter: counter, onSurface: true),
            const SizedBox(width: Gap.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          counter.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.headline(palette),
                        ),
                      ),
                      if (counter.favorite) ...[
                        const SizedBox(width: Gap.x1),
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFEFB018),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snapshot.eventDate != null
                        ? formatDayMonth(snapshot.eventDate!)
                        : snapshot.headline,
                    style: AppType.footnote(palette),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.x3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  snapshot.isToday ? '🎉' : '${unit.value}',
                  style: AppType.metric(palette).copyWith(fontSize: 24),
                ),
                Text(
                  snapshot.isToday ? 'hoje' : unit.label.toLowerCase(),
                  style: AppType.caption(palette),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (selectionMode) {
      return tile;
    }

    return Dismissible(
      key: ValueKey('dismiss-${counter.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onFavorite();
        } else {
          onArchive();
        }
        return false;
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: const Color(0xFFEFB018),
        icon: counter.favorite
            ? Icons.star_outline_rounded
            : Icons.star_rounded,
        label: counter.favorite ? 'Remover' : 'Favoritar',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: palette.textSecondary,
        icon: Icons.archive_rounded,
        label: 'Arquivar',
      ),
      child: tile,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: Gap.x6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Corner.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppType.caption(palette).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
