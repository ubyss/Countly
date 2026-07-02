import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pressable.dart';
import 'archive_page.dart';

/// Página de ajustes: tema, arquivo e informações do app.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dependencies = AppScope.of(context);
    final settings = dependencies.settings;

    return ListenableBuilder(
      listenable: Listenable.merge([
        settings,
        dependencies.counters,
        dependencies.habits,
      ]),
      builder: (context, _) {
        final archivedCount = dependencies.counters.archived.length +
            dependencies.habits.archived.length;

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 130),
            children: [
              const PageHeader(title: 'Ajustes'),
              const SizedBox(height: Gap.x6),
              _SectionLabel('Aparência'),
              _SettingsCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Gap.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tema', style: AppType.headline(palette)),
                        const SizedBox(height: Gap.x3),
                        _ThemeSelector(
                          mode: settings.themeMode,
                          onChanged: settings.setThemeMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.x6),
              _SectionLabel('Organização'),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.archive_rounded,
                    title: 'Arquivadas',
                    subtitle: archivedCount == 0
                        ? 'Nada arquivado'
                        : '$archivedCount itens',
                    onTap: () => Navigator.of(context).push(
                      SoftSlideRoute(builder: (_) => const ArchivePage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.x6),
              _SectionLabel('Sobre'),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.hourglass_bottom_rounded,
                    title: 'Countly',
                    subtitle: 'Versão 2.0.0',
                  ),
                  Divider(color: palette.outline, height: 1),
                  _SettingsRow(
                    icon: Icons.notifications_active_rounded,
                    title: 'Lembretes',
                    subtitle: 'Avisos automáticos 7 dias e 1 dia antes',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page + Gap.x1, 0, Gap.page, Gap.x2),
      child: Text(text.toUpperCase(), style: AppType.overline(context.palette)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.page),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(Corner.lg),
          border: Border.all(color: palette.outline),
          boxShadow: Elevations.soft(palette),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.99,
      child: Padding(
        padding: const EdgeInsets.all(Gap.x4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(Corner.xs),
              ),
              child: Icon(icon, size: 20, color: palette.accent),
            ),
            const SizedBox(width: Gap.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.headline(palette)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppType.footnote(palette)),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    const options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, 'Sistema'),
      (ThemeMode.light, Icons.light_mode_rounded, 'Claro'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Escuro'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceSunken,
        borderRadius: BorderRadius.circular(Corner.sm),
      ),
      child: Row(
        children: [
          for (final (value, icon, label) in options)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(value),
                pressedScale: 0.95,
                child: AnimatedContainer(
                  duration: Motion.base,
                  curve: Motion.emphasized,
                  padding: const EdgeInsets.symmetric(vertical: Gap.x2),
                  decoration: BoxDecoration(
                    color: mode == value ? palette.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(Corner.xs),
                    boxShadow:
                        mode == value ? Elevations.soft(palette) : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: mode == value
                            ? palette.accent
                            : palette.textTertiary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppType.caption(palette).copyWith(
                          color: mode == value
                              ? palette.textPrimary
                              : palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
