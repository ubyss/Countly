enum CountlyRepeatMode {
  none,
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
        CountlyRepeatMode.none => 'Não',
        CountlyRepeatMode.daily => 'Dia.',
        CountlyRepeatMode.weekly => 'Sem.',
        CountlyRepeatMode.monthly => 'Men.',
      };

  String get storageValue => name;

  static CountlyRepeatMode fromString(String? value) {
    return CountlyRepeatMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => CountlyRepeatMode.none,
    );
  }
}
