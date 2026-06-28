import '../models/countdown.dart';
import 'home_widget_service.dart';
import 'notification_service.dart';

class CountdownPlatformSync {
  CountdownPlatformSync._();

  static Future<void> initialize() async {
    await NotificationService.instance.initialize();
    await HomeWidgetService.instance.initialize();
  }

  static Future<void> sync(List<Countdown> countdowns) async {
    await Future.wait([
      NotificationService.instance.syncCountdowns(countdowns),
      HomeWidgetService.instance.syncCountdowns(countdowns),
    ]);
  }
}
