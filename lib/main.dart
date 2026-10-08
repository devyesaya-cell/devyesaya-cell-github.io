import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/database_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.initialize();

  runApp(
    const ProviderScope(
      child: SpotMonitoringApp(),
    ),
  );
}

class SpotMonitoringApp extends ConsumerWidget {
  const SpotMonitoringApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Spot Monitoring - SCADA Excavator Telemetry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}
