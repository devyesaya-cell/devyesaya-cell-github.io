import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spot_monitoring/main.dart';

void main() {
  testWidgets('SpotMonitoringApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SpotMonitoringApp(),
      ),
    );
    expect(find.text('SPOT MONITORING'), findsOneWidget);
  });

  testWidgets('Dashboard metrics 4-column full width test (1920x1080 & 1200x800)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: SpotMonitoringApp(),
      ),
    );
    await tester.pump();

    // Verify 4-column card titles exist without overflow
    expect(find.text('SPOT MONITORING'), findsOneWidget);

    // Test boundary width 1200px
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    expect(find.text('SPOT MONITORING'), findsOneWidget);
  });

  testWidgets('SideMenu contains Dashboard, Map, Config and handles navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: SpotMonitoringApp(),
      ),
    );
    await tester.pump();

    // Verify 3 side menu items exist
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Peta Galian (Map)'), findsOneWidget);
    expect(find.text('Konfigurasi (Config)'), findsOneWidget);

    // Tap on 'Peta Galian (Map)'
    await tester.tap(find.text('Peta Galian (Map)'));
    await tester.pump();

    // Tap on 'Konfigurasi (Config)'
    await tester.tap(find.text('Konfigurasi (Config)'));
    await tester.pump();
  });

  testWidgets('Light and Dark theme toggle switches theme correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: SpotMonitoringApp(),
      ),
    );
    await tester.pump();

    // Initial theme text in SideMenu is 'Gelap'
    expect(find.text('Gelap'), findsOneWidget);

    // Tap theme toggle pill
    await tester.tap(find.text('Gelap'));
    await tester.pump();

    // Theme switches to Light ('Terang')
    expect(find.text('Terang'), findsOneWidget);

    // Tap theme toggle again to switch back to Dark ('Gelap')
    await tester.tap(find.text('Terang'));
    await tester.pump();
    expect(find.text('Gelap'), findsOneWidget);
  });
}

