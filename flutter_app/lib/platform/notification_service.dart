import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../features/counters/domain/counter.dart';
import '../features/counters/domain/counter_snapshot.dart';

const _channelId = 'countly_reminders';
const _channelName = 'Lembretes de contagem';
const _channelDescription = 'Avisos quando um evento está próximo';

/// Agenda lembretes locais (7 dias e 1 dia antes, às 09:00) para as
/// contagens ativas com data alvo, respeitando recorrência.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (_initialized || !_supported) {
      return;
    }

    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  Future<void> syncCounters(List<Counter> counters) async {
    if (!_initialized || !_supported) {
      return;
    }

    await _plugin.cancelAll();

    final now = DateTime.now();
    for (final counter in counters) {
      if (counter.archived) {
        continue;
      }
      await _scheduleForCounter(counter, now);
    }
  }

  Future<void> _scheduleForCounter(Counter counter, DateTime now) async {
    final snapshot = CounterSnapshot.of(counter, now);
    final eventDate = snapshot.eventDate;
    if (eventDate == null || !snapshot.isCountdown) {
      return;
    }

    await _scheduleReminder(
      counter: counter,
      eventDate: eventDate,
      daysBefore: 7,
      title: 'Faltam 7 dias',
      body: 'Faltam 7 dias para ${counter.title}',
      now: now,
    );

    await _scheduleReminder(
      counter: counter,
      eventDate: eventDate,
      daysBefore: 1,
      title: 'Amanhã chega o dia',
      body: 'Falta 1 dia para ${counter.title}',
      now: now,
    );
  }

  Future<void> _scheduleReminder({
    required Counter counter,
    required DateTime eventDate,
    required int daysBefore,
    required String title,
    required String body,
    required DateTime now,
  }) async {
    final scheduledDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day - daysBefore,
      9,
    );
    if (!scheduledDate.isAfter(now)) {
      return;
    }

    await _plugin.zonedSchedule(
      id: Object.hash(counter.id, daysBefore) & 0x7FFFFFFF,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      payload: counter.id,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
