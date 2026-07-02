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

/// Card imersivo da grade: imagem/gradiente de fundo, métrica grande
/// e título, com animação Hero para a página de detalhe.
class CounterGridCard extends StatelessWidget {
  const CounterGridCard({
    super.key,
    required this.counter,
    required this.now,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
  });

  final Counter counter;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final snapshot = CounterSnapshot.of(counter, now);

    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: '${counter.title}, ${snapshot.headline}',
      child: AnimatedContainer(
        duration: Motion.fast,
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Corner.lg),
          border:
              selected ? Border.all(color: palette.accent, width: 3) : null,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Corner.lg),
          boxShadow: Elevations.soft(palette),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Corner.lg),
          child: Hero(
            tag: 'counter-visual-${counter.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CounterBackdrop(counter: counter),
                  Padding(
                    padding: const EdgeInsets.all(Gap.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (snapshot.isToday)
                              const _TodayBadge()
                            else if (counter.recurrence.repeats)
                              const _GlassTag(icon: Icons.repeat_rounded),
                            const Spacer(),
                            if (selectionMode)
                              _SelectionDot(selected: selected)
                            else if (counter.favorite)
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFD452),
                                size: 22,
                              ),
                          ],
                        ),
                        const Spacer(),
                        _CardFooter(counter: counter, snapshot: snapshot),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.counter, required this.snapshot});

  final Counter counter;
  final CounterSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final unit = snapshot.units.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (snapshot.isToday)
          Text(
            'É hoje!',
            style: AppType.metric(palette).copyWith(color: Colors.white),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${unit.value}',
                style: AppType.metric(palette)
                    .copyWith(color: Colors.white, fontSize: 34),
              ),
              const SizedBox(width: Gap.x1),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  unit.label.toLowerCase(),
                  style: AppType.footnote(palette).copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: Gap.x1),
        Text(
          counter.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppType.headline(palette).copyWith(color: Colors.white),
        ),
        if (snapshot.eventDate != null) ...[
          const SizedBox(height: 2),
          Text(
            formatDayMonth(snapshot.eventDate!),
            style: AppType.caption(palette).copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.x3, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(Corner.pill),
      ),
      child: const Text(
        '🎉 Hoje',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnimatedContainer(
      duration: Motion.fast,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color:
            selected ? palette.accent : Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}
