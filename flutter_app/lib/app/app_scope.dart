import 'package:flutter/widgets.dart';

import '../features/counters/application/counters_controller.dart';
import '../features/habits/application/habits_controller.dart';
import '../features/settings/application/settings_controller.dart';
import '../platform/platform_sync.dart';

/// Contêiner de dependências do app.
///
/// Cria os controllers uma única vez e liga as mutações persistidas ao
/// sync de plataforma (widgets nativos + notificações).
class AppDependencies {
  AppDependencies() {
    counters.onPersisted = _syncPlatform;
    habits.onPersisted = _syncPlatform;
  }

  final counters = CountersController();
  final habits = HabitsController();
  final settings = SettingsController();

  Future<void> bootstrap() async {
    await PlatformSync.initialize();
    await settings.load();
    await counters.load(initialViewMode: settings.counterViewMode);
    await habits.load();
    _syncPlatform();
  }

  void _syncPlatform() {
    PlatformSync.sync(counters: counters.all, habits: habits.all);
  }
}

/// Dá acesso às dependências via `AppScope.of(context)`.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado no contexto');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
