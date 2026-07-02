import 'package:uuid/uuid.dart';

/// Tipos de evento registrados no histórico de um hábito.
enum HabitEventType {
  trackerStarted,
  trackerPaused,
  trackerResumed,
  trackerReset,
  sessionStarted,
  sessionPaused,
  sessionResumed,
  sessionCompleted,
  quantityLog,
  simpleCompleted,
}

/// Evento imutável no histórico — base para estatísticas e heatmap.
class HabitEvent {
  const HabitEvent({
    required this.id,
    required this.type,
    required this.at,
    this.value,
  });

  final String id;
  final HabitEventType type;
  final DateTime at;

  /// Segundos (sessão) ou delta de quantidade (+/-).
  final int? value;

  factory HabitEvent.create({
    required HabitEventType type,
    DateTime? at,
    int? value,
  }) {
    return HabitEvent(
      id: const Uuid().v4(),
      type: type,
      at: at ?? DateTime.now(),
      value: value,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'at': at.toIso8601String(),
        if (value != null) 'value': value,
      };

  factory HabitEvent.fromJson(Map<String, dynamic> json) {
    return HabitEvent(
      id: json['id'] as String,
      type: HabitEventType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => HabitEventType.simpleCompleted,
      ),
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      value: (json['value'] as num?)?.toInt(),
    );
  }
}

/// Sessão ativa persistida (cronômetro em andamento).
class ActiveSession {
  const ActiveSession({
    required this.startedAt,
    this.pausedAt,
    this.accumulatedSeconds = 0,
  });

  final DateTime startedAt;
  final DateTime? pausedAt;
  final int accumulatedSeconds;

  bool get isPaused => pausedAt != null;
  bool get isRunning => pausedAt == null;

  int elapsedSeconds(DateTime now) {
    if (isPaused) {
      return accumulatedSeconds;
    }
    return accumulatedSeconds + now.difference(startedAt).inSeconds;
  }

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        if (pausedAt != null) 'pausedAt': pausedAt!.toIso8601String(),
        'accumulatedSeconds': accumulatedSeconds,
      };

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      pausedAt: DateTime.tryParse(json['pausedAt'] as String? ?? ''),
      accumulatedSeconds: (json['accumulatedSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  ActiveSession copyWith({
    DateTime? startedAt,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    int? accumulatedSeconds,
  }) {
    return ActiveSession(
      startedAt: startedAt ?? this.startedAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
    );
  }
}
