import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../../core/widgets/tag_chip.dart';
import '../domain/counter.dart';
import '../domain/counter_snapshot.dart';
import 'counter_editor_sheet.dart';
import 'widgets/counter_visual.dart';

/// Página de detalhe de uma contagem, com cabeçalho Hero, métricas
/// grandes, notas, tags e ações rápidas.
class CounterDetailPage extends StatelessWidget {
  const CounterDetailPage({super.key, required this.counterId});

  final String counterId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).counters;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final counter = controller.byId(counterId);
        if (counter == null) {
          // Contagem excluída enquanto a página estava aberta.
          return const Scaffold(body: SizedBox.shrink());
        }
        return _DetailScaffold(counter: counter);
      },
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.counter});

  final Counter counter;

  Future<void> _delete(BuildContext context) async {
    final controller = AppScope.of(context).counters;
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir contagem?',
      message: '"${counter.title}" será removida permanentemente.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    navigator.pop();
    await controller.remove(counter.id);
  }

  Future<void> _archive(BuildContext context) async {
    final controller = AppScope.of(context).counters;
    final navigator = Navigator.of(context);
    navigator.pop();
    await controller.setArchived(counter.id, true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = AppScope.of(context).counters;
    final now = DateTime.now();
    final snapshot = CounterSnapshot.of(counter, now);
    final accent =
        CountlyAccents.adaptive(counter.accent, Theme.of(context).brightness);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 340,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'counter-visual-${counter.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(Corner.xl),
                          ),
                          child: CounterBackdrop(counter: counter),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.x4,
                          vertical: Gap.x2,
                        ),
                        child: Row(
                          children: [
                            RoundIconButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Voltar',
                              background:
                                  Colors.black.withValues(alpha: 0.28),
                              color: Colors.white,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                            RoundIconButton(
                              icon: counter.favorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              tooltip: 'Favoritar',
                              background:
                                  Colors.black.withValues(alpha: 0.28),
                              color: counter.favorite
                                  ? const Color(0xFFFFD452)
                                  : Colors.white,
                              onTap: () =>
                                  controller.toggleFavorite(counter.id),
                            ),
                            const SizedBox(width: Gap.x2),
                            RoundIconButton(
                              icon: Icons.edit_rounded,
                              tooltip: 'Editar',
                              background:
                                  Colors.black.withValues(alpha: 0.28),
                              color: Colors.white,
                              onTap: () => showCounterEditorSheet(
                                context,
                                existing: counter,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: Gap.page,
                    right: Gap.page,
                    bottom: Gap.x6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          counter.title,
                          style: AppType.largeTitle(palette)
                              .copyWith(color: Colors.white),
                        ),
                        if (counter.description.isNotEmpty) ...[
                          const SizedBox(height: Gap.x1),
                          Text(
                            counter.description,
                            style: AppType.body(palette).copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Gap.page,
              Gap.x6,
              Gap.page,
              Gap.x12,
            ),
            sliver: SliverList.list(
              children: [
                StaggeredReveal(
                  index: 0,
                  child: _MetricsCard(snapshot: snapshot, accent: accent),
                ),
                const SizedBox(height: Gap.x4),
                StaggeredReveal(
                  index: 1,
                  child: _InfoCard(counter: counter, snapshot: snapshot),
                ),
                if (counter.tags.isNotEmpty) ...[
                  const SizedBox(height: Gap.x4),
                  StaggeredReveal(
                    index: 2,
                    child: Wrap(
                      spacing: Gap.x2,
                      runSpacing: Gap.x2,
                      children: [
                        for (final tag in counter.tags) TagChip(label: '#$tag'),
                      ],
                    ),
                  ),
                ],
                if (counter.notes.isNotEmpty) ...[
                  const SizedBox(height: Gap.x4),
                  StaggeredReveal(
                    index: 3,
                    child: _NotesCard(notes: counter.notes),
                  ),
                ],
                const SizedBox(height: Gap.x6),
                StaggeredReveal(
                  index: 4,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.archive_rounded,
                          label: 'Arquivar',
                          onTap: () => _archive(context),
                        ),
                      ),
                      const SizedBox(width: Gap.x3),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Excluir',
                          destructive: true,
                          onTap: () => _delete(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.snapshot, required this.accent});

  final CounterSnapshot snapshot;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(Gap.x6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(Corner.lg),
        border: Border.all(color: palette.outline),
        boxShadow: Elevations.soft(palette),
      ),
      child: Column(
        children: [
          Text(
            snapshot.headline,
            style: AppType.footnote(palette).copyWith(color: accent),
          ),
          const SizedBox(height: Gap.x4),
          if (snapshot.isToday)
            Text('🎉', style: AppType.display(palette))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < snapshot.units.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(width: Gap.x6),
                    Container(
                      width: 1,
                      height: 48,
                      color: palette.outline,
                    ),
                    const SizedBox(width: Gap.x6),
                  ],
                  Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: snapshot.units[i].value.toDouble(),
                        ),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          value.round().toString().padLeft(2, '0'),
                          style: AppType.display(palette),
                        ),
                      ),
                      const SizedBox(height: Gap.x1),
                      Text(
                        snapshot.units[i].label.toUpperCase(),
                        style: AppType.overline(palette),
                      ),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.counter, required this.snapshot});

  final Counter counter;
  final CounterSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget row(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.x2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: palette.textTertiary),
            const SizedBox(width: Gap.x3),
            Text(label, style: AppType.footnote(palette)),
            const Spacer(),
            Text(
              value,
              style: AppType.footnote(palette)
                  .copyWith(color: palette.textPrimary),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.x5,
        vertical: Gap.x2,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(Corner.lg),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        children: [
          if (snapshot.eventDate != null)
            row(
              Icons.event_rounded,
              counter.recurrence.repeats ? 'Próxima ocorrência' : 'Data',
              formatFullDate(snapshot.eventDate!),
            ),
          if (counter.recurrence.repeats)
            row(
              Icons.repeat_rounded,
              'Repetição',
              counter.recurrence.label,
            ),
          row(
            Icons.history_rounded,
            'Criada em',
            formatFullDate(counter.createdAt),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.x5),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(Corner.lg),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTAS', style: AppType.overline(palette)),
          const SizedBox(height: Gap.x2),
          Text(notes, style: AppType.body(palette)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = destructive ? palette.danger : palette.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: destructive ? palette.dangerSoft : palette.surfaceSunken,
          borderRadius: BorderRadius.circular(Corner.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: Gap.x2),
            Text(
              label,
              style: AppType.headline(palette).copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
