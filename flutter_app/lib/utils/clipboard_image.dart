import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

const _androidClipboardChannel = MethodChannel('com.countly.countly/clipboard');

Future<Uint8List?> readClipboardImageBytes() async {
  if (kIsWeb) {
    return Pasteboard.image;
  }

  if (Platform.isAndroid) {
    final bytes = await _androidClipboardChannel.invokeMethod<Object>('getImage');
    if (bytes is Uint8List) {
      return bytes;
    }
    return null;
  }

  return Pasteboard.image;
}
