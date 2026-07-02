import 'package:flutter/material.dart';

/// Conjunto curado de ícones que o usuário pode atribuir a contagens
/// e hábitos. As chaves são persistidas nos modelos.
class AppIcons {
  const AppIcons._();

  static const Map<String, IconData> all = {
    'event': Icons.event_rounded,
    'cake': Icons.cake_rounded,
    'favorite': Icons.favorite_rounded,
    'flight': Icons.flight_rounded,
    'beach': Icons.beach_access_rounded,
    'celebration': Icons.celebration_rounded,
    'school': Icons.school_rounded,
    'work': Icons.work_rounded,
    'home': Icons.home_rounded,
    'star': Icons.star_rounded,
    'gift': Icons.card_giftcard_rounded,
    'music': Icons.music_note_rounded,
    'movie': Icons.movie_rounded,
    'sports': Icons.sports_soccer_rounded,
    'gym': Icons.fitness_center_rounded,
    'run': Icons.directions_run_rounded,
    'book': Icons.menu_book_rounded,
    'meditation': Icons.self_improvement_rounded,
    'nosmoking': Icons.smoke_free_rounded,
    'nodrink': Icons.no_drinks_rounded,
    'nosugar': Icons.cookie_rounded,
    'water': Icons.water_drop_rounded,
    'sleep': Icons.bedtime_rounded,
    'money': Icons.savings_rounded,
    'health': Icons.monitor_heart_rounded,
    'baby': Icons.child_friendly_rounded,
    'pet': Icons.pets_rounded,
    'car': Icons.directions_car_rounded,
    'game': Icons.sports_esports_rounded,
    'code': Icons.code_rounded,
    'camera': Icons.photo_camera_rounded,
    'nature': Icons.park_rounded,
    'sun': Icons.wb_sunny_rounded,
    'moon': Icons.nightlight_round,
    'spark': Icons.auto_awesome_rounded,
    'flag': Icons.flag_rounded,
    'rocket': Icons.rocket_launch_rounded,
    'timer': Icons.hourglass_bottom_rounded,
  };

  static IconData resolve(String name) => all[name] ?? Icons.event_rounded;
}
