import '../features/counters/domain/counter.dart';
import '../features/habits/domain/habit.dart';
import 'home_widget_service.dart';
import 'notification_service.dart';

/// Mantém notificações e widgets nativos em dia com o estado do app.
class PlatformSync {
  PlatformSync._();

  static Future<void> initialize() async {
    await NotificationService.instance.initialize();
    await HomeWidgetService.instance.initialize();
  }

  static Future<void> sync({
    required List<Counter> counters,
    required List<Habit> habits,
  }) async {
    await Future.wait([
      NotificationService.instance.syncCounters(counters),
      HomeWidgetService.instance.sync(counters, habits),
    ]);
  }
}
