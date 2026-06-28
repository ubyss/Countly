import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app.dart';
import 'services/countdown_platform_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await LiquidGlassWidgets.initialize();
  await CountdownPlatformSync.initialize();
  runApp(
    LiquidGlassWidgets.wrap(
      child: const CountlyApp(),
      theme: GlassThemeData.simple(
        blur: 10,
        thickness: 30,
        quality: GlassQuality.standard,
      ),
    ),
  );
}
