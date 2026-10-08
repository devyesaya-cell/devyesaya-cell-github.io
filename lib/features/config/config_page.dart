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
    final filtered = query.isEmpty
        ? allSpots
        : allSpots.where((s) {
            return s.id.toString().contains(query) ||
                s.uid.toLowerCase().contains(query) ||
                (s.pointIndex?.toString().contains(query) ?? false) ||
                (s.spotId?.toString().contains(query) ?? false) ||
                (s.operatorId?.contains(query) ?? false);
          }).toList();

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
              // Search in table
              SizedBox(
                width: 260,
                height: 36,
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
            ],
          ),
          const SizedBox(height: 16),

          // Table
          if (pageSpots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('Tidak ada data yang cocok.',
                    style: TextStyle(color: AppColors.textMuted)),
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
                            : '-')),
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
