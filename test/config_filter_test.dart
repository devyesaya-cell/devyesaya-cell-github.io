import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spot_monitoring/core/models/config_model.dart';
import 'package:spot_monitoring/core/models/spot_model.dart';
import 'package:spot_monitoring/features/config/config_page.dart';
import 'package:spot_monitoring/features/spot_provider.dart';

void main() {
  final sampleSpots = [
    Spot(
      id: 1,
      uid: 'spot-1',
      status: 'done',
      latitude: 1.0,
      longitude: 101.0,
      timestamp: DateTime(2026, 9, 25, 10, 0),
      completedAt: DateTime(2026, 9, 25, 10, 0),
      trenchWidthCm: 100.0,
      avgDepthCm: 70.0,
      isLineString: true,
      operatorName: 'Operator A',
    ),
    Spot(
      id: 2,
      uid: 'spot-2',
      status: 'done',
      latitude: 1.01,
      longitude: 101.01,
      timestamp: DateTime(2026, 9, 26, 11, 0),
      completedAt: DateTime(2026, 9, 26, 11, 0),
      trenchWidthCm: 120.0,
      avgDepthCm: 85.0,
      isLineString: true,
      operatorName: 'Operator B',
    ),
    Spot(
      id: 3,
      uid: 'spot-3',
      status: 'done',
      latitude: 1.02,
      longitude: 101.02,
      timestamp: DateTime(2026, 9, 27, 12, 0),
      completedAt: DateTime(2026, 9, 27, 12, 0),
      trenchWidthCm: 90.0,
      avgDepthCm: 60.0,
      isLineString: true,
      operatorName: 'Operator C',
    ),
  ];

  testWidgets('ConfigPage displays filter buttons for Date, Lebar, and Depth',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          datasetProvider.overrideWith(
            () => _MockDatasetNotifier(
              SpotDatasetState(
                isLoading: false,
                datasetName: 'TestDataset',
                spots: sampleSpots,
                isCrumbling: true,
              ),
            ),
          ),
          configProvider.overrideWith(() => _MockConfigNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConfigPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify filter buttons exist
    expect(find.text('Filter Tanggal'), findsOneWidget);
    expect(find.text('Filter Lebar'), findsOneWidget);
    expect(find.text('Filter Kedalaman'), findsOneWidget);

    // Verify all 3 spots are displayed initially
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);
  });

  testWidgets('ConfigPage opening Date Filter Dialog shows options and quick dates',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          datasetProvider.overrideWith(
            () => _MockDatasetNotifier(
              SpotDatasetState(
                isLoading: false,
                datasetName: 'TestDataset',
                spots: sampleSpots,
                isCrumbling: true,
              ),
            ),
          ),
          configProvider.overrideWith(() => _MockConfigNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConfigPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Filter Tanggal' button
    await tester.tap(find.text('Filter Tanggal'));
    await tester.pumpAndSettle();

    // Verify Dialog opened
    expect(find.text('Filter Tanggal Pekerjaan'), findsOneWidget);
    expect(find.text('Pilih Satu Tanggal (Single Date)'), findsOneWidget);
    expect(find.text('Pilih Rentang Tanggal (Date Range)'), findsOneWidget);
    expect(find.text('PILIHAN CEPAT DARI DATASET:'), findsOneWidget);

    // Pick 26 Sep 2026 quick chip
    await tester.tap(find.text('26 Sep 2026'));
    await tester.pumpAndSettle();

    // Dialog should be closed, filter badge should be active
    expect(find.text('Filter Aktif: '), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('#1'), findsNothing);
    expect(find.text('#3'), findsNothing);

    // Reset All
    await tester.tap(find.text('Hapus Semua'));
    await tester.pumpAndSettle();

    // All spots visible again
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);
  });

  testWidgets('ConfigPage Lebar filter dialog and preset works correctly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          datasetProvider.overrideWith(
            () => _MockDatasetNotifier(
              SpotDatasetState(
                isLoading: false,
                datasetName: 'TestDataset',
                spots: sampleSpots,
                isCrumbling: true,
              ),
            ),
          ),
          configProvider.overrideWith(() => _MockConfigNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConfigPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Filter Lebar'
    await tester.tap(find.text('Filter Lebar'));
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Filter Rentang Lebar Parit (Trench Width)'), findsOneWidget);
    expect(find.text('Overwidth (> 110 cm)'), findsOneWidget);

    // Tap 'Overwidth (> 110 cm)' preset
    await tester.tap(find.text('Overwidth (> 110 cm)'));
    await tester.pump();

    // Tap 'Terapkan Filter'
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    // Only Spot #2 (width 120cm) should match
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('#1'), findsNothing);
    expect(find.text('#3'), findsNothing);
  });

  testWidgets('ConfigPage Depth filter dialog and preset works correctly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          datasetProvider.overrideWith(
            () => _MockDatasetNotifier(
              SpotDatasetState(
                isLoading: false,
                datasetName: 'TestDataset',
                spots: sampleSpots,
                isCrumbling: true,
              ),
            ),
          ),
          configProvider.overrideWith(() => _MockConfigNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConfigPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Filter Kedalaman'
    await tester.tap(find.text('Filter Kedalaman'));
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Filter Rentang Kedalaman Crumbling'), findsOneWidget);

    // Target is 70cm +-10% (63 to 77cm). Spot #1 has 70cm.
    expect(find.text('🟢 Ideal QC (63 - 77 cm)'), findsOneWidget);

    // Tap Ideal QC preset
    await tester.tap(find.text('🟢 Ideal QC (63 - 77 cm)'));
    await tester.pump();

    // Tap 'Terapkan Filter'
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    // Only Spot #1 (depth 70.0cm) should match
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsNothing);
    expect(find.text('#3'), findsNothing);
  });
}

class _MockDatasetNotifier extends DatasetNotifier {
  final SpotDatasetState _initial;
  _MockDatasetNotifier(this._initial);

  @override
  SpotDatasetState build() => _initial;
}

class _MockConfigNotifier extends ConfigNotifier {
  @override
  SpotConfig build() => const SpotConfig(
        targetDepthCm: 70.0,
        maxTrenchWidthCm: 110.0,
        depthTolerancePercent: 10.0,
      );
}
