import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/countdown.dart';
import '../utils/countdown_utils.dart';

const _channelId = 'countly_reminders';
const _channelName = 'Lembretes de contagem';
const _channelDescription = 'Avisos quando um evento está próximo';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    tz_data.initializeTimeZones();
    if (!Platform.isWindows) {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  Future<void> syncCountdowns(List<Countdown> countdowns) async {
    if (!_initialized || kIsWeb) {
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    await _plugin.cancelAll();

    final now = DateTime.now();
    for (final countdown in countdowns) {
      await _scheduleForCountdown(countdown, now);
    }
  }

  Future<void> _scheduleForCountdown(Countdown countdown, DateTime referenceDate) async {
    final remaining = calculateRemainingTime(countdown.targetDate, referenceDate);
    if (remaining.expired) {
      return;
    }

    await _scheduleReminder(
      countdown: countdown,
      daysBefore: 7,
      title: 'Faltam 7 dias',
      body: 'Faltam 7 dias para ${countdown.name}',
      referenceDate: referenceDate,
    );

    await _scheduleReminder(
      countdown: countdown,
      daysBefore: 1,
      title: 'Amanhã chega o dia',
      body: 'Faltam 1 dia para ${countdown.name}',
      referenceDate: referenceDate,
    );
  }

  Future<void> _scheduleReminder({
    required Countdown countdown,
    required int daysBefore,
    required String title,
    required String body,
    required DateTime referenceDate,
  }) async {
    final scheduledDate = _notificationDate(countdown.targetDate, daysBefore);
    if (scheduledDate == null || !scheduledDate.isAfter(referenceDate)) {
      return;
    }

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final notificationId = _notificationId(countdown.id, daysBefore);

    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: tzDate,
      payload: countdown.id,
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

  DateTime? _notificationDate(String targetDate, int daysBefore) {
    final localDate = isoDateToLocalDate(normalizeTargetDate(targetDate));
    if (localDate == null) {
      return null;
    }

    return DateTime(
      localDate.year,
      localDate.month,
      localDate.day - daysBefore,
      9,
      0,
    );
  }

  int _notificationId(String countdownId, int daysBefore) {
    return Object.hash(countdownId, daysBefore) & 0x7FFFFFFF;
  }
}
