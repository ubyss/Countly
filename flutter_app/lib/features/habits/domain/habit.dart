import 'package:flutter/painting.dart';
import 'package:uuid/uuid.dart';

import 'habit_event.dart';
import 'habit_kind.dart';

/// Rastreador de hábito unificado — suporta 4 tipos via [kind].
class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.kind,
    required this.createdAt,
    this.notes = '',
    this.category,
    this.iconName = 'spark',
    this.accentColor = 0xFF19A45B,
    this.archived = false,
    this.startAt,
    this.dailyGoal = 1,
    this.unitLabel = '',
    this.activeSession,
    this.events = const [],
  });

  final String id;
  final String title;
  final String notes;
  final HabitKind kind;
  final String? category;
  final DateTime createdAt;
  final String iconName;
  final int accentColor;
  final bool archived;

  /// Time tracker: data/hora de início do período atual.
  final DateTime? startAt;

  /// Quantidade: meta diária e rótulo da unidade.
  final int dailyGoal;
  final String unitLabel;

  /// Sessão: cronômetro ativo persistido.
  final ActiveSession? activeSession;

  /// Histórico de eventos para estatísticas e heatmap.
  final List<HabitEvent> events;

  Color get accent => Color(accentColor);

  bool get hasActiveSession => activeSession != null;

  Habit copyWith({
    String? title,
    String? notes,
    HabitKind? kind,
    String? category,
    bool clearCategory = false,
    String? iconName,
    int? accentColor,
    bool? archived,
    DateTime? startAt,
    bool clearStartAt = false,
    int? dailyGoal,
    String? unitLabel,
    ActiveSession? activeSession,
    bool clearActiveSession = false,
    List<HabitEvent>? events,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      kind: kind ?? this.kind,
      category: clearCategory ? null : (category ?? this.category),
      createdAt: createdAt,
      iconName: iconName ?? this.iconName,
      accentColor: accentColor ?? this.accentColor,
      archived: archived ?? this.archived,
      startAt: clearStartAt ? null : (startAt ?? this.startAt),
      dailyGoal: dailyGoal ?? this.dailyGoal,
      unitLabel: unitLabel ?? this.unitLabel,
      activeSession:
          clearActiveSession ? null : (activeSession ?? this.activeSession),
      events: events ?? this.events,
    );
  }

  Habit withEvent(HabitEvent event) => copyWith(events: [...events, event]);

  factory Habit.create({
    required String title,
    required HabitKind kind,
    String notes = '',
    String? category,
    String iconName = 'spark',
    int accentColor = 0xFF19A45B,
    DateTime? startAt,
    int dailyGoal = 1,
    String unitLabel = '',
  }) {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final events = <HabitEvent>[];

    if (kind == HabitKind.timeTracker && startAt != null) {
      events.add(HabitEvent.create(type: HabitEventType.trackerStarted, at: startAt));
    }

    return Habit(
      id: id,
      title: title,
      kind: kind,
      notes: notes,
      category: category,
      createdAt: now,
      iconName: iconName,
      accentColor: accentColor,
      startAt: kind == HabitKind.timeTracker ? startAt : null,
      dailyGoal: dailyGoal,
      unitLabel: unitLabel,
      events: events,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind.name,
        if (notes.isNotEmpty) 'notes': notes,
        if (category != null) 'category': category,
        'createdAt': createdAt.toIso8601String(),
        'iconName': iconName,
        'accentColor': accentColor,
        if (archived) 'archived': true,
        if (startAt != null) 'startAt': startAt!.toIso8601String(),
        if (dailyGoal != 1) 'dailyGoal': dailyGoal,
        if (unitLabel.isNotEmpty) 'unitLabel': unitLabel,
        if (activeSession != null) 'activeSession': activeSession!.toJson(),
        if (events.isNotEmpty)
          'events': events.map((event) => event.toJson()).toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      kind: HabitKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => HabitKind.simple,
      ),
      notes: json['notes'] as String? ?? '',
      category: json['category'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      iconName: json['iconName'] as String? ?? 'spark',
      accentColor: (json['accentColor'] as num?)?.toInt() ?? 0xFF19A45B,
      archived: json['archived'] as bool? ?? false,
      startAt: DateTime.tryParse(json['startAt'] as String? ?? ''),
      dailyGoal: (json['dailyGoal'] as num?)?.toInt() ?? 1,
      unitLabel: json['unitLabel'] as String? ?? '',
      activeSession: json['activeSession'] != null
          ? ActiveSession.fromJson(
              (json['activeSession'] as Map).cast<String, dynamic>(),
            )
          : null,
      events: (json['events'] as List?)
              ?.map((item) =>
                  HabitEvent.fromJson((item as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
    );
  }
}
