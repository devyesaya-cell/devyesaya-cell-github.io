import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/config_model.dart';
import '../core/models/spot_model.dart';
import '../core/models/summary_model.dart';
import '../core/services/database_service.dart';
import '../core/utils/calculation_engine.dart';
import '../core/utils/geojson_parser.dart';

// --- Models for State ---

enum MapColoringMode {
  qcFourQuadrant, // Default: 4-Quadrant QC (Green / Blue / Yellow / Red)
  progressStatus, // Progress (Green Done / Orange In-Progress / Grey Pending)
  depthHeatmap, // Depth compliance/variance
  deviationHeatmap, // Lateral deviation from axis
}

class SpotDatasetState {
  final bool isLoading;
  final String? loadingMessage;
  final String? datasetName;
  final List<Spot> spots;
  final bool isCrumbling;
  final String? error;
  final DateTime? lastLoadedAt;

  const SpotDatasetState({
    this.isLoading = false,
    this.loadingMessage,
    this.datasetName,
    this.spots = const [],
    this.isCrumbling = false,
    this.error,
    this.lastLoadedAt,
  });

  SpotDatasetState copyWith({
    bool? isLoading,
    String? loadingMessage,
    String? datasetName,
    List<Spot>? spots,
    bool? isCrumbling,
    String? error,
    DateTime? lastLoadedAt,
  }) {
    return SpotDatasetState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage,
      datasetName: datasetName ?? this.datasetName,
      spots: spots ?? this.spots,
      isCrumbling: isCrumbling ?? this.isCrumbling,
      error: error,
      lastLoadedAt: lastLoadedAt ?? this.lastLoadedAt,
    );
  }
}

class SpotFilter {
  final String status; // 'all' | 'done' | 'in_progress' | 'pending' | 'ideal' | 'overwidth' | 'depth_out' | 'fail_both'
  final String? operatorId;
  final String? date;
  final String searchQuery;

  const SpotFilter({
    this.status = 'all',
    this.operatorId,
    this.date,
    this.searchQuery = '',
  });

  SpotFilter copyWith({
    String? status,
    String? operatorId,
    bool clearOperator = false,
    String? date,
    bool clearDate = false,
    String? searchQuery,
  }) {
    return SpotFilter(
      status: status ?? this.status,
      operatorId: clearOperator ? null : (operatorId ?? this.operatorId),
      date: clearDate ? null : (date ?? this.date),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// --- Notifiers ---

class MapColoringNotifier extends Notifier<MapColoringMode> {
  @override
  MapColoringMode build() => MapColoringMode.qcFourQuadrant;

  void setMode(MapColoringMode mode) => state = mode;
}

class ConfigNotifier extends Notifier<SpotConfig> {
  @override
  SpotConfig build() {
    return DatabaseService.loadConfig();
  }

  Future<void> updateConfig(SpotConfig newConfig) async {
    state = newConfig;
    await DatabaseService.saveConfig(newConfig);
  }
}

class FilterNotifier extends Notifier<SpotFilter> {
  @override
  SpotFilter build() => const SpotFilter();

  void setStatus(String status) => state = state.copyWith(status: status);
  void setOperator(String? op) {
    if (op == null || op == 'all') {
      state = state.copyWith(clearOperator: true);
    } else {
      state = state.copyWith(operatorId: op);
    }
  }

  void setDate(String? d) {
    if (d == null || d == 'all') {
      state = state.copyWith(clearDate: true);
    } else {
      state = state.copyWith(date: d);
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void reset() => state = const SpotFilter();
}

class SelectedSpotNotifier extends Notifier<Spot?> {
  @override
  Spot? build() => null;

  void select(Spot? spot) => state = spot;
}

class DatasetNotifier extends Notifier<SpotDatasetState> {
  @override
  SpotDatasetState build() {
    // Initial fetch trigger
    Future.microtask(() => loadInitialData());
    return const SpotDatasetState(isLoading: true, loadingMessage: 'Memuat data lokal...');
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, loadingMessage: 'Memeriksa database lokal...');
    try {
      final savedSpots = await DatabaseService.loadDataset();
      final name = DatabaseService.getDatasetName();

      if (savedSpots != null && savedSpots.isNotEmpty) {
        final bool isCrumbling = savedSpots.any((s) => s.isLineString) ||
            (name != null && name.toLowerCase().contains('crumbling'));

        state = state.copyWith(
          isLoading: false,
          loadingMessage: null,
          datasetName: name ?? 'Tersimpan di Lokal',
          spots: savedSpots,
          isCrumbling: isCrumbling,
          lastLoadedAt: DateTime.now(),
        );
      } else {
        // Automatically load bundled sample dataset for immediate experience
        await loadSampleGeoJson();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data awal: $e',
      );
    }
  }

  Future<void> loadSampleGeoJson() async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Memuat data sampel SBAE035803.geojson...',
      error: null,
    );

    try {
      final jsonString = await rootBundle.loadString('assets/data/SBAE035803.geojson');
      final result = GeoJsonParser.parseString(jsonString, defaultName: 'SBAE035803');

      await DatabaseService.saveDataset(
        name: result.name,
        spots: result.spots,
      );

      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        datasetName: result.name,
        spots: result.spots,
        isCrumbling: result.isCrumbling,
        lastLoadedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat sampel GeoJSON: $e',
      );
    }
  }

  Future<void> loadSampleCrumblingGeoJson() async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Memuat data sampel Crumbling Badak Culah...',
      error: null,
    );

    try {
      final jsonString = await rootBundle
          .loadString('assets/data/crumbling_results_Area1_Badak_Culah_20261007_170409.geojson');
      final result = GeoJsonParser.parseString(
        jsonString,
        defaultName: 'Crumbling_Area1_Badak_Culah',
      );

      await DatabaseService.saveDataset(
        name: result.name,
        spots: result.spots,
      );

      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        datasetName: result.name,
        spots: result.spots,
        isCrumbling: true,
        lastLoadedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat sampel crumbling: $e',
      );
    }
  }

  Future<void> importBytes(Uint8List bytes, String fileName) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage:
          'Memproses $fileName (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB)...',
      error: null,
    );

    try {
      final defaultName =
          fileName.replaceAll(RegExp(r'\.geojson|\.json', caseSensitive: false), '');
      final result = GeoJsonParser.parseBytes(bytes, defaultName: defaultName);

      if (result.spots.isEmpty) {
        throw const FormatException('Tidak ada titik/segmen galian valid yang ditemukan dalam file.');
      }

      await DatabaseService.saveDataset(
        name: result.name,
        spots: result.spots,
      );

      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        datasetName: result.name,
        spots: result.spots,
        isCrumbling: result.isCrumbling,
        lastLoadedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal mengimpor file: $e',
      );
      rethrow;
    }
  }

  Future<void> clearAll() async {
    state = state.copyWith(isLoading: true, loadingMessage: 'Menghapus data...');
    await DatabaseService.clearAll();
    state = const SpotDatasetState(
      isLoading: false,
      datasetName: null,
      spots: [],
      isCrumbling: false,
    );
  }
}

// --- Provider Instances ---

final mapColoringProvider =
    NotifierProvider<MapColoringNotifier, MapColoringMode>(MapColoringNotifier.new);

final configProvider = NotifierProvider<ConfigNotifier, SpotConfig>(ConfigNotifier.new);

final filterProvider = NotifierProvider<FilterNotifier, SpotFilter>(FilterNotifier.new);

final selectedSpotProvider =
    NotifierProvider<SelectedSpotNotifier, Spot?>(SelectedSpotNotifier.new);

final datasetProvider = NotifierProvider<DatasetNotifier, SpotDatasetState>(DatasetNotifier.new);

final filteredSpotsProvider = Provider<List<Spot>>((ref) {
  final dataset = ref.watch(datasetProvider);
  final filter = ref.watch(filterProvider);
  final config = ref.watch(configProvider);

  if (dataset.spots.isEmpty) return [];

  return dataset.spots.where((spot) {
    // Status filter
    if (filter.status != 'all') {
      if (filter.status == 'done' && !spot.isDone) return false;
      if (filter.status == 'in_progress' && !spot.isInProgress) return false;
      if (filter.status == 'pending' && !spot.isPending) return false;

      // QC Filters for Crumbling
      if (dataset.isCrumbling) {
        final qc = spot.evaluateQC(
          targetDepthCm: config.targetDepthCm,
          maxWidthCm: config.maxTrenchWidthCm,
          tolerancePercent: config.depthTolerancePercent,
        );
        if (filter.status == 'ideal' && qc != CrumblingQCStatus.idealPass) return false;
        if (filter.status == 'overwidth' && qc != CrumblingQCStatus.overwidth) return false;
        if (filter.status == 'depth_out' && qc != CrumblingQCStatus.depthOutOfSpec) return false;
        if (filter.status == 'fail_both' && qc != CrumblingQCStatus.failBoth) return false;
      }
    }

    // Operator filter
    if (filter.operatorId != null && filter.operatorId!.isNotEmpty) {
      final op = spot.operatorId ?? 'Unassigned';
      if (op != filter.operatorId) return false;
    }

    // Date filter
    if (filter.date != null && filter.date!.isNotEmpty) {
      if (spot.timestamp == null) return false;
      final spotDate = spot.timestamp!.toIso8601String().substring(0, 10);
      if (spotDate != filter.date) return false;
    }

    // Search query (id or uid or point_index or spot_id)
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchId = spot.id.toString().contains(q);
      final matchUid = spot.uid.toLowerCase().contains(q);
      final matchPoint = spot.pointIndex?.toString().contains(q) ?? false;
      final matchSpotId = spot.spotId?.toString().contains(q) ?? false;
      if (!matchId && !matchUid && !matchPoint && !matchSpotId) return false;
    }

    return true;
  }).toList();
});

final summaryProvider = Provider<SpotSummary>((ref) {
  final spots = ref.watch(filteredSpotsProvider);
  final config = ref.watch(configProvider);
  return CalculationEngine.calculate(spots: spots, config: config);
});

// Full unfiltered summary (for global stats on header / config)
final globalSummaryProvider = Provider<SpotSummary>((ref) {
  final dataset = ref.watch(datasetProvider);
  final config = ref.watch(configProvider);
  return CalculationEngine.calculate(spots: dataset.spots, config: config);
});
