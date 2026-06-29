import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

const _maxImageEdge = 900;

Future<String?> prepareCountdownImageBase64(Uint8List bytes) async {
  if (bytes.isEmpty) {
    return null;
  }

  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: _maxImageEdge);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();

    if (byteData == null) {
      return null;
    }

    final compressed = byteData.buffer.asUint8List();
    if (kIsWeb) {
      return base64Encode(compressed);
    }

    return compute(_encodeBase64, compressed);
  } catch (_) {
    return null;
  }
}

String _encodeBase64(Uint8List bytes) => base64Encode(bytes);
