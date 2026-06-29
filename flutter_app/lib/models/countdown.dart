import 'package:flutter/material.dart';

import 'repeat_mode.dart';

class Countdown {
  const Countdown({
    required this.id,
    required this.name,
    required this.targetDate,
    this.repeat = CountlyRepeatMode.none,
    this.imageBase64,
    this.imageAlignment = Alignment.center,
  });

  final String id;
  final String name;
  final String targetDate;
  final CountlyRepeatMode repeat;
  final String? imageBase64;
  final Alignment imageAlignment;

  Countdown copyWith({
    String? id,
    String? name,
    String? targetDate,
    CountlyRepeatMode? repeat,
    String? imageBase64,
    Alignment? imageAlignment,
    bool clearImage = false,
  }) {
    return Countdown(
      id: id ?? this.id,
      name: name ?? this.name,
      targetDate: targetDate ?? this.targetDate,
      repeat: repeat ?? this.repeat,
      imageBase64: clearImage ? null : (imageBase64 ?? this.imageBase64),
      imageAlignment: imageAlignment ?? this.imageAlignment,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetDate': targetDate,
        'repeat': repeat.storageValue,
        if (imageBase64 != null) 'image': imageBase64,
        if (imageAlignment != Alignment.center)
          'imageAlignment': {
            'x': imageAlignment.x,
            'y': imageAlignment.y,
          },
      };

  factory Countdown.fromJson(Map<String, dynamic> json) {
    return Countdown(
      id: json['id'] as String,
      name: json['name'] as String,
      targetDate: json['targetDate'] as String,
      repeat: CountlyRepeatMode.fromString(json['repeat'] as String?),
      imageBase64: json['image'] as String?,
      imageAlignment: _alignmentFromJson(json['imageAlignment']),
    );
  }

  static Alignment _alignmentFromJson(dynamic value) {
    if (value is! Map) {
      return Alignment.center;
    }

    final x = (value['x'] as num?)?.toDouble() ?? 0;
    final y = (value['y'] as num?)?.toDouble() ?? 0;
    return Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
  }
}
