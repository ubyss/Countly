import 'package:flutter/material.dart';

/// Tipos de hábito suportados pelo Countly.
enum HabitKind {
  timeTracker,
  session,
  quantity,
  simple,
}

extension HabitKindX on HabitKind {
  String get label {
    switch (this) {
      case HabitKind.timeTracker:
        return 'Time Tracker';
      case HabitKind.session:
        return 'Sessão';
      case HabitKind.quantity:
        return 'Quantidade';
      case HabitKind.simple:
        return 'Simples';
    }
  }

  String get description {
    switch (this) {
      case HabitKind.timeTracker:
        return 'Conta automaticamente desde uma data — casamento, sem fumar...';
      case HabitKind.session:
        return 'Cronômetro para leitura, meditação, estudo...';
      case HabitKind.quantity:
        return 'Meta diária em unidades — copos de água, flexões...';
      case HabitKind.simple:
        return 'Um toque para marcar como feito hoje';
    }
  }

  IconData get icon {
    switch (this) {
      case HabitKind.timeTracker:
        return Icons.hourglass_top_rounded;
      case HabitKind.session:
        return Icons.timer_rounded;
      case HabitKind.quantity:
        return Icons.water_drop_rounded;
      case HabitKind.simple:
        return Icons.check_circle_outline_rounded;
    }
  }
}

/// Categorias opcionais para organização.
class HabitCategories {
  const HabitCategories._();

  static const all = [
    'Saúde',
    'Fitness',
    'Mindfulness',
    'Produtividade',
    'Relacionamento',
    'Estudo',
    'Outro',
  ];
}
