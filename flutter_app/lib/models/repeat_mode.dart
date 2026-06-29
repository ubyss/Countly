enum CountlyRepeatMode {
  none,
  yearly,
  weekly,
  monthly;

  String get label => switch (this) {
        CountlyRepeatMode.none => 'Não',
        CountlyRepeatMode.yearly => 'Ano.',
        CountlyRepeatMode.weekly => 'Sem.',
        CountlyRepeatMode.monthly => 'Men.',
      };

  String get displayLabel => switch (this) {
        CountlyRepeatMode.none => 'Não',
        CountlyRepeatMode.yearly => 'Anual',
        CountlyRepeatMode.weekly => 'Semanal',
        CountlyRepeatMode.monthly => 'Mensal',
      };

  String get storageValue => name;

  static CountlyRepeatMode fromString(String? value) {
    if (value == 'daily') {
      return CountlyRepeatMode.yearly;
    }

    return CountlyRepeatMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => CountlyRepeatMode.none,
    );
  }
}
