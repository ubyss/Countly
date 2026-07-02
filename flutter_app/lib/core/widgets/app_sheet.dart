import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Abre um bottom sheet modal com o visual padrão do app
/// (cantos arredondados, alça de arrasto e respeito ao teclado).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool expand = false,
}) {
  final palette = context.palette;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: palette.scrim,
    builder: (sheetContext) {
      final viewInsets = MediaQuery.viewInsetsOf(sheetContext);
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.92 -
          viewInsets.bottom;

      final content = Container(
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(Corner.xl)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            const SizedBox(height: Gap.x3),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.outlineStrong,
                borderRadius: BorderRadius.circular(Corner.pill),
              ),
            ),
            Flexible(
              fit: expand ? FlexFit.tight : FlexFit.loose,
              child: builder(sheetContext),
            ),
          ],
        ),
      );

      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: expand
            ? FractionallySizedBox(heightFactor: 0.94, child: content)
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: content,
              ),
      );
    },
  );
}
