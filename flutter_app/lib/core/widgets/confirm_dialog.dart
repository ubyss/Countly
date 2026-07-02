import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

/// Diálogo de confirmação com hierarquia visual clara e ação
/// destrutiva destacada.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final palette = context.palette;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(Gap.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppType.title(palette)),
            const SizedBox(height: Gap.x2),
            Text(message, style: AppType.bodySecondary(palette)),
            const SizedBox(height: Gap.x6),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: cancelLabel,
                    background: palette.surfaceSunken,
                    foreground: palette.textPrimary,
                    onTap: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: Gap.x3),
                Expanded(
                  child: _DialogButton(
                    label: confirmLabel,
                    background: destructive ? palette.danger : palette.accent,
                    foreground:
                        destructive ? Colors.white : palette.onAccent,
                    onTap: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Pressable(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Corner.sm),
        ),
        child: Text(
          label,
          style: AppType.headline(palette).copyWith(color: foreground),
        ),
      ),
    );
  }
}
