import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/countly_colors.dart';

Uint8List? decodeCountdownImage(String? base64) {
  if (base64 == null || base64.isEmpty) {
    return null;
  }

  try {
    final payload = base64.contains(',') ? base64.split(',').last : base64;
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

class CountdownImagePreview extends StatelessWidget {
  const CountdownImagePreview({
    super.key,
    required this.imageBase64,
    required this.colors,
    this.height = 160,
    this.borderRadius = 14,
    this.compact = false,
    this.alignment = Alignment.center,
    this.panEnabled = false,
    this.onAlignmentChanged,
  });

  final String? imageBase64;
  final CountlyColors colors;
  final double height;
  final double borderRadius;
  final bool compact;
  final Alignment alignment;
  final bool panEnabled;
  final ValueChanged<Alignment>? onAlignmentChanged;

  @override
  Widget build(BuildContext context) {
    final imageBytes = decodeCountdownImage(imageBase64);
    final fillsAvailableSpace = !height.isFinite;

    final Widget coreImage = imageBytes != null
        ? _CoverImage(
            bytes: imageBytes,
            alignment: alignment,
            cacheKey: imageBase64!,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.accentSoft,
                  colors.accent.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: compact ? 28 : 42,
                color: colors.accent.withValues(alpha: 0.45),
              ),
            ),
          );

    Widget imageContent = coreImage;

    if (panEnabled && imageBytes != null && onAlignmentChanged != null) {
      imageContent = LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              final width = constraints.maxWidth;
              final heightValue = constraints.maxHeight;
              if (width <= 0 || heightValue <= 0) {
                return;
              }

              onAlignmentChanged!(
                Alignment(
                  (alignment.x - details.delta.dx / width * 2).clamp(-1.0, 1.0),
                  (alignment.y - details.delta.dy / height * 2).clamp(-1.0, 1.0),
                ),
              );
            },
            child: coreImage,
          );
        },
      );
    }

    if (borderRadius <= 0) {
      if (fillsAvailableSpace) {
        return SizedBox.expand(child: imageContent);
      }
      return SizedBox(
        height: height,
        width: double.infinity,
        child: imageContent,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: fillsAvailableSpace
          ? SizedBox.expand(child: imageContent)
          : SizedBox(
              height: height,
              width: double.infinity,
              child: imageContent,
            ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.bytes,
    required this.alignment,
    required this.cacheKey,
  });

  final Uint8List bytes;
  final Alignment alignment;
  final String cacheKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipRect(
        child: Image.memory(
          bytes,
          key: ValueKey<String>(cacheKey),
          fit: BoxFit.cover,
          alignment: alignment,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
