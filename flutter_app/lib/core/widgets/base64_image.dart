import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Exibe uma imagem persistida em base64, memoizando a decodificação
/// para evitar trabalho repetido em rebuilds.
class Base64Image extends StatefulWidget {
  const Base64Image({
    super.key,
    required this.base64,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  final String base64;
  final Alignment alignment;
  final BoxFit fit;

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(Base64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64 != widget.base64) {
      _decode();
    }
  }

  void _decode() {
    try {
      _bytes = base64Decode(widget.base64);
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return const SizedBox.shrink();
    }
    return Image.memory(
      bytes,
      fit: widget.fit,
      alignment: widget.alignment,
      gaplessPlayback: true,
    );
  }
}
