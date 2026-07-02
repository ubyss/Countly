/// Marcos de conquista das sequências de hábitos.
class Milestone {
  const Milestone({
    required this.days,
    required this.title,
    required this.emoji,
  });

  final int days;
  final String title;
  final String emoji;

  static const all = <Milestone>[
    Milestone(days: 1, title: 'Primeiro dia', emoji: '🌱'),
    Milestone(days: 3, title: '3 dias', emoji: '✨'),
    Milestone(days: 7, title: '1 semana', emoji: '🔥'),
    Milestone(days: 14, title: '2 semanas', emoji: '💪'),
    Milestone(days: 30, title: '1 mês', emoji: '🏅'),
    Milestone(days: 60, title: '2 meses', emoji: '🚀'),
    Milestone(days: 90, title: '3 meses', emoji: '💎'),
    Milestone(days: 180, title: '6 meses', emoji: '🌟'),
    Milestone(days: 365, title: '1 ano', emoji: '👑'),
    Milestone(days: 730, title: '2 anos', emoji: '🏆'),
  ];

  /// Próximo marco a ser alcançado a partir de uma sequência em dias.
  static Milestone? nextFor(int streakDays) {
    for (final milestone in all) {
      if (streakDays < milestone.days) {
        return milestone;
      }
    }
    return null;
  }

  /// Progresso (0..1) da sequência atual em direção ao próximo marco.
  static double progressFor(int streakDays) {
    final next = nextFor(streakDays);
    if (next == null) {
      return 1;
    }
    Milestone? previous;
    for (final milestone in all) {
      if (milestone.days <= streakDays) {
        previous = milestone;
      }
    }
    final base = previous?.days ?? 0;
    final range = next.days - base;
    if (range <= 0) {
      return 1;
    }
    return ((streakDays - base) / range).clamp(0.0, 1.0);
  }
}
