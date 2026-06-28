import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/countdown.dart';
import '../utils/countdown_utils.dart';

const _androidWidgetName = 'com.countly.countly.CountlyWidgetProvider';

class HomeWidgetService {
  HomeWidgetService._();

  static final HomeWidgetService instance = HomeWidgetService._();

  Future<void> initialize() async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    await HomeWidget.setAppGroupId('group.com.countly.countly');
  }

  Future<void> syncCountdowns(List<Countdown> countdowns) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    final now = DateTime.now();
    final next = findNextUpcomingCountdown(countdowns, now);

    if (next == null) {
      await _saveEmptyState();
    } else {
      await _saveCountdownState(next, now);
    }

    await HomeWidget.updateWidget(
      qualifiedAndroidName: _androidWidgetName,
    );
  }

  Future<void> _saveEmptyState() async {
    await HomeWidget.saveWidgetData<bool>('widget_empty', true);
    await HomeWidget.saveWidgetData<String>('widget_next_name', '');
    await HomeWidget.saveWidgetData<String>('widget_next_date_label', '');
    await HomeWidget.saveWidgetData<String>('widget_image_path', '');
    await HomeWidget.saveWidgetData<String>('widget_primary_value', '');
    await HomeWidget.saveWidgetData<String>('widget_primary_label', '');
    await HomeWidget.saveWidgetData<String>('widget_secondary_value', '');
    await HomeWidget.saveWidgetData<String>('widget_secondary_label', '');
    await HomeWidget.saveWidgetData<String>('widget_target_day', '');
    await HomeWidget.saveWidgetData<String>('widget_target_month', '');
  }

  Future<void> _saveCountdownState(Countdown countdown, DateTime now) async {
    final remaining = calculateRemainingTime(countdown.targetDate, now);
    final units = remaining.expired ? <CountdownDisplayUnit>[] : buildCountdownDisplayUnits(remaining);
    final targetDate = isoDateToLocalDate(normalizeTargetDate(countdown.targetDate));
    final imagePath = await _saveWidgetImage(countdown.imageBase64, countdown.id);

    await HomeWidget.saveWidgetData<bool>('widget_empty', false);
    await HomeWidget.saveWidgetData<String>('widget_next_name', countdown.name);
    await HomeWidget.saveWidgetData<String>(
      'widget_next_date_label',
      formatDateLabel(countdown.targetDate),
    );
    await HomeWidget.saveWidgetData<String>('widget_image_path', imagePath ?? '');

    if (units.isEmpty) {
      await HomeWidget.saveWidgetData<String>('widget_primary_value', '00');
      await HomeWidget.saveWidgetData<String>('widget_primary_label', 'DIAS');
      await HomeWidget.saveWidgetData<String>('widget_secondary_value', '');
      await HomeWidget.saveWidgetData<String>('widget_secondary_label', '');
    } else {
      await HomeWidget.saveWidgetData<String>(
        'widget_primary_value',
        padMetric(units.first.value),
      );
      await HomeWidget.saveWidgetData<String>('widget_primary_label', units.first.label);
      if (units.length > 1) {
        await HomeWidget.saveWidgetData<String>(
          'widget_secondary_value',
          padMetric(units[1].value),
        );
        await HomeWidget.saveWidgetData<String>('widget_secondary_label', units[1].label);
      } else {
        await HomeWidget.saveWidgetData<String>('widget_secondary_value', '');
        await HomeWidget.saveWidgetData<String>('widget_secondary_label', '');
      }
    }

    if (targetDate != null) {
      await HomeWidget.saveWidgetData<String>(
        'widget_target_day',
        targetDate.day.toString().padLeft(2, '0'),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_target_month',
        DateFormat('MMM', 'pt_BR').format(targetDate).replaceAll('.', '').toUpperCase(),
      );
    } else {
      await HomeWidget.saveWidgetData<String>('widget_target_day', '--');
      await HomeWidget.saveWidgetData<String>('widget_target_month', '---');
    }
  }

  Future<String?> _saveWidgetImage(String? imageBase64, String countdownId) async {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return null;
    }

    try {
      final bytes = base64Decode(imageBase64);
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 640);
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();

      if (byteData == null) {
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/widget_$countdownId.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
