import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

import 'core/app_theme.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1180, 780),
      minimumSize: Size(900, 640),
      center: true,
      backgroundColor: Color(0xFFF4F7F5),
      title: 'CalorieRecord · 能量收支',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const ProviderScope(child: EnergyBalanceApp()));
}

class EnergyBalanceApp extends StatelessWidget {
  const EnergyBalanceApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CalorieRecord · 能量收支',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const AppShell(),
  );
}
