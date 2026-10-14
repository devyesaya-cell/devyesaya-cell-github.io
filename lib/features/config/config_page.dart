import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/config_model.dart';
import '../../core/models/spot_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badge.dart';
import '../spot_provider.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _idleGapController;
  late TextEditingController _targetSpeedController;
  late TextEditingController _targetDepthController;

  // Crumbling Specific Controllers
  late TextEditingController _targetDepthCmController;
  late TextEditingController _maxTrenchWidthCmController;
  late TextEditingController _depthTolerancePercentController;

  final TextEditingController _tableSearchController = TextEditingController();

  int _currentPage = 0;
  static const int _pageSize = 25;

  // Table Filter States
  DateTime? _selectedSingleDate;
  DateTimeRange? _selectedDateRange;
  double? _minWidth;
  double? _maxWidth;
  double? _minDepth;
  double? _maxDepth;

  @override
  void initState() {
    super.initState();
    final config = ref.read(configProvider);
    _lengthController = TextEditingController(text: config.spotLength.toString());
    _widthController = TextEditingController(text: config.spotWidth.toString());
    _idleGapController = TextEditingController(text: config.idleGapMinutes.toString());
    _targetSpeedController =
        TextEditingController(text: config.targetSpeedSpotsPerHour.toString());
    _targetDepthController = TextEditingController(text: config.targetDepth.toString());

    _targetDepthCmController =
        TextEditingController(text: config.targetDepthCm.toStringAsFixed(0));
    _maxTrenchWidthCmController =
        TextEditingController(text: config.maxTrenchWidthCm.toStringAsFixed(0));
    _depthTolerancePercentController =
        TextEditingController(text: config.depthTolerancePercent.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _idleGapController.dispose();
    _targetSpeedController.dispose();
    _targetDepthController.dispose();
    _targetDepthCmController.dispose();
    _maxTrenchWidthCmController.dispose();
    _depthTolerancePercentController.dispose();
    _tableSearchController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final length = double.tryParse(_lengthController.text) ?? 4.0;
    final width = double.tryParse(_widthController.text) ?? 1.87;
    final idleGap = int.tryParse(_idleGapController.text) ?? 20;
    final speed = double.tryParse(_targetSpeedController.text) ?? 200.0;
    final depth = double.tryParse(_targetDepthController.text) ?? 0.8;

    final depthCm = double.tryParse(_targetDepthCmController.text) ?? 70.0;
    final trenchWidthCm = double.tryParse(_maxTrenchWidthCmController.text) ?? 110.0;
    final tolerancePct =
        double.tryParse(_depthTolerancePercentController.text) ?? 10.0;

    final newConfig = SpotConfig(
      spotLength: length,
      spotWidth: width,
      idleGapMinutes: idleGap,
      targetSpeedSpotsPerHour: speed,
      targetDepth: depth,
      targetDepthCm: depthCm,
      maxTrenchWidthCm: trenchWidthCm,
      depthTolerancePercent: tolerancePct,
    );

    ref.read(configProvider.notifier).updateConfig(newConfig);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            '✅ Pengaturan target kedalaman, toleransi QC, dan dimensi berhasil disimpan!'),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  Future<void> _pickAndUploadGeoJson() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['geojson', 'json'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        await ref.read(datasetProvider.notifier).importBytes(bytes, file.name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ File ${file.name} berhasil diunggah dan disimpan ke database lokal!'),
              backgroundColor: AppColors.statusDone,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal mengunggah file: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.statusPending),
            SizedBox(width: 8),
            Text('Hapus Database Lokal?'),
          ],
        ),
        content: const Text(
          'Semua data galian yang tersimpan di browser akan dihapus. Anda dapat memuat ulang file GeoJSON kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(datasetProvider.notifier).clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data lokal telah dikosongkan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final datasetState = ref.watch(datasetProvider);
    final summary = ref.watch(globalSummaryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.settings, color: AppColors.accentCyan, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PENGATURAN & MANAJEMEN DATA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Konfigurasi target kedalaman galian, toleransi QC 4-Kuadran, dan basis data',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Two Column Settings Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDimensionsCard(config, summary)),
                    const SizedBox(width: 20),
                    Expanded(
                        child: _buildDatabaseManagementCard(datasetState, summary)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDimensionsCard(config, summary),
                    const SizedBox(height: 20),
                    _buildDatabaseManagementCard(datasetState, summary),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 28),

          // Data Table Preview Card
          _buildDataTableCard(datasetState.spots, datasetState.isCrumbling, config),
        ],
      ),
    );
  }

  Widget _buildDimensionsCard(SpotConfig config, dynamic summary) {
    final targetDepthCm = double.tryParse(_targetDepthCmController.text) ?? 70.0;
    final tolPct = double.tryParse(_depthTolerancePercentController.text) ?? 10.0;
    final minAllowed = targetDepthCm * (1.0 - (tolPct / 100.0));
    final maxAllowed = targetDepthCm * (1.0 + (tolPct / 100.0));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.alt_route, color: Color(0xFFFB923C), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PARAMETER CRUMBLING & KEDALAMAN (QC)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: 'QC Manual', color: const Color(0xFFFB923C)),
            ],
          ),
          const SizedBox(height: 16),

          // Live QC Tolerance Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: const Color(0xFFFB923C).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RENTANG TOLERANSI KEDALAMAN IDEAL (QC HIJAU):',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${minAllowed.toStringAsFixed(1)} cm s/d ${maxAllowed.toStringAsFixed(1)} cm (±${tolPct.toStringAsFixed(0)}%)',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2ECC71)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${targetDepthCm.toStringAsFixed(0)} cm • Batas Lebar Parit: ≤ ${_maxTrenchWidthCmController.text} cm',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Depth Presets
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  controller: _targetDepthCmController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target Kedalaman Crumbling (cm)',
                    suffixText: 'cm',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: [60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0]
                              .contains(targetDepthCm)
                          ? targetDepthCm
                          : null,
                      hint: const Text('Preset', style: TextStyle(fontSize: 12)),
                      dropdownColor: AppColors.surfaceElevated,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                      items: [60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0]
                          .map((val) => DropdownMenuItem(
                                value: val,
                                child: Text('${val.toInt()} cm'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _targetDepthCmController.text = val.toInt().toString();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _maxTrenchWidthCmController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Batas Lebar Parit Standar (cm)',
                    suffixText: 'cm',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _depthTolerancePercentController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Toleransi Kedalaman (±%)',
                    suffixText: '%',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),

          // Spot Mode Dimensions
          const Row(
            children: [
              Icon(Icons.crop_square, color: AppColors.accentCyan, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PARAMETER MODE SPOT (LEGACY LUBANG TANAM)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lengthController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Panjang Spot (m)',
                    suffixText: 'm',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _widthController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Lebar Spot (m)',
                    suffixText: 'm',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Simpan Pengaturan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseManagementCard(
      SpotDatasetState datasetState, dynamic summary) {
    final intFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.storage, color: AppColors.accentCyan, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MANAJEMEN DATABASE LOKAL',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.cyan(label: 'IndexedDB / Hive'),
            ],
          ),
          const SizedBox(height: 16),

          // Dataset Status Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDbInfoRow(
                    'Nama Dataset:', datasetState.datasetName ?? 'Belum ada'),
                _buildDbInfoRow(
                    'Mode Dataset:',
                    datasetState.isCrumbling
                        ? 'CRUMBLING (LineString 3D)'
                        : 'SPOT (Point GNSS)'),
                _buildDbInfoRow('Total Item Tersimpan:',
                    '${intFormat.format(datasetState.spots.length)} ${datasetState.isCrumbling ? 'segmen' : 'titik'}'),
                _buildDbInfoRow('Status Done / Selesai:',
                    '${intFormat.format(summary.doneSpots)} item (${summary.totalAreaHa.toStringAsFixed(4)} Ha)'),
                _buildDbInfoRow('Status Pending:',
                    '${intFormat.format(summary.pendingSpots)} item'),
                _buildDbInfoRow(
                  'Terakhir Diperbarui:',
                  datasetState.lastLoadedAt != null
                      ? dateFormat.format(datasetState.lastLoadedAt!)
                      : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: _pickAndUploadGeoJson,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Unggah GeoJSON Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: const Color(0xFF0B1017),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(datasetProvider.notifier).loadSampleCrumblingGeoJson(),
                icon: const Icon(Icons.alt_route, size: 16, color: Color(0xFFFB923C)),
                label: const Text('Muat Contoh Crumbling (Badak Culah)'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(datasetProvider.notifier).loadSampleGeoJson(),
                icon: const Icon(Icons.pin_drop, size: 16),
                label: const Text('Muat Contoh Spot (SBAE)'),
              ),
              OutlinedButton.icon(
                onPressed: _confirmClearDatabase,
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.statusError),
                label: const Text('Kosongkan DB',
                    style: TextStyle(color: AppColors.statusError)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.statusError),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDbInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDataTableCard(
      List<Spot> allSpots, bool isCrumbling, SpotConfig config) {
    final query = _tableSearchController.text.trim().toLowerCase();
    final depthUnit = isCrumbling ? 'cm' : 'm';

    // Comprehensive Filtering Logic
    final filtered = allSpots.where((s) {
      // 1. Text Search Filter
      if (query.isNotEmpty) {
        final matchesQuery = s.id.toString().contains(query) ||
            s.uid.toLowerCase().contains(query) ||
            (s.pointIndex?.toString().contains(query) ?? false) ||
            (s.spotId?.toString().contains(query) ?? false) ||
            (s.operatorId?.toLowerCase().contains(query) ?? false) ||
            (s.operatorName?.toLowerCase().contains(query) ?? false);
        if (!matchesQuery) return false;
      }

      // 2. Date Filter (Single date or Date range)
      if (_selectedSingleDate != null) {
        final d = s.completedAt ?? s.timestamp ?? s.createdAt;
        if (d == null) return false;
        final local = d.toLocal();
        final matchLocal = local.year == _selectedSingleDate!.year &&
            local.month == _selectedSingleDate!.month &&
            local.day == _selectedSingleDate!.day;
        final matchUtc = d.year == _selectedSingleDate!.year &&
            d.month == _selectedSingleDate!.month &&
            d.day == _selectedSingleDate!.day;
        if (!matchLocal && !matchUtc) return false;
      } else if (_selectedDateRange != null) {
        final d = s.completedAt ?? s.timestamp ?? s.createdAt;
        if (d == null) return false;
        final local = d.toLocal();
        final startDay = DateTime(_selectedDateRange!.start.year,
            _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final endDay = DateTime(_selectedDateRange!.end.year,
            _selectedDateRange!.end.month, _selectedDateRange!.end.day);
        final spotDayLocal = DateTime(local.year, local.month, local.day);
        final spotDayUtc = DateTime(d.year, d.month, d.day);
        final matchLocal =
            !spotDayLocal.isBefore(startDay) && !spotDayLocal.isAfter(endDay);
        final matchUtc =
            !spotDayUtc.isBefore(startDay) && !spotDayUtc.isAfter(endDay);
        if (!matchLocal && !matchUtc) return false;
      }

      // 3. Lebar (Width) Filter Range
      if (_minWidth != null || _maxWidth != null) {
        final w = _getSpotWidth(s);
        if (w == null) return false;
        if (_minWidth != null && w < _minWidth!) return false;
        if (_maxWidth != null && w > _maxWidth!) return false;
      }

      // 4. Depth (Kedalaman) Filter Range
      if (_minDepth != null || _maxDepth != null) {
        final d = _getSpotDepth(s, isCrumbling);
        if (d == null) return false;
        if (_minDepth != null && d < _minDepth!) return false;
        if (_maxDepth != null && d > _maxDepth!) return false;
      }

      return true;
    }).toList();

    final isDateFiltered = _selectedSingleDate != null || _selectedDateRange != null;
    final isWidthFiltered = _minWidth != null || _maxWidth != null;
    final isDepthFiltered = _minDepth != null || _maxDepth != null;
    final hasActiveFilters = isDateFiltered || isWidthFiltered || isDepthFiltered || query.isNotEmpty;

    final totalPages = (filtered.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize < filtered.length)
        ? start + _pageSize
        : filtered.length;
    final pageSpots =
        (start < filtered.length) ? filtered.sublist(start, end) : <Spot>[];

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_chart_outlined,
                      color: AppColors.accentCyan, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isCrumbling
                        ? 'TABEL RINCIAN SEGMEN CRUMBLING (${filtered.length} SEGMEN)'
                        : 'TABEL RINCIAN HASIL GALIAN (${filtered.length} TITIK)',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              if (filtered.length != allSpots.length)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.accentCyan.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Difilter dari ${allSpots.length} total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentCyan,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Dedicated SCADA Filter Toolbar
          _buildFilterToolbar(
            context: context,
            allSpots: allSpots,
            isCrumbling: isCrumbling,
            config: config,
            query: query,
            depthUnit: depthUnit,
            isDateFiltered: isDateFiltered,
            isWidthFiltered: isWidthFiltered,
            isDepthFiltered: isDepthFiltered,
            hasActiveFilters: hasActiveFilters,
          ),
          const SizedBox(height: 16),

          // Table Content or Empty State
          if (pageSpots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.filter_alt_off,
                        size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    const Text('Tidak ada data yang cocok dengan kriteria filter.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    if (hasActiveFilters) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _resetAllFilters,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset Semua Filter'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(AppColors.surfaceElevated),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  return AppColors.surfaceCard;
                }),
                columns: isCrumbling
                    ? const [
                        DataColumn(
                            label: Text('ID Segmen',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Spot ID',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('QC Evaluasi',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Panjang (m)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Kedalaman (cm)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Lebar (cm)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Deviasi (cm)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Sweep',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Waktu',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Operator',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                      ]
                    : const [
                        DataColumn(
                            label: Text('Point Index',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Waktu (Timestamp)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Operator ID',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Equipment ID',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Koordinat (Lat, Lng)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Akurasi (mm)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(
                            label: Text('Kedalaman (m)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                rows: pageSpots.map((spot) {
                  if (isCrumbling) {
                    final qc = spot.evaluateQC(
                      targetDepthCm: config.targetDepthCm,
                      maxWidthCm: config.maxTrenchWidthCm,
                      tolerancePercent: config.depthTolerancePercent,
                    );
                    return DataRow(
                      cells: [
                        DataCell(Text('#${spot.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text('#${spot.spotId ?? spot.pointIndex ?? '-'}')),
                        DataCell(_buildTableQCBadge(qc)),
                        DataCell(
                            Text(spot.lengthMeters?.toStringAsFixed(2) ?? '1.00')),
                        DataCell(Text(
                            '${spot.avgDepthCm?.toStringAsFixed(1) ?? '-'}${spot.isDepthPass(targetDepthCm: config.targetDepthCm) ? ' ✓' : ' ✗'}')),
                        DataCell(Text(
                            '${spot.trenchWidthCm?.toStringAsFixed(1) ?? '-'}${spot.isWidthPass(maxWidthCm: config.maxTrenchWidthCm) ? ' ✓' : ' ✗'}')),
                        DataCell(Text(spot.avgDeviationCm != null
                            ? '±${spot.avgDeviationCm!.toStringAsFixed(1)}'
                            : '-')),
                        DataCell(Text(
                            '${((spot.sweepProgress ?? 1.0) * 100).toStringAsFixed(0)}%')),
                        DataCell(Text(spot.completedAt != null
                            ? dateFormat.format(spot.completedAt!)
                            : (spot.timestamp != null
                                ? dateFormat.format(spot.timestamp!)
                                : '-'))),
                        DataCell(Text(spot.operatorName ?? spot.operatorId ?? '-')),
                      ],
                    );
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text('#${spot.pointIndex ?? spot.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(spot.isDone ? StatusBadge.done() : StatusBadge.pending()),
                      DataCell(Text(spot.timestamp != null
                          ? dateFormat.format(spot.timestamp!)
                          : '-')),
                      DataCell(Text(spot.operatorId?.isNotEmpty == true
                          ? 'OP-${spot.operatorId}'
                          : '-')),
                      DataCell(Text(spot.equipmentId?.isNotEmpty == true
                          ? 'EQ-${spot.equipmentId}'
                          : '-')),
                      DataCell(Text(
                          '${spot.latitude.toStringAsFixed(6)}, ${spot.longitude.toStringAsFixed(6)}')),
                      DataCell(Text('${spot.accuracy?.toStringAsFixed(0) ?? 0} mm')),
                      DataCell(Text('${spot.depth?.toStringAsFixed(2) ?? 0.0} m')),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Pagination Controls
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menampilkan ${start + 1} - $end dari ${filtered.length} ${isCrumbling ? 'segmen' : 'titik'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed:
                          _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    ),
                    Text(
                      'Halaman ${_currentPage + 1} / $totalPages',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar({
    required BuildContext context,
    required List<Spot> allSpots,
    required bool isCrumbling,
    required SpotConfig config,
    required String query,
    required String depthUnit,
    required bool isDateFiltered,
    required bool isWidthFiltered,
    required bool isDepthFiltered,
    required bool hasActiveFilters,
  }) {
    String dateLabel = 'Filter Tanggal';
    if (_selectedSingleDate != null) {
      dateLabel = DateFormat('dd MMM yyyy').format(_selectedSingleDate!);
    } else if (_selectedDateRange != null) {
      dateLabel =
          '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}';
    }

    final widthLabel = isWidthFiltered
        ? 'Lebar: ${_formatRangeText(_minWidth, _maxWidth, 'cm')}'
        : 'Filter Lebar';

    final depthLabel = isDepthFiltered
        ? 'Kedalaman: ${_formatRangeText(_minDepth, _maxDepth, depthUnit)}'
        : 'Filter Kedalaman';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Controls Row
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 1. Search Box
              SizedBox(
                width: 250,
                height: 38,
                child: TextField(
                  controller: _tableSearchController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Cari ID, Spot ID, Operator...',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 14),
                            onPressed: () {
                              _tableSearchController.clear();
                              setState(() => _currentPage = 0);
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() => _currentPage = 0),
                ),
              ),

              // 2. Date Filter Button (Single & Range)
              OutlinedButton.icon(
                onPressed: () => _showDateFilterDialog(context, allSpots),
                icon: Icon(
                  isDateFiltered ? Icons.event_available : Icons.calendar_today_outlined,
                  size: 16,
                  color: isDateFiltered ? AppColors.accentCyan : AppColors.textSecondary,
                ),
                label: Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isDateFiltered ? FontWeight.bold : FontWeight.normal,
                    color: isDateFiltered ? AppColors.accentCyan : AppColors.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDateFiltered
                      ? AppColors.accentCyan.withValues(alpha: 0.12)
                      : AppColors.surfaceCard,
                  side: BorderSide(
                    color: isDateFiltered ? AppColors.accentCyan : AppColors.border,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              // 3. Lebar (Width Range) Button
              OutlinedButton.icon(
                onPressed: () => _showWidthFilterDialog(context, allSpots),
                icon: Icon(
                  Icons.straighten,
                  size: 16,
                  color: isWidthFiltered
                      ? const Color(0xFF3B82F6)
                      : AppColors.textSecondary,
                ),
                label: Text(
                  widthLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isWidthFiltered ? FontWeight.bold : FontWeight.normal,
                    color: isWidthFiltered
                        ? const Color(0xFF3B82F6)
                        : AppColors.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isWidthFiltered
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                      : AppColors.surfaceCard,
                  side: BorderSide(
                    color: isWidthFiltered
                        ? const Color(0xFF3B82F6)
                        : AppColors.border,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              // 4. Depth (Kedalaman Range) Button
              OutlinedButton.icon(
                onPressed: () =>
                    _showDepthFilterDialog(context, allSpots, isCrumbling, config),
                icon: Icon(
                  Icons.vertical_align_bottom,
                  size: 16,
                  color: isDepthFiltered
                      ? const Color(0xFFF59E0B)
                      : AppColors.textSecondary,
                ),
                label: Text(
                  depthLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isDepthFiltered ? FontWeight.bold : FontWeight.normal,
                    color: isDepthFiltered
                        ? const Color(0xFFF59E0B)
                        : AppColors.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDepthFiltered
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                      : AppColors.surfaceCard,
                  side: BorderSide(
                    color: isDepthFiltered
                        ? const Color(0xFFF59E0B)
                        : AppColors.border,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              // 5. Reset All Filter Button
              if (hasActiveFilters)
                OutlinedButton.icon(
                  onPressed: _resetAllFilters,
                  icon: const Icon(Icons.refresh,
                      size: 16, color: AppColors.statusError),
                  label: const Text('Reset Filter',
                      style: TextStyle(
                          color: AppColors.statusError, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.statusError),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
            ],
          ),

          // Active Filter Chips Row
          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Filter Aktif: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_selectedSingleDate != null)
                  _buildFilterBadge(
                    icon: Icons.calendar_today,
                    label: DateFormat('dd MMM yyyy').format(_selectedSingleDate!),
                    color: AppColors.accentCyan,
                    onRemove: () => setState(() {
                      _selectedSingleDate = null;
                      _currentPage = 0;
                    }),
                    onTap: () => _showDateFilterDialog(context, allSpots),
                  ),
                if (_selectedDateRange != null)
                  _buildFilterBadge(
                    icon: Icons.date_range,
                    label:
                        '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                    color: AppColors.accentCyan,
                    onRemove: () => setState(() {
                      _selectedDateRange = null;
                      _currentPage = 0;
                    }),
                    onTap: () => _showDateFilterDialog(context, allSpots),
                  ),
                if (isWidthFiltered)
                  _buildFilterBadge(
                    icon: Icons.straighten,
                    label: 'Lebar: ${_formatRangeText(_minWidth, _maxWidth, 'cm')}',
                    color: const Color(0xFF3B82F6),
                    onRemove: () => setState(() {
                      _minWidth = null;
                      _maxWidth = null;
                      _currentPage = 0;
                    }),
                    onTap: () => _showWidthFilterDialog(context, allSpots),
                  ),
                if (isDepthFiltered)
                  _buildFilterBadge(
                    icon: Icons.vertical_align_bottom,
                    label:
                        'Kedalaman: ${_formatRangeText(_minDepth, _maxDepth, depthUnit)}',
                    color: const Color(0xFFF59E0B),
                    onRemove: () => setState(() {
                      _minDepth = null;
                      _maxDepth = null;
                      _currentPage = 0;
                    }),
                    onTap: () => _showDepthFilterDialog(
                        context, allSpots, isCrumbling, config),
                  ),
                if (query.isNotEmpty)
                  _buildFilterBadge(
                    icon: Icons.search,
                    label: '"$query"',
                    color: AppColors.textAccent,
                    onRemove: () => setState(() {
                      _tableSearchController.clear();
                      _currentPage = 0;
                    }),
                  ),
                TextButton.icon(
                  onPressed: _resetAllFilters,
                  icon: const Icon(Icons.clear_all,
                      size: 14, color: AppColors.statusError),
                  label: const Text(
                    'Hapus Semua',
                    style: TextStyle(fontSize: 11, color: AppColors.statusError),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBadge({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onRemove,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 5),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close, size: 12, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Filter Dialog Handlers ---

  double? _getSpotWidth(Spot s) {
    if (s.trenchWidthCm != null) return s.trenchWidthCm;
    final rawW = s.rawProperties['trench_width_cm'] ??
        s.rawProperties['width'] ??
        s.rawProperties['lebar'];
    if (rawW is num) return rawW.toDouble();
    return null;
  }

  double? _getSpotDepth(Spot s, bool isCrumbling) {
    if (isCrumbling) {
      return s.avgDepthCm ?? s.depth;
    } else {
      return s.depth;
    }
  }

  void _resetAllFilters() {
    setState(() {
      _selectedSingleDate = null;
      _selectedDateRange = null;
      _minWidth = null;
      _maxWidth = null;
      _minDepth = null;
      _maxDepth = null;
      _tableSearchController.clear();
      _currentPage = 0;
    });
  }

  String _formatRangeText(double? min, double? max, String unit) {
    if (min != null && max != null) {
      return '${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)} $unit';
    } else if (min != null) {
      return '≥ ${min.toStringAsFixed(1)} $unit';
    } else if (max != null) {
      return '≤ ${max.toStringAsFixed(1)} $unit';
    }
    return 'Semua';
  }

  Future<void> _showDateFilterDialog(
      BuildContext context, List<Spot> spots) async {
    DateTime minDate = DateTime(2020, 1, 1);
    DateTime maxDate = DateTime.now().add(const Duration(days: 365));
    final List<DateTime> uniqueDays = [];
    final Set<String> seenDays = {};

    for (final s in spots) {
      final d = s.completedAt ?? s.timestamp ?? s.createdAt;
      if (d != null) {
        final local = d.toLocal();
        final dayStr = DateFormat('yyyy-MM-dd').format(local);
        if (!seenDays.contains(dayStr)) {
          seenDays.add(dayStr);
          uniqueDays.add(DateTime(local.year, local.month, local.day));
        }
      }
    }

    uniqueDays.sort((a, b) => b.compareTo(a));

    if (uniqueDays.isNotEmpty) {
      minDate = uniqueDays.last.subtract(const Duration(days: 7));
      maxDate = uniqueDays.first.add(const Duration(days: 7));
    }

    DateTime safeMin = minDate;
    DateTime safeMax = maxDate;
    if (!safeMax.isAfter(safeMin)) {
      safeMax = safeMin.add(const Duration(days: 7));
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: AppColors.accentCyan, size: 22),
            SizedBox(width: 10),
            Text('Filter Tanggal Pekerjaan', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih metode filter tanggal untuk menampilkan segmen / titik:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              // Option 1: Single Date Button
              _buildDateOptionTile(
                icon: Icons.calendar_today,
                title: 'Pilih Satu Tanggal (Single Date)',
                subtitle: _selectedSingleDate != null
                    ? 'Terpilih: ${DateFormat('dd MMMM yyyy').format(_selectedSingleDate!)}'
                    : 'Pilih satu hari spesifik dari kalender',
                isSelected: _selectedSingleDate != null,
                onTap: () {
                  Navigator.pop(ctx);
                  _openSingleDatePicker(context, safeMin, safeMax);
                },
              ),
              const SizedBox(height: 10),
              // Option 2: Date Range Button
              _buildDateOptionTile(
                icon: Icons.date_range,
                title: 'Pilih Rentang Tanggal (Date Range)',
                subtitle: _selectedDateRange != null
                    ? 'Terpilih: ${DateFormat('dd MMM').format(_selectedDateRange!.start)} s/d ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'
                    : 'Pilih rentang tanggal awal s/d akhir',
                isSelected: _selectedDateRange != null,
                onTap: () {
                  Navigator.pop(ctx);
                  _openDateRangePicker(context, safeMin, safeMax);
                },
              ),
              if (uniqueDays.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),
                const Text(
                  'PILIHAN CEPAT DARI DATASET:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: uniqueDays.take(8).map((day) {
                    final isCur = _selectedSingleDate != null &&
                        _selectedSingleDate!.year == day.year &&
                        _selectedSingleDate!.month == day.month &&
                        _selectedSingleDate!.day == day.day;
                    return ActionChip(
                      backgroundColor: isCur
                          ? AppColors.accentCyan.withValues(alpha: 0.25)
                          : AppColors.surfaceCard,
                      side: BorderSide(
                        color: isCur ? AppColors.accentCyan : AppColors.border,
                      ),
                      label: Text(
                        DateFormat('dd MMM yyyy').format(day),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                          color: isCur ? AppColors.accentCyan : AppColors.textPrimary,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedSingleDate = day;
                          _selectedDateRange = null;
                          _currentPage = 0;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (_selectedSingleDate != null || _selectedDateRange != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSingleDate = null;
                  _selectedDateRange = null;
                  _currentPage = 0;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Reset Tanggal',
                  style: TextStyle(color: AppColors.statusError)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentCyan.withValues(alpha: 0.12)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentCyan.withValues(alpha: 0.2)
                    : AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.accentCyan : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? AppColors.accentCyan : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? AppColors.textPrimary.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _openSingleDatePicker(
      BuildContext context, DateTime minDate, DateTime maxDate) async {
    final now = DateTime.now();
    DateTime initial = _selectedSingleDate ??
        (_selectedDateRange?.start ??
            (now.isAfter(minDate) && now.isBefore(maxDate) ? now : maxDate));
    if (initial.isBefore(minDate)) initial = minDate;
    if (initial.isAfter(maxDate)) initial = maxDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'PILIH TANGGAL SPESIFIK (SINGLE DATE)',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentCyan,
              onPrimary: Color(0xFF0B1017),
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: AppColors.surfaceElevated),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedSingleDate = picked;
        _selectedDateRange = null;
        _currentPage = 0;
      });
    }
  }

  Future<void> _openDateRangePicker(
      BuildContext context, DateTime minDate, DateTime maxDate) async {
    final initialRange = _selectedDateRange ??
        DateTimeRange(
          start: minDate,
          end: maxDate,
        );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'PILIH RENTANG TANGGAL (DATE RANGE)',
      cancelText: 'BATAL',
      confirmText: 'PILIH RENTANG',
      saveText: 'PILIH RENTANG',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentCyan,
              onPrimary: Color(0xFF0B1017),
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: AppColors.surfaceElevated),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedSingleDate = null;
        _currentPage = 0;
      });
    }
  }

  Future<void> _showWidthFilterDialog(
      BuildContext context, List<Spot> spots) async {
    double? minW;
    double? maxW;
    for (final s in spots) {
      final w = _getSpotWidth(s);
      if (w != null) {
        if (minW == null || w < minW) minW = w;
        if (maxW == null || w > maxW) maxW = w;
      }
    }

    final dataMin = minW ?? 60.0;
    double dataMax = maxW ?? 160.0;
    if (dataMax <= dataMin) dataMax = dataMin + 20.0;

    final config = ref.read(configProvider);
    final maxWidthStd = config.maxTrenchWidthCm;

    final presets = [
      const _RangePreset(label: 'Semua Lebar', min: null, max: null),
      _RangePreset(
        label: '≤ Standar (${maxWidthStd.toInt()} cm)',
        min: null,
        max: maxWidthStd,
      ),
      _RangePreset(
        label: 'Overwidth (> ${maxWidthStd.toInt()} cm)',
        min: maxWidthStd,
        max: null,
      ),
      const _RangePreset(label: '80 - 100 cm', min: 80, max: 100),
      const _RangePreset(label: '100 - 120 cm', min: 100, max: 120),
    ];

    final result = await showDialog<_RangeResult>(
      context: context,
      builder: (ctx) => _RangeFilterDialog(
        title: 'Filter Rentang Lebar Parit (Trench Width)',
        icon: Icons.straighten,
        themeColor: const Color(0xFF3B82F6),
        unit: 'cm',
        initialMin: _minWidth,
        initialMax: _maxWidth,
        dataMin: dataMin,
        dataMax: dataMax,
        presets: presets,
      ),
    );

    if (result != null) {
      setState(() {
        _minWidth = result.min;
        _maxWidth = result.max;
        _currentPage = 0;
      });
    }
  }

  Future<void> _showDepthFilterDialog(BuildContext context, List<Spot> spots,
      bool isCrumbling, SpotConfig config) async {
    double? minD;
    double? maxD;
    for (final s in spots) {
      final d = _getSpotDepth(s, isCrumbling);
      if (d != null) {
        if (minD == null || d < minD) minD = d;
        if (maxD == null || d > maxD) maxD = d;
      }
    }

    final unit = isCrumbling ? 'cm' : 'm';
    final dataMin = minD ?? (isCrumbling ? 40.0 : 0.0);
    double dataMax = maxD ?? (isCrumbling ? 120.0 : 2.0);
    if (dataMax <= dataMin) dataMax = dataMin + (isCrumbling ? 20.0 : 1.0);

    List<_RangePreset> presets;
    if (isCrumbling) {
      final target = config.targetDepthCm;
      final tol = config.depthTolerancePercent;
      final idealMin = target * (1.0 - (tol / 100.0));
      final idealMax = target * (1.0 + (tol / 100.0));

      presets = [
        const _RangePreset(label: 'Semua Kedalaman', min: null, max: null),
        _RangePreset(
          label:
              '🟢 Ideal QC (${idealMin.toStringAsFixed(0)} - ${idealMax.toStringAsFixed(0)} cm)',
          min: idealMin,
          max: idealMax,
        ),
        _RangePreset(
          label: '🟡 Dangkal (< ${idealMin.toStringAsFixed(0)} cm)',
          min: null,
          max: idealMin,
        ),
        _RangePreset(
          label: '🔴 Dalam (> ${idealMax.toStringAsFixed(0)} cm)',
          min: idealMax,
          max: null,
        ),
      ];
    } else {
      presets = [
        const _RangePreset(label: 'Semua Kedalaman', min: null, max: null),
        const _RangePreset(label: '< 0.5 m', min: null, max: 0.5),
        const _RangePreset(label: '0.5 - 1.0 m', min: 0.5, max: 1.0),
        const _RangePreset(label: '> 1.0 m', min: 1.0, max: null),
      ];
    }

    final result = await showDialog<_RangeResult>(
      context: context,
      builder: (ctx) => _RangeFilterDialog(
        title: isCrumbling
            ? 'Filter Rentang Kedalaman Crumbling'
            : 'Filter Rentang Kedalaman Spot Galian',
        icon: Icons.vertical_align_bottom,
        themeColor: const Color(0xFFF59E0B),
        unit: unit,
        initialMin: _minDepth,
        initialMax: _maxDepth,
        dataMin: dataMin,
        dataMax: dataMax,
        presets: presets,
      ),
    );

    if (result != null) {
      setState(() {
        _minDepth = result.min;
        _maxDepth = result.max;
        _currentPage = 0;
      });
    }
  }

  Widget _buildTableQCBadge(CrumblingQCStatus qc) {
    switch (qc) {
      case CrumblingQCStatus.idealPass:
        return const StatusBadge(label: '🟢 Ideal', color: Color(0xFF2ECC71));
      case CrumblingQCStatus.overwidth:
        return const StatusBadge(label: '🔵 Lebar', color: Color(0xFF3B82F6));
      case CrumblingQCStatus.depthOutOfSpec:
        return const StatusBadge(label: '🟡 Kedalaman', color: Color(0xFFF59E0B));
      case CrumblingQCStatus.failBoth:
        return const StatusBadge(label: '🔴 Gagal', color: Color(0xFFEF4444));
      case CrumblingQCStatus.inProgress:
        return const StatusBadge(label: '🟠 Progress', color: Color(0xFFFB923C));
      case CrumblingQCStatus.pending:
        return const StatusBadge(label: '⚪ Pending', color: Color(0xFF64748B));
    }
  }
}

// --- Reusable Range Filter Dialog ---

class _RangeResult {
  final double? min;
  final double? max;

  const _RangeResult(this.min, this.max);
}

class _RangePreset {
  final String label;
  final double? min;
  final double? max;

  const _RangePreset({
    required this.label,
    this.min,
    this.max,
  });
}

class _RangeFilterDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color themeColor;
  final String unit;
  final double? initialMin;
  final double? initialMax;
  final double dataMin;
  final double dataMax;
  final List<_RangePreset> presets;

  const _RangeFilterDialog({
    required this.title,
    required this.icon,
    required this.themeColor,
    required this.unit,
    this.initialMin,
    this.initialMax,
    required this.dataMin,
    required this.dataMax,
    required this.presets,
  });

  @override
  State<_RangeFilterDialog> createState() => _RangeFilterDialogState();
}

class _RangeFilterDialogState extends State<_RangeFilterDialog> {
  late double _sliderMin;
  late double _sliderMax;
  late RangeValues _currentRange;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _sliderMin = (widget.dataMin * 0.95).floorToDouble();
    if (_sliderMin < 0) _sliderMin = 0.0;
    _sliderMax = (widget.dataMax * 1.05).ceilToDouble();
    if (_sliderMax <= _sliderMin) {
      _sliderMax = _sliderMin + (widget.unit == 'm' ? 1.0 : 10.0);
    }

    final initStart =
        (widget.initialMin ?? _sliderMin).clamp(_sliderMin, _sliderMax);
    final initEnd =
        (widget.initialMax ?? _sliderMax).clamp(_sliderMin, _sliderMax);
    _currentRange = RangeValues(
      initStart <= initEnd ? initStart : _sliderMin,
      initEnd >= initStart ? initEnd : _sliderMax,
    );

    _minController = TextEditingController(
      text: widget.initialMin != null
          ? widget.initialMin!.toStringAsFixed(1)
          : '',
    );
    _maxController = TextEditingController(
      text: widget.initialMax != null
          ? widget.initialMax!.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _applyPreset(_RangePreset preset) {
    setState(() {
      if (preset.min == null && preset.max == null) {
        _minController.clear();
        _maxController.clear();
        _currentRange = RangeValues(_sliderMin, _sliderMax);
      } else {
        _minController.text =
            preset.min != null ? preset.min!.toStringAsFixed(1) : '';
        _maxController.text =
            preset.max != null ? preset.max!.toStringAsFixed(1) : '';
        final s = (preset.min ?? _sliderMin).clamp(_sliderMin, _sliderMax);
        final e = (preset.max ?? _sliderMax).clamp(_sliderMin, _sliderMax);
        _currentRange =
            RangeValues(s <= e ? s : _sliderMin, e >= s ? e : _sliderMax);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: widget.themeColor, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data Bounds Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: widget.themeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: widget.themeColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rentang data aktual: ${widget.dataMin.toStringAsFixed(1)} s/d ${widget.dataMax.toStringAsFixed(1)} ${widget.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Presets
              if (widget.presets.isNotEmpty) ...[
                const Text(
                  'PRESET PILIHAN CEPAT:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.presets.map((p) {
                    final isSelected = (p.min == null
                            ? _minController.text.isEmpty
                            : double.tryParse(_minController.text) == p.min) &&
                        (p.max == null
                            ? _maxController.text.isEmpty
                            : double.tryParse(_maxController.text) == p.max);
                    return ActionChip(
                      backgroundColor: isSelected
                          ? widget.themeColor.withValues(alpha: 0.25)
                          : AppColors.surfaceCard,
                      side: BorderSide(
                        color:
                            isSelected ? widget.themeColor : AppColors.border,
                      ),
                      label: Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? widget.themeColor
                              : AppColors.textPrimary,
                        ),
                      ),
                      onPressed: () => _applyPreset(p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Slider
              const Text(
                'GESER RENTANG NILAI:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              RangeSlider(
                values: _currentRange,
                min: _sliderMin,
                max: _sliderMax,
                divisions: ((_sliderMax - _sliderMin) *
                        (widget.unit == 'm' ? 20 : 2))
                    .toInt()
                    .clamp(10, 100),
                activeColor: widget.themeColor,
                inactiveColor: AppColors.border,
                labels: RangeLabels(
                  '${_currentRange.start.toStringAsFixed(1)} ${widget.unit}',
                  '${_currentRange.end.toStringAsFixed(1)} ${widget.unit}',
                ),
                onChanged: (values) {
                  setState(() {
                    _currentRange = values;
                    _minController.text = values.start.toStringAsFixed(1);
                    _maxController.text = values.end.toStringAsFixed(1);
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_sliderMin.toStringAsFixed(1)} ${widget.unit}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    '${_sliderMax.toStringAsFixed(1)} ${widget.unit}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Min and Max Inputs
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Batas Bawah (Min)',
                        suffixText: widget.unit,
                        hintText: _sliderMin.toStringAsFixed(1),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          setState(() {
                            final s = parsed.clamp(_sliderMin, _sliderMax);
                            final e = _currentRange.end >= s
                                ? _currentRange.end
                                : _sliderMax;
                            _currentRange = RangeValues(s, e);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _maxController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Batas Atas (Max)',
                        suffixText: widget.unit,
                        hintText: _sliderMax.toStringAsFixed(1),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          setState(() {
                            final e = parsed.clamp(_sliderMin, _sliderMax);
                            final s = _currentRange.start <= e
                                ? _currentRange.start
                                : _sliderMin;
                            _currentRange = RangeValues(s, e);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _RangeResult(null, null)),
          child: const Text('Reset Filter',
              style: TextStyle(color: AppColors.statusError)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.themeColor,
            foregroundColor: const Color(0xFF0B1017),
          ),
          onPressed: () {
            final minVal = double.tryParse(_minController.text);
            final maxVal = double.tryParse(_maxController.text);
            Navigator.pop(context, _RangeResult(minVal, maxVal));
          },
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Terapkan Filter'),
        ),
      ],
    );
  }
}
