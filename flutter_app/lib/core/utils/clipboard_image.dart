import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

const _androidClipboardChannel =
    MethodChannel('com.countly.countly/clipboard');

/// Lê uma imagem da área de transferência.
///
/// No Android usa um canal nativo (a API de clipboard de imagens não é
/// coberta pelo `pasteboard`); nas demais plataformas usa o plugin.
Future<Uint8List?> readClipboardImageBytes() async {
  if (kIsWeb) {
    return Pasteboard.image;
  }

  if (Platform.isAndroid) {
    final bytes =
        await _androidClipboardChannel.invokeMethod<Object>('getImage');
    return bytes is Uint8List ? bytes : null;
  }

  return Pasteboard.image;
}
