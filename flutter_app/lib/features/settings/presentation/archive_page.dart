import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/round_icon_button.dart';

/// Itens arquivados (contagens e hábitos) com restauração e exclusão.
class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dependencies = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            dependencies.counters,
            dependencies.habits,
          ]),
          builder: (context, _) {
            final counters = dependencies.counters.archived;
            final habits = dependencies.habits.archived;
            final isEmpty = counters.isEmpty && habits.isEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.x4,
                    Gap.x2,
                    Gap.x4,
                    0,
                  ),
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Voltar',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: Gap.x3),
                      Text('Arquivadas', style: AppType.title(palette)),
                    ],
                  ),
                ),
                Expanded(
                  child: isEmpty
                      ? const EmptyState(
                          icon: Icons.archive_outlined,
                          title: 'Arquivo vazio',
                          message:
                              'Contagens e hábitos arquivados aparecem aqui e podem ser restaurados a qualquer momento.',
                        )
                      : ListView(
                          padding: const EdgeInsets.all(Gap.page),
                          children: [
                            if (counters.isNotEmpty) ...[
                              Text(
                                'CONTAGENS',
                                style: AppType.overline(palette),
                              ),
                              const SizedBox(height: Gap.x3),
                              for (final counter in counters)
                                _ArchivedRow(
                                  icon: AppIcons.resolve(counter.iconName),
                                  accent: counter.accent,
                                  title: counter.title,
                                  onRestore: () => dependencies.counters
                                      .setArchived(counter.id, false),
                                  onDelete: () async {
                                    final confirmed =
                                        await showConfirmDialog(
                                      context,
                                      title: 'Excluir contagem?',
                                      message:
                                          '"${counter.title}" será removida permanentemente.',
                                      confirmLabel: 'Excluir',
                                      destructive: true,
                                    );
                                    if (confirmed) {
                                      await dependencies.counters
                                          .remove(counter.id);
                                    }
                                  },
                                ),
                              const SizedBox(height: Gap.x5),
                            ],
                            if (habits.isNotEmpty) ...[
                              Text(
                                'HÁBITOS',
                                style: AppType.overline(palette),
                              ),
                              const SizedBox(height: Gap.x3),
                              for (final habit in habits)
                                _ArchivedRow(
                                  icon: AppIcons.resolve(habit.iconName),
                                  accent: habit.accent,
                                  title: habit.title,
                                  onRestore: () => dependencies.habits
                                      .setArchived(habit.id, false),
                                  onDelete: () async {
                                    final confirmed =
                                        await showConfirmDialog(
                                      context,
                                      title: 'Excluir hábito?',
                                      message:
                                          '"${habit.title}" e o histórico serão removidos.',
                                      confirmLabel: 'Excluir',
                                      destructive: true,
                                    );
                                    if (confirmed) {
                                      await dependencies.habits
                                          .remove(habit.id);
                                    }
                                  },
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.onRestore,
    required this.onDelete,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final adaptiveAccent =
        CountlyAccents.adaptive(accent, Theme.of(context).brightness);

    return Container(
      margin: const EdgeInsets.only(bottom: Gap.x2),
      padding: const EdgeInsets.all(Gap.x3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(Corner.md),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: adaptiveAccent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: adaptiveAccent),
          ),
          const SizedBox(width: Gap.x3),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.headline(palette),
            ),
          ),
          RoundIconButton(
            icon: Icons.unarchive_rounded,
            tooltip: 'Restaurar',
            size: 38,
            color: palette.accent,
            onTap: onRestore,
          ),
          const SizedBox(width: Gap.x2),
          RoundIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Excluir',
            size: 38,
            color: palette.danger,
            background: palette.dangerSoft,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
