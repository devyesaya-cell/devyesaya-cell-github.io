import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maplibre/maplibre.dart';
import '../../core/models/config_model.dart';
import '../../core/models/spot_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badge.dart';
import '../spot_provider.dart';

enum MapTileType {
  satellite,
  cartoDark,
  streets,
}

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  MapController? _mapController;
  MapTileType _tileType = MapTileType.satellite;
  bool _showTrackLine = true;
  String _mapStatusFilter = 'all'; // 'all' | 'done' | 'in_progress' | 'pending' | 'ideal' | 'overwidth' | 'depth_out' | 'fail_both'
  final TextEditingController _searchController = TextEditingController();
  bool _hasFittedInitial = false;

  static const String _esriSatelliteStyle = '''
{
  "version": 8,
  "sources": {
    "esri-satellite": {
      "type": "raster",
      "tiles": [
        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
      ],
      "tileSize": 256
    }
  },
  "layers": [
    {
      "id": "esri-layer",
      "type": "raster",
      "source": "esri-satellite",
      "minzoom": 0,
      "maxzoom": 20
    }
  ]
}''';

  static const String _cartoDarkStyle = '''
{
  "version": 8,
  "sources": {
    "carto-dark": {
      "type": "raster",
      "tiles": [
        "https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png"
      ],
      "tileSize": 256
    }
  },
  "layers": [
    {
      "id": "carto-layer",
      "type": "raster",
      "source": "carto-dark",
      "minzoom": 0,
      "maxzoom": 20
    }
  ]
}''';

  static const String _osmStreetsStyle = '''
{
  "version": 8,
  "sources": {
    "osm-tiles": {
      "type": "raster",
      "tiles": [
        "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
      ],
      "tileSize": 256
    }
  },
  "layers": [
    {
      "id": "osm-layer",
      "type": "raster",
      "source": "osm-tiles",
      "minzoom": 0,
      "maxzoom": 19
    }
  ]
}''';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getStyle(MapTileType type) {
    switch (type) {
      case MapTileType.satellite:
        return _esriSatelliteStyle;
      case MapTileType.cartoDark:
        return _cartoDarkStyle;
      case MapTileType.streets:
        return _osmStreetsStyle;
    }
  }

  void _fitBounds(List<Spot> spots) {
    if (spots.isEmpty || _mapController == null) return;
    try {
      final List<Geographic> points = [];
      for (final s in spots) {
        if (s.isLineString && s.startLongitude != null && s.startLatitude != null) {
          points.add(Geographic(lon: s.startLongitude!, lat: s.startLatitude!));
          if (s.endLongitude != null && s.endLatitude != null) {
            points.add(Geographic(lon: s.endLongitude!, lat: s.endLatitude!));
          }
        } else {
          points.add(Geographic(lon: s.longitude, lat: s.latitude));
        }
      }

      if (points.isEmpty) return;
      final bounds = LngLatBounds.fromPoints(points);
      _mapController!.fitBounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      );
    } catch (e) {
      debugPrint('Error fitBounds: $e');
    }
  }

  void _onMapTapped(Geographic point, List<Spot> spots) {
    if (spots.isEmpty) return;

    Spot? closest;
    double minDistance = double.infinity;

    for (final spot in spots) {
      final dLat = spot.latitude - point.lat;
      final dLng = spot.longitude - point.lon;
      final dist = (dLat * dLat) + (dLng * dLng);

      if (dist < minDistance) {
        minDistance = dist;
        closest = spot;
      }
    }

    // Threshold ~ 0.0001 (~10 meters on ground) for comfortable selection
    if (closest != null && minDistance < 0.0002) {
      ref.read(selectedSpotProvider.notifier).select(closest);
    } else {
      ref.read(selectedSpotProvider.notifier).select(null);
    }
  }

  void _flyToSpot(Spot spot) {
    ref.read(selectedSpotProvider.notifier).select(spot);
    _mapController?.animateCamera(
      center: Geographic(lon: spot.longitude, lat: spot.latitude),
      zoom: 18.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final datasetState = ref.watch(datasetProvider);
    final allSpots = datasetState.spots;
    final selectedSpot = ref.watch(selectedSpotProvider);
    final config = ref.watch(configProvider);
    final isCrumbling = datasetState.isCrumbling;
    final coloringMode = ref.watch(mapColoringProvider);

    if (datasetState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentCyan),
      );
    }

    if (allSpots.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data galian untuk ditampilkan di peta.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Filter spots for map rendering
    final spotsToRender = allSpots.where((s) {
      if (_mapStatusFilter == 'all') return true;
      if (_mapStatusFilter == 'done') return s.isDone;
      if (_mapStatusFilter == 'in_progress') return s.isInProgress;
      if (_mapStatusFilter == 'pending') return s.isPending;

      if (isCrumbling) {
        final qc = s.evaluateQC(
          targetDepthCm: config.targetDepthCm,
          maxWidthCm: config.maxTrenchWidthCm,
          tolerancePercent: config.depthTolerancePercent,
        );
        if (_mapStatusFilter == 'ideal') return qc == CrumblingQCStatus.idealPass;
        if (_mapStatusFilter == 'overwidth') return qc == CrumblingQCStatus.overwidth;
        if (_mapStatusFilter == 'depth_out') return qc == CrumblingQCStatus.depthOutOfSpec;
        if (_mapStatusFilter == 'fail_both') return qc == CrumblingQCStatus.failBoth;
      }
      return true;
    }).toList();

    // Default center
    final centerLat = allSpots.isNotEmpty ? allSpots.first.latitude : 1.0594;
    final centerLng = allSpots.isNotEmpty ? allSpots.first.longitude : 101.5484;

    final List<Layer> layers = [];

    if (isCrumbling) {
      // Build Batched Polyline Layers for Crumbling
      layers.addAll(_buildCrumblingPolylineLayers(
        spotsToRender,
        config,
        coloringMode,
        selectedSpot,
      ));
    } else {
      // Build Circle Layers for Point Spots
      final doneSpots = spotsToRender.where((s) => s.isDone).toList();
      final pendingSpots = spotsToRender.where((s) => s.isPending).toList();

      if (doneSpots.isNotEmpty) {
        layers.add(CircleLayer(
          points: doneSpots
              .map((s) => Feature<Point>(
                    id: s.id,
                    geometry: Point([s.longitude, s.latitude].xy),
                  ))
              .toList(),
          color: AppColors.statusDone,
          radius: 4,
          strokeWidth: 1,
          strokeColor: Colors.black45,
        ));
      }

      if (pendingSpots.isNotEmpty) {
        layers.add(CircleLayer(
          points: pendingSpots
              .map((s) => Feature<Point>(
                    id: s.id,
                    geometry: Point([s.longitude, s.latitude].xy),
                  ))
              .toList(),
          color: AppColors.statusPending,
          radius: 4,
          strokeWidth: 1,
          strokeColor: Colors.black45,
        ));
      }

      if (selectedSpot != null) {
        layers.add(CircleLayer(
          points: [
            Feature<Point>(
              id: selectedSpot.id,
              geometry: Point([selectedSpot.longitude, selectedSpot.latitude].xy),
            ),
          ],
          color: AppColors.accentCyan,
          radius: 8,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ));
      }

      if (_showTrackLine) {
        final trackSpots = allSpots.where((s) => s.isDone && s.timestamp != null).toList()
          ..sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
        if (trackSpots.length >= 2) {
          layers.add(
            PolylineLayer(
              polylines: [
                Feature<LineString>(
                  geometry: LineString(
                    PositionSeries.from(trackSpots.map((s) => [s.longitude, s.latitude].xy)),
                  ),
                ),
              ],
              color: AppColors.accentCyan.withValues(alpha: 0.6),
              width: 2,
            ),
          );
        }
      }
    }

    return Stack(
      children: [
        // MapLibre Map Component
        MapLibreMap(
          options: MapOptions(
            initStyle: _getStyle(_tileType),
            initCenter: Geographic(lon: centerLng, lat: centerLat),
            initZoom: 16.5,
            minZoom: 2.0,
            maxZoom: 20.0,
          ),
          layers: layers,
          onMapCreated: (controller) {
            _mapController = controller;
            if (!_hasFittedInitial && allSpots.isNotEmpty) {
              _hasFittedInitial = true;
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) _fitBounds(allSpots);
              });
            }
          },
          onEvent: (event) {
            if (event is MapEventClick) {
              _onMapTapped(event.point, spotsToRender);
            }
          },
        ),

        // Top Left Controls (Layer Switcher & Filters)
        Positioned(
          top: 20,
          left: 20,
          child: _buildTopMapControls(allSpots, spotsToRender, isCrumbling, coloringMode),
        ),

        // Top Right Map Actions (Fit Bounds)
        Positioned(
          top: 20,
          right: 20,
          child: _buildMapActionButtons(allSpots),
        ),

        // Bottom Left Legend
        Positioned(
          bottom: 20,
          left: 20,
          child: _buildMapLegend(spotsToRender.length, isCrumbling, coloringMode, config),
        ),

        // Bottom Right Spot Inspector Card (When spot is selected)
        if (selectedSpot != null)
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildSpotInspectorCard(selectedSpot, isCrumbling, config),
          ),
      ],
    );
  }

  List<Layer> _buildCrumblingPolylineLayers(
    List<Spot> spots,
    SpotConfig config,
    MapColoringMode coloringMode,
    Spot? selectedSpot,
  ) {
    final Map<Color, List<Feature<LineString>>> colorGroups = {};

    for (final spot in spots) {
      if (!spot.isLineString || spot.startLongitude == null || spot.endLongitude == null) {
        continue;
      }

      final color = _resolveSegmentColor(spot, config, coloringMode);
      final feature = Feature<LineString>(
        id: spot.id,
        geometry: LineString(
          PositionSeries.from([
            [spot.startLongitude!, spot.startLatitude!].xy,
            [spot.endLongitude!, spot.endLatitude!].xy,
          ]),
        ),
      );

      colorGroups.putIfAbsent(color, () => []).add(feature);
    }

    final List<Layer> layers = [];

    // Add layers grouped by color
    colorGroups.forEach((color, polylines) {
      layers.add(PolylineLayer(
        polylines: polylines,
        color: color,
        width: 4,
      ));
    });

    // Add Highlight Layer for selected spot
    if (selectedSpot != null &&
        selectedSpot.isLineString &&
        selectedSpot.startLongitude != null &&
        selectedSpot.endLongitude != null) {
      layers.add(PolylineLayer(
        polylines: [
          Feature<LineString>(
            id: selectedSpot.id,
            geometry: LineString(
              PositionSeries.from([
                [selectedSpot.startLongitude!, selectedSpot.startLatitude!].xy,
                [selectedSpot.endLongitude!, selectedSpot.endLatitude!].xy,
              ]),
            ),
          ),
        ],
        color: AppColors.accentCyan,
        width: 7,
      ));

      layers.add(CircleLayer(
        points: [
          Feature<Point>(
            id: selectedSpot.id,
            geometry: Point([selectedSpot.longitude, selectedSpot.latitude].xy),
          ),
        ],
        color: Colors.white,
        radius: 6,
        strokeWidth: 2,
        strokeColor: AppColors.accentCyan,
      ));
    }

    return layers;
  }

  Color _resolveSegmentColor(Spot spot, SpotConfig config, MapColoringMode mode) {
    if (spot.isSweepPending) {
      return const Color(0xFF64748B); // Slate Grey
    }
    if (spot.isSweepInProgress) {
      return const Color(0xFFFB923C); // Orange
    }

    switch (mode) {
      case MapColoringMode.qcFourQuadrant:
        final qc = spot.evaluateQC(
          targetDepthCm: config.targetDepthCm,
          maxWidthCm: config.maxTrenchWidthCm,
          tolerancePercent: config.depthTolerancePercent,
        );
        switch (qc) {
          case CrumblingQCStatus.idealPass:
            return const Color(0xFF2ECC71); // Green
          case CrumblingQCStatus.overwidth:
            return const Color(0xFF3B82F6); // Blue
          case CrumblingQCStatus.depthOutOfSpec:
            return const Color(0xFFF59E0B); // Amber / Yellow
          case CrumblingQCStatus.failBoth:
            return const Color(0xFFEF4444); // Red
          case CrumblingQCStatus.inProgress:
            return const Color(0xFFFB923C); // Orange
          case CrumblingQCStatus.pending:
            return const Color(0xFF64748B); // Grey
        }

      case MapColoringMode.progressStatus:
        if (spot.isSweepDone) return const Color(0xFF2ECC71);
        if (spot.isSweepInProgress) return const Color(0xFFFB923C);
        return const Color(0xFF64748B);

      case MapColoringMode.depthHeatmap:
        final d = spot.avgDepthCm ?? spot.depth ?? 0.0;
        if (d >= config.minAllowedDepthCm && d <= config.maxAllowedDepthCm) {
          return const Color(0xFF2ECC71); // Ideal Green
        } else if (d < config.minAllowedDepthCm) {
          return const Color(0xFFFB923C); // Shallow Orange
        } else {
          return const Color(0xFFA855F7); // Deep Purple
        }

      case MapColoringMode.deviationHeatmap:
        final dev = spot.avgDeviationCm?.abs() ?? 0.0;
        if (dev <= 10.0) {
          return const Color(0xFF2ECC71); // High Precision Green
        } else if (dev <= 25.0) {
          return const Color(0xFFF59E0B); // Moderate Yellow
        } else {
          return const Color(0xFFEF4444); // High Deviation Red
        }
    }
  }

  Widget _buildTopMapControls(
    List<Spot> allSpots,
    List<Spot> currentSpots,
    bool isCrumbling,
    MapColoringMode coloringMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tile Mode Switcher
              DropdownButtonHideUnderline(
                child: DropdownButton<MapTileType>(
                  value: _tileType,
                  dropdownColor: AppColors.surfaceElevated,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  icon: const Icon(Icons.layers, size: 16, color: AppColors.accentCyan),
                  items: const [
                    DropdownMenuItem(
                      value: MapTileType.satellite,
                      child: Text('🛰️ Citra Satelit (Esri)'),
                    ),
                    DropdownMenuItem(
                      value: MapTileType.cartoDark,
                      child: Text('🌙 SCADA Dark (Carto)'),
                    ),
                    DropdownMenuItem(
                      value: MapTileType.streets,
                      child: Text('🗺️ Peta Jalan (OSM)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _tileType = val);
                      _mapController?.setStyle(_getStyle(val));
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Coloring Mode Switcher (For Crumbling)
              if (isCrumbling) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFB923C).withValues(alpha: 0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MapColoringMode>(
                      value: coloringMode,
                      dropdownColor: AppColors.surfaceElevated,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      icon: const Icon(Icons.palette_outlined, size: 16, color: Color(0xFFFB923C)),
                      items: const [
                        DropdownMenuItem(
                          value: MapColoringMode.qcFourQuadrant,
                          child: Text('🎯 QC 4-Kuadran'),
                        ),
                        DropdownMenuItem(
                          value: MapColoringMode.progressStatus,
                          child: Text('📊 Status Sapuan'),
                        ),
                        DropdownMenuItem(
                          value: MapColoringMode.depthHeatmap,
                          child: Text('⬇️ Heatmap Kedalaman'),
                        ),
                        DropdownMenuItem(
                          value: MapColoringMode.deviationHeatmap,
                          child: Text('📏 Heatmap Presisi As'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(mapColoringProvider.notifier).setMode(val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Status Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _mapStatusFilter,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Semua')),
                      const DropdownMenuItem(value: 'done', child: Text('Done Saja')),
                      if (isCrumbling)
                        const DropdownMenuItem(
                            value: 'in_progress', child: Text('In Progress')),
                      const DropdownMenuItem(value: 'pending', child: Text('Pending Saja')),
                      if (isCrumbling) ...[
                        const DropdownMenuItem(value: 'ideal', child: Text('🟢 Ideal Saja')),
                        const DropdownMenuItem(
                            value: 'overwidth', child: Text('🔵 Overwidth Saja')),
                        const DropdownMenuItem(
                            value: 'depth_out', child: Text('🟡 Kedalaman Out')),
                        const DropdownMenuItem(
                            value: 'fail_both', child: Text('🔴 Gagal Keduanya')),
                      ],
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _mapStatusFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Bar
          SizedBox(
            width: 360,
            height: 36,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: isCrumbling
                    ? 'Cari ID Segmen / Spot ID (contoh: 2660)...'
                    : 'Cari Spot ID / Point Index (contoh: 483)...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.accentCyan),
                  onPressed: () {
                    final query = _searchController.text.trim();
                    if (query.isEmpty) return;
                    final match = allSpots.firstWhere(
                      (s) =>
                          s.id.toString() == query ||
                          s.spotId.toString() == query ||
                          s.pointIndex.toString() == query ||
                          s.uid.contains(query),
                      orElse: () => allSpots.first,
                    );
                    _flyToSpot(match);
                  },
                ),
              ),
              onSubmitted: (query) {
                if (query.trim().isEmpty) return;
                final match = allSpots.firstWhere(
                  (s) =>
                      s.id.toString() == query ||
                      s.spotId.toString() == query ||
                      s.pointIndex.toString() == query ||
                      s.uid.contains(query),
                  orElse: () => allSpots.first,
                );
                _flyToSpot(match);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButtons(List<Spot> allSpots) {
    return Column(
      children: [
        // Fit Bounds
        FloatingActionButton.small(
          heroTag: 'fit_bounds_btn',
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.accentCyan,
          tooltip: 'Pusatkan ke Seluruh Area Galian',
          onPressed: () => _fitBounds(allSpots),
          child: const Icon(Icons.zoom_out_map, size: 18),
        ),
        const SizedBox(height: 8),

        // Toggle Trackline
        FloatingActionButton.small(
          heroTag: 'track_line_btn',
          backgroundColor: _showTrackLine ? AppColors.accentCyan : AppColors.surface,
          foregroundColor: _showTrackLine ? Colors.black : AppColors.textSecondary,
          tooltip: 'Jalur Trajektori Galian (Polyline)',
          onPressed: () => setState(() => _showTrackLine = !_showTrackLine),
          child: const Icon(Icons.timeline, size: 18),
        ),
      ],
    );
  }

  Widget _buildMapLegend(
    int renderedCount,
    bool isCrumbling,
    MapColoringMode coloringMode,
    SpotConfig config,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isCrumbling
                ? 'TAMPIL: $renderedCount SEGMEN CRUMBLING'
                : 'TITIK AKTIF: $renderedCount SPOT',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          if (!isCrumbling)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendDot(AppColors.statusDone, 'Done (Galian Selesai)'),
                const SizedBox(width: 14),
                _buildLegendDot(AppColors.statusPending, 'Pending'),
                const SizedBox(width: 14),
                _buildLegendDot(AppColors.accentCyan, 'Dipilih'),
              ],
            )
          else ...[
            if (coloringMode == MapColoringMode.qcFourQuadrant)
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _buildLegendLine(const Color(0xFF2ECC71), 'Ideal (Kedalaman & Lebar Lolos)'),
                  _buildLegendLine(const Color(0xFF3B82F6), 'Overwidth (>110cm)'),
                  _buildLegendLine(const Color(0xFFF59E0B), 'Kedalaman Out (±10%)'),
                  _buildLegendLine(const Color(0xFFEF4444), 'Gagal Keduanya'),
                  _buildLegendLine(const Color(0xFFFB923C), 'In Progress'),
                  _buildLegendLine(const Color(0xFF64748B), 'Pending'),
                ],
              )
            else if (coloringMode == MapColoringMode.progressStatus)
              Wrap(
                spacing: 12,
                children: [
                  _buildLegendLine(const Color(0xFF2ECC71), 'Selesai (100%)'),
                  _buildLegendLine(const Color(0xFFFB923C), 'Sedang Dikerjakan (20-90%)'),
                  _buildLegendLine(const Color(0xFF64748B), 'Belum Dimulai (0%)'),
                ],
              )
            else if (coloringMode == MapColoringMode.depthHeatmap)
              Wrap(
                spacing: 12,
                children: [
                  _buildLegendLine(
                      const Color(0xFF2ECC71), 'Ideal (${config.minAllowedDepthCm.toStringAsFixed(0)}–${config.maxAllowedDepthCm.toStringAsFixed(0)}cm)'),
                  _buildLegendLine(
                      const Color(0xFFFB923C), 'Dangkal (<${config.minAllowedDepthCm.toStringAsFixed(0)}cm)'),
                  _buildLegendLine(
                      const Color(0xFFA855F7), 'Dalam (>${config.maxAllowedDepthCm.toStringAsFixed(0)}cm)'),
                ],
              )
            else if (coloringMode == MapColoringMode.deviationHeatmap)
              Wrap(
                spacing: 12,
                children: [
                  _buildLegendLine(const Color(0xFF2ECC71), 'Presisi Tinggi (≤10cm)'),
                  _buildLegendLine(const Color(0xFFF59E0B), 'Toleransi Sedang (10–25cm)'),
                  _buildLegendLine(const Color(0xFFEF4444), 'Deviasi Tinggi (>25cm)'),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLegendLine(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSpotInspectorCard(Spot spot, bool isCrumbling, SpotConfig config) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');
    final timeStr = spot.timestamp != null ? dateFormat.format(spot.timestamp!) : '-';

    return Container(
      width: 360,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCrumbling ? const Color(0xFFFB923C) : AppColors.accentCyan,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isCrumbling ? const Color(0xFFFB923C) : AppColors.accentCyan)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isCrumbling ? Icons.alt_route : Icons.place,
                      color: isCrumbling ? const Color(0xFFFB923C) : AppColors.accentCyan,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCrumbling ? 'CRUMBLING #${spot.id}' : 'SPOT #${spot.id}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => ref.read(selectedSpotProvider.notifier).select(null),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status & UID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UID: ${spot.uid}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
              ),
              if (isCrumbling)
                _buildCrumblingQCStatusBadge(spot, config)
              else
                (spot.isDone
                    ? StatusBadge.done(label: 'DONE')
                    : (spot.isPending
                        ? StatusBadge.pending(label: 'PENDING')
                        : StatusBadge(
                            label: spot.status.toUpperCase(),
                            color: AppColors.textSecondary))),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),

          // Details List
          if (isCrumbling) ...[
            _buildInspectorRow(
              'Jalur / Spot ID',
              '#${spot.spotId ?? spot.pointIndex ?? '-'}',
              icon: Icons.tag,
            ),
            _buildInspectorRow(
              'Panjang Segmen',
              spot.lengthMeters != null ? '${spot.lengthMeters!.toStringAsFixed(2)} m' : '-',
              icon: Icons.straighten,
            ),
            _buildInspectorRow(
              'Lebar Parit',
              spot.trenchWidthCm != null
                  ? '${spot.trenchWidthCm!.toStringAsFixed(1)} cm (${spot.isWidthPass(maxWidthCm: config.maxTrenchWidthCm) ? 'Lolos' : 'Overwidth'})'
                  : '-',
              icon: Icons.swap_horiz,
            ),
            _buildInspectorRow(
              'Kedalaman Rata-rata',
              spot.avgDepthCm != null
                  ? '${spot.avgDepthCm!.toStringAsFixed(1)} cm (Min: ${spot.minDepthCm?.toStringAsFixed(0)}, Max: ${spot.maxDepthCm?.toStringAsFixed(0)})'
                  : '-',
              icon: Icons.vertical_align_bottom,
            ),
            _buildInspectorRow(
              'Presisi Deviasi As',
              spot.avgDeviationCm != null ? '±${spot.avgDeviationCm!.toStringAsFixed(1)} cm' : '-',
              icon: Icons.center_focus_strong,
            ),
            _buildInspectorRow(
              'Progress Sapuan',
              spot.sweepProgress != null
                  ? '${(spot.sweepProgress! * 100).toStringAsFixed(0)}% (${spot.isSweepDone ? 'Selesai' : 'Parsial'})'
                  : '-',
              icon: Icons.donut_large,
            ),
            if (spot.startElevation != null)
              _buildInspectorRow(
                'Elevasi Kontur',
                '${spot.startElevation!.toStringAsFixed(1)} m DPL',
                icon: Icons.terrain,
              ),
            _buildInspectorRow(
              'Operator & Alat',
              spot.operatorName ?? spot.operatorId ?? 'Badak Culah',
              icon: Icons.precision_manufacturing,
            ),
            _buildInspectorRow(
              'Area',
              spot.areaName ?? 'Area1',
              icon: Icons.map,
            ),
            _buildInspectorRow(
              'Waktu Pengerjaan',
              timeStr,
              icon: Icons.access_time,
            ),
          ] else ...[
            _buildInspectorRow(
              'Koordinat',
              '${spot.latitude.toStringAsFixed(6)}, ${spot.longitude.toStringAsFixed(6)}',
              icon: Icons.my_location,
            ),
            _buildInspectorRow(
              'Point Index',
              spot.pointIndex?.toString() ?? '-',
              icon: Icons.format_list_numbered,
            ),
            _buildInspectorRow(
              'Kedalaman (Depth)',
              spot.depth != null ? '${spot.depth!.toStringAsFixed(2)} m' : '-',
              icon: Icons.vertical_align_bottom,
            ),
            _buildInspectorRow(
              'Akurasi RTK (GNSS)',
              spot.accuracy != null ? '${spot.accuracy!.toStringAsFixed(1)} cm' : '-',
              icon: Icons.gps_fixed,
            ),
            _buildInspectorRow(
              'Operator ID',
              spot.operatorId?.isNotEmpty == true ? 'OP-${spot.operatorId}' : 'Unassigned',
              icon: Icons.person,
            ),
            _buildInspectorRow(
              'Equipment ID',
              spot.equipmentId?.isNotEmpty == true ? 'EQ-${spot.equipmentId}' : 'Unassigned',
              icon: Icons.precision_manufacturing,
            ),
            _buildInspectorRow(
              'Waktu Selesai',
              timeStr,
              icon: Icons.access_time,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCrumblingQCStatusBadge(Spot spot, SpotConfig config) {
    final qc = spot.evaluateQC(
      targetDepthCm: config.targetDepthCm,
      maxWidthCm: config.maxTrenchWidthCm,
      tolerancePercent: config.depthTolerancePercent,
    );

    switch (qc) {
      case CrumblingQCStatus.idealPass:
        return const StatusBadge(label: '🟢 IDEAL PASS', color: Color(0xFF2ECC71));
      case CrumblingQCStatus.overwidth:
        return const StatusBadge(label: '🔵 OVERWIDTH', color: Color(0xFF3B82F6));
      case CrumblingQCStatus.depthOutOfSpec:
        return const StatusBadge(label: '🟡 KEDALAMAN OUT', color: Color(0xFFF59E0B));
      case CrumblingQCStatus.failBoth:
        return const StatusBadge(label: '🔴 GAGAL KEDUANYA', color: Color(0xFFEF4444));
      case CrumblingQCStatus.inProgress:
        return const StatusBadge(label: '🟠 IN PROGRESS', color: Color(0xFFFB923C));
      case CrumblingQCStatus.pending:
        return const StatusBadge(label: '⚪ PENDING', color: Color(0xFF64748B));
    }
  }

  Widget _buildInspectorRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
