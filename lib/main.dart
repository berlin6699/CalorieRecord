import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_theme.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  runApp(const ProviderScope(child: EnergyBalanceApp()));
}

class EnergyBalanceApp extends StatelessWidget {
  const EnergyBalanceApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '能量收支',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const AppShell(),
  );
}
