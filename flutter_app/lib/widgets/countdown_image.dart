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
  });

  final String? imageBase64;
  final CountlyColors colors;
  final double height;
  final double borderRadius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageBytes = decodeCountdownImage(imageBase64);
    final fillsAvailableSpace = !height.isFinite;
    final imageContent = imageBytes != null
        ? RepaintBoundary(
            child: Image.memory(
              imageBytes,
              key: ValueKey<String>(imageBase64!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: fillsAvailableSpace ? double.infinity : height,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
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
