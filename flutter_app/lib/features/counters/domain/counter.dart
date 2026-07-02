import 'package:flutter/painting.dart';

import '../../../core/utils/date_utils.dart';
import 'recurrence.dart';

/// Uma contagem criada pelo usuário.
///
/// - Com [targetDate] futura: contagem regressiva.
/// - Com [targetDate] passada e recorrência: conta para a próxima ocorrência.
/// - Com [targetDate] passada sem recorrência: conta o tempo decorrido.
/// - Sem [targetDate]: conta os dias desde a criação.
class Counter {
  const Counter({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description = '',
    this.notes = '',
    this.targetDate,
    this.recurrence = Recurrence.none,
    this.imageBase64,
    this.imageAlignment = Alignment.center,
    this.iconName = 'event',
    this.accentColor = 0xFF5551E8,
    this.tags = const [],
    this.archived = false,
    this.favorite = false,
  });

  final String id;
  final String title;
  final String description;
  final String notes;
  final DateTime createdAt;

  /// Data alvo em ISO `yyyy-MM-dd`; nula para contagens de "dias desde".
  final String? targetDate;
  final Recurrence recurrence;
  final String? imageBase64;
  final Alignment imageAlignment;
  final String iconName;
  final int accentColor;
  final List<String> tags;
  final bool archived;
  final bool favorite;

  Color get accent => Color(accentColor);

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;

  DateTime? get targetLocalDate =>
      targetDate == null ? null : isoToLocalDate(targetDate!);

  Counter copyWith({
    String? title,
    String? description,
    String? notes,
    DateTime? createdAt,
    String? targetDate,
    bool clearTargetDate = false,
    Recurrence? recurrence,
    String? imageBase64,
    bool clearImage = false,
    Alignment? imageAlignment,
    String? iconName,
    int? accentColor,
    List<String>? tags,
    bool? archived,
    bool? favorite,
  }) {
    return Counter(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      recurrence: recurrence ?? this.recurrence,
      imageBase64: clearImage ? null : (imageBase64 ?? this.imageBase64),
      imageAlignment: imageAlignment ?? this.imageAlignment,
      iconName: iconName ?? this.iconName,
      accentColor: accentColor ?? this.accentColor,
      tags: tags ?? this.tags,
      archived: archived ?? this.archived,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description.isNotEmpty) 'description': description,
        if (notes.isNotEmpty) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        if (targetDate != null) 'targetDate': targetDate,
        if (recurrence.repeats) 'recurrence': recurrence.toJson(),
        if (imageBase64 != null) 'image': imageBase64,
        if (imageAlignment != Alignment.center)
          'imageAlignment': {'x': imageAlignment.x, 'y': imageAlignment.y},
        'iconName': iconName,
        'accentColor': accentColor,
        if (tags.isNotEmpty) 'tags': tags,
        if (archived) 'archived': true,
        if (favorite) 'favorite': true,
      };

  factory Counter.fromJson(Map<String, dynamic> json) {
    return Counter(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      targetDate: _readTargetDate(json['targetDate']),
      recurrence: Recurrence.fromJson(
        (json['recurrence'] as Map?)?.cast<String, dynamic>(),
      ),
      imageBase64: json['image'] as String?,
      imageAlignment: _alignmentFromJson(json['imageAlignment']),
      iconName: json['iconName'] as String? ?? 'event',
      accentColor: (json['accentColor'] as num?)?.toInt() ?? 0xFF5551E8,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      archived: json['archived'] as bool? ?? false,
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  /// Converte um registro legado (modelo `Countdown` v3).
  factory Counter.fromLegacyJson(Map<String, dynamic> json) {
    final targetDate = normalizeIsoDate(json['targetDate']);
    return Counter(
      id: json['id'] as String,
      title: json['name'] as String? ?? '',
      createdAt: DateTime.now(),
      targetDate: targetDate.isEmpty ? null : targetDate,
      recurrence: Recurrence.fromLegacy(json['repeat'] as String?),
      imageBase64: json['image'] as String?,
      imageAlignment: _alignmentFromJson(json['imageAlignment']),
    );
  }

  static String? _readTargetDate(dynamic value) {
    final normalized = normalizeIsoDate(value);
    return normalized.isEmpty ? null : normalized;
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
