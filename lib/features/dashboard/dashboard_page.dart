import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/config_model.dart';
import '../../core/models/spot_model.dart';
import '../../core/models/summary_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/filter_toolbar.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/status_badge.dart';
import '../spot_provider.dart';

class DashboardPage extends ConsumerWidget {
  final VoidCallback onNavigateToMap;

  const DashboardPage({
    super.key,
    required this.onNavigateToMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datasetState = ref.watch(datasetProvider);
    final summary = ref.watch(summaryProvider);
    final config = ref.watch(configProvider);

    if (datasetState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accentCyan,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              datasetState.loadingMessage ?? 'Memuat data galian...',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (datasetState.spots.isEmpty) {
      return _buildEmptyState(ref);
    }

    final isCrumbling = summary.isCrumbling;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Summary Banner
          _buildSummaryHero(context, summary, config),
          const SizedBox(height: 20),

          // QC 4-Quadrant Card for Crumbling
          if (isCrumbling) ...[
            _buildCrumblingQCComplianceCard(summary, config),
            const SizedBox(height: 20),
          ],

          // Filter Toolbar
          const FilterToolbar(),
          const SizedBox(height: 24),

          // Primary Metric Cards Grid
          _buildMetricsGrid(summary, config),
          const SizedBox(height: 24),

          // Charts & Analytics Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildDailyChartCard(summary),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: _buildOperatorLeaderboard(summary),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDailyChartCard(summary),
                    const SizedBox(height: 20),
                    _buildOperatorLeaderboard(summary),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Equipment & Shift Details Card
          _buildOperationalDetailsCard(summary),
        ],
      ),
    );
  }

  Widget _buildSummaryHero(BuildContext context, SpotSummary summary, SpotConfig config) {
    final numberFormat = NumberFormat('#,##0.0000');
    final intFormat = NumberFormat('#,##0');
    final isCrumbling = summary.isCrumbling;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCrumbling
              ? const Color(0xFFFB923C).withValues(alpha: 0.3)
              : AppColors.accentCyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCrumbling
              ? const [Color(0xFF231815), Color(0xFF131A24)]
              : const [Color(0xFF132238), Color(0xFF0F1826)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isCrumbling ? const Color(0xFFFB923C) : AppColors.accentCyan)
                .withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isCrumbling ? const Color(0xFFFB923C) : AppColors.accentCyan)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCrumbling ? const Color(0xFFFB923C) : AppColors.accentCyan,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isCrumbling ? Icons.alt_route : Icons.terrain,
                      color: isCrumbling ? const Color(0xFFFB923C) : AppColors.accentCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCrumbling
                            ? 'RINGKASAN HASIL GALIAN CRUMBLING (TRENCH & SWEEP)'
                            : 'RINGKASAN HASIL GALIAN (EXCAVATION SPOTS)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isCrumbling
                                ? 'Target Kedalaman: ${config.targetDepthCm.toStringAsFixed(0)} cm (Tol: ${config.minAllowedDepthCm.toStringAsFixed(0)}–${config.maxAllowedDepthCm.toStringAsFixed(0)} cm)'
                                : 'Formula Standar: (${config.spotLength} x ${config.spotWidth} m) x Total Spot Done',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isCrumbling)
                            StatusBadge(
                              label: 'Lebar Standar ≤ ${config.maxTrenchWidthCm.toStringAsFixed(0)} cm',
                              color: const Color(0xFFFB923C),
                            )
                          else
                            StatusBadge.cyan(label: '${config.spotAreaM2.toStringAsFixed(2)} m² / spot'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onNavigateToMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Buka di Peta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCrumbling ? const Color(0xFFFB923C) : AppColors.accentCyan,
                  foregroundColor: const Color(0xFF0B1017),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _buildHeroStat(
                label: isCrumbling ? 'TOTAL PANJANG SELESAI' : 'TOTAL AREA DIKERJAKAN',
                value: isCrumbling
                    ? '${summary.doneLengthMeters.toStringAsFixed(1)} m'
                    : '${numberFormat.format(summary.totalAreaHa)} Ha',
                sublabel: isCrumbling
                    ? '${summary.completionRate.toStringAsFixed(1)}% dari total ${summary.totalLengthMeters.toStringAsFixed(1)} m'
                    : 'Setara ${intFormat.format(summary.totalAreaM2)} m²',
                color: AppColors.statusDone,
                isLarge: true,
              ),
              _buildHeroStat(
                label: isCrumbling ? 'LUAS AREA DIKERJAKAN' : 'TOTAL SPOT DONE',
                value: isCrumbling
                    ? '${numberFormat.format(summary.totalAreaHa)} Ha'
                    : '${intFormat.format(summary.doneSpots)} spot',
                sublabel: isCrumbling
                    ? 'Setara ${intFormat.format(summary.totalAreaM2)} m² (Jarak x Spacing ${config.spotLength.toStringAsFixed(0)}m)'
                    : '${summary.completionRate.toStringAsFixed(1)}% dari total ${intFormat.format(summary.totalSpots)} spot',
                color: isCrumbling ? const Color(0xFF3B82F6) : AppColors.accentCyan,
              ),
              _buildHeroStat(
                label: isCrumbling ? 'RATA-RATA KEDALAMAN' : 'TOTAL WORKHOURS',
                value: isCrumbling
                    ? '${summary.averageDepth.toStringAsFixed(1)} cm'
                    : '${summary.activeWorkHours.toStringAsFixed(1)} Jam',
                sublabel: isCrumbling
                    ? 'Target: ${config.targetDepthCm.toStringAsFixed(0)} cm (Akurasi: ±${summary.avgDeviationCm.toStringAsFixed(1)} cm)'
                    : 'Rentang ${summary.grossWorkHours.toStringAsFixed(1)} Jam (Idle: ${summary.idleHours.toStringAsFixed(1)} Jam)',
                color: isCrumbling ? const Color(0xFF2ECC71) : AppColors.statusInfo,
              ),
              _buildHeroStat(
                label: isCrumbling ? 'KECEPATAN GALIAN' : 'RATA-RATA WORKSPEED',
                value: isCrumbling
                    ? '${summary.speedMetersPerHour.toStringAsFixed(1)} m/jam'
                    : '${summary.speedSpotsPerHour.toStringAsFixed(1)} spot/jam',
                sublabel: isCrumbling
                    ? '${summary.activeWorkHours.toStringAsFixed(1)} Jam Aktif • ${summary.speedHaPerHour.toStringAsFixed(3)} Ha/jam'
                    : '${summary.speedHaPerHour.toStringAsFixed(3)} Ha/jam • ${summary.avgSecondsPerSpot.toStringAsFixed(1)} dtk/spot',
                color: AppColors.statusPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrumblingQCComplianceCard(SpotSummary summary, SpotConfig config) {
    final qc = summary.qcDistribution;
    final total = summary.totalSpots > 0 ? summary.totalSpots : 1;
    final idealCount = qc[CrumblingQCStatus.idealPass] ?? 0;
    final overwidthCount = qc[CrumblingQCStatus.overwidth] ?? 0;
    final depthOutCount = qc[CrumblingQCStatus.depthOutOfSpec] ?? 0;
    final failBothCount = qc[CrumblingQCStatus.failBoth] ?? 0;
    final inProgressCount = qc[CrumblingQCStatus.inProgress] ?? 0;
    final pendingCount = qc[CrumblingQCStatus.pending] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
                  const Icon(Icons.verified_outlined, color: Color(0xFF2ECC71), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'KUALITAS HASIL GALIAN (EVALUASI QC 4-KUADRAN)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Target: ${config.targetDepthCm.toStringAsFixed(0)} cm (±${config.depthTolerancePercent.toStringAsFixed(0)}%) | Max Lebar: ${config.maxTrenchWidthCm.toStringAsFixed(0)} cm',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Multi-color Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (idealCount > 0)
                    Expanded(
                      flex: idealCount,
                      child: Container(color: const Color(0xFF2ECC71)),
                    ),
                  if (overwidthCount > 0)
                    Expanded(
                      flex: overwidthCount,
                      child: Container(color: const Color(0xFF3B82F6)),
                    ),
                  if (depthOutCount > 0)
                    Expanded(
                      flex: depthOutCount,
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  if (failBothCount > 0)
                    Expanded(
                      flex: failBothCount,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                  if (inProgressCount > 0)
                    Expanded(
                      flex: inProgressCount,
                      child: Container(color: const Color(0xFFFB923C)),
                    ),
                  if (pendingCount > 0)
                    Expanded(
                      flex: pendingCount,
                      child: Container(color: const Color(0xFF64748B)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // QC Legend & Counter Grid
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildQCChip(
                color: const Color(0xFF2ECC71),
                title: 'Ideal Pass',
                count: idealCount,
                percent: (idealCount / total * 100),
                desc: 'Kedalaman & Lebar Sesuai',
              ),
              _buildQCChip(
                color: const Color(0xFF3B82F6),
                title: 'Parit Terlalu Lebar',
                count: overwidthCount,
                percent: (overwidthCount / total * 100),
                desc: 'Kedalaman Pas, Lebar > 110cm',
              ),
              _buildQCChip(
                color: const Color(0xFFF59E0B),
                title: 'Kedalaman Out of Spec',
                count: depthOutCount,
                percent: (depthOutCount / total * 100),
                desc: 'Lebar Pas, Kedalaman di luar ±10%',
              ),
              _buildQCChip(
                color: const Color(0xFFEF4444),
                title: 'Gagal Keduanya',
                count: failBothCount,
                percent: (failBothCount / total * 100),
                desc: 'Kedalaman & Lebar Gagal',
              ),
              _buildQCChip(
                color: const Color(0xFFFB923C),
                title: 'Sedang Dikerjakan',
                count: inProgressCount,
                percent: (inProgressCount / total * 100),
                desc: 'Sweep Progress 20–90%',
              ),
              _buildQCChip(
                color: const Color(0xFF64748B),
                title: 'Pending',
                count: pendingCount,
                percent: (pendingCount / total * 100),
                desc: 'Belum Dimulai (0%)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQCChip({
    required Color color,
    required String title,
    required int count,
    required double percent,
    required String desc,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count (${percent.toStringAsFixed(1)}%)',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
            Text(
              desc,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroStat({
    required String label,
    required String value,
    required String sublabel,
    required Color color,
    bool isLarge = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 28 : 22,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(SpotSummary summary, SpotConfig config) {
    final intFormat = NumberFormat('#,##0');
    final isCrumbling = summary.isCrumbling;
    final speedDiff = summary.speedSpotsPerHour - config.targetSpeedSpotsPerHour;
    final isSpeedAboveTarget = speedDiff >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1150
            ? 4
            : (constraints.maxWidth > 650 ? 2 : 1);

        final childAspectRatio = crossAxisCount == 4
            ? (constraints.maxWidth > 1400 ? 1.6 : 1.45)
            : (crossAxisCount == 2 ? 1.6 : 2.0);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: [
            MetricCard(
              title: isCrumbling ? 'Panjang & Luas Galian' : 'Total Spot (Ha)',
              value: isCrumbling
                  ? summary.doneLengthMeters.toStringAsFixed(1)
                  : summary.totalAreaHa.toStringAsFixed(4),
              unit: isCrumbling ? 'm' : 'Ha',
              subtitle: isCrumbling
                  ? 'Luas: ${summary.totalAreaHa.toStringAsFixed(3)} Ha (${intFormat.format(summary.totalAreaM2)} m² • Spacing ${config.spotLength.toStringAsFixed(0)}m)'
                  : 'Formula: (${config.spotLength}x${config.spotWidth}m) x ${summary.doneSpots} spot',
              icon: isCrumbling ? Icons.straighten : Icons.square_foot,
              accentColor: AppColors.statusDone,
              gradientColors: const [Color(0xFF00E676), Color(0xFF00BCD4)],
              trailingBadge: isCrumbling
                  ? StatusBadge.done(label: '${summary.totalAreaHa.toStringAsFixed(3)} Ha')
                  : StatusBadge.done(label: '${config.spotAreaM2.toStringAsFixed(2)} m²'),
            ),
            MetricCard(
              title: isCrumbling ? 'Rata-rata Kedalaman' : 'Workhours',
              value: isCrumbling
                  ? summary.averageDepth.toStringAsFixed(1)
                  : summary.activeWorkHours.toStringAsFixed(1),
              unit: isCrumbling ? 'cm' : 'Jam',
              subtitle: isCrumbling
                  ? 'Target: ${config.targetDepthCm.toStringAsFixed(0)} cm (Tol: ${config.minAllowedDepthCm.toStringAsFixed(0)}–${config.maxAllowedDepthCm.toStringAsFixed(0)} cm)'
                  : 'Aktif: ${summary.activeWorkHours.toStringAsFixed(1)}j | Idle: ${summary.idleHours.toStringAsFixed(1)}j',
              icon: isCrumbling ? Icons.vertical_align_bottom : Icons.timer,
              accentColor: AppColors.accentCyan,
              trailingBadge: isCrumbling
                  ? StatusBadge(
                      label: (summary.averageDepth >= config.minAllowedDepthCm &&
                              summary.averageDepth <= config.maxAllowedDepthCm)
                          ? 'Kedalaman Ideal'
                          : 'Perlu Penyesuaian',
                      color: (summary.averageDepth >= config.minAllowedDepthCm &&
                              summary.averageDepth <= config.maxAllowedDepthCm)
                          ? AppColors.statusDone
                          : AppColors.statusPending,
                    )
                  : StatusBadge.cyan(label: 'Sesi Aktif'),
            ),
            MetricCard(
              title: isCrumbling ? 'Presisi & Deviasi As' : 'Workspeed',
              value: isCrumbling
                  ? '±${summary.avgDeviationCm.toStringAsFixed(1)}'
                  : summary.speedSpotsPerHour.toStringAsFixed(1),
              unit: isCrumbling ? 'cm' : 'spot/jam',
              subtitle: isCrumbling
                  ? 'Rata-rata Lebar Parit: ${summary.avgTrenchWidthCm.toStringAsFixed(1)} cm'
                  : '${summary.avgSecondsPerSpot.toStringAsFixed(1)} dtk/galian • ${summary.speedHaPerHour.toStringAsFixed(3)} Ha/j',
              icon: isCrumbling ? Icons.center_focus_strong : Icons.speed,
              accentColor: isCrumbling
                  ? (summary.avgDeviationCm < 20 ? AppColors.statusDone : AppColors.statusPending)
                  : (isSpeedAboveTarget ? AppColors.statusDone : AppColors.statusPending),
              trailingBadge: isCrumbling
                  ? StatusBadge(
                      label: summary.avgDeviationCm < 20 ? 'Presisi Baik' : 'Deviasi Sedang',
                      color: summary.avgDeviationCm < 20
                          ? AppColors.statusDone
                          : AppColors.statusPending,
                    )
                  : StatusBadge(
                      label: isSpeedAboveTarget
                          ? '+${speedDiff.toStringAsFixed(0)} vs Target'
                          : '${speedDiff.toStringAsFixed(0)} vs Target',
                      color: isSpeedAboveTarget ? AppColors.statusDone : AppColors.statusPending,
                      icon: isSpeedAboveTarget ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
            ),
            MetricCard(
              title: isCrumbling ? 'Kecepatan Operasional' : 'Progress Selesai',
              value: isCrumbling
                  ? summary.speedMetersPerHour.toStringAsFixed(1)
                  : '${summary.completionRate.toStringAsFixed(1)}%',
              unit: isCrumbling ? 'm/jam' : '',
              subtitle: isCrumbling
                  ? '${summary.activeWorkHours.toStringAsFixed(1)} Jam Aktif • ${summary.speedHaPerHour.toStringAsFixed(3)} Ha/j'
                  : '${intFormat.format(summary.doneSpots)} done • ${intFormat.format(summary.pendingSpots)} pending',
              icon: isCrumbling ? Icons.speed : Icons.pie_chart_outline,
              accentColor: AppColors.primaryBlue,
              trailingBadge: StatusBadge(
                label: isCrumbling
                    ? '${intFormat.format(summary.doneSpots)} Segmen'
                    : '${intFormat.format(summary.totalSpots)} Total',
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailyChartCard(SpotSummary summary) {
    if (summary.dailyBreakdown.isEmpty) {
      return Container(
        height: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('Tidak ada data shift harian untuk ditampilkan',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final daily = summary.dailyBreakdown;
    final isCrumbling = summary.isCrumbling;

    double maxVal = 0;
    for (var d in daily) {
      final v = isCrumbling ? d.metersDone : d.spotsDone.toDouble();
      if (v > maxVal) maxVal = v;
    }
    final maxY = ((maxVal / 200).ceil() * 200.0) + 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
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
                  const Icon(Icons.bar_chart, color: AppColors.accentCyan, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isCrumbling
                        ? 'PRODUKTIVITAS HARIAN (PANJANG METER PER HARI)'
                        : 'PRODUKTIVITAS HARIAN (SPOT DONE PER HARI)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              StatusBadge.cyan(label: '${daily.length} Hari Kerja'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCrumbling
                ? 'Grafik panjang galian parit (meter) yang diselesaikan setiap tanggal'
                : 'Grafik total galian titik (spot) yang diselesaikan setiap tanggal',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceElevated,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = daily[group.x.toInt()];
                      return BarTooltipItem(
                        '${item.date}\n',
                        const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                        children: [
                          TextSpan(
                            text: isCrumbling
                                ? '${item.metersDone.toStringAsFixed(1)} m (${item.spotsDone} segmen)\n'
                                : '${item.spotsDone} spots (${item.areaHa.toStringAsFixed(3)} Ha)\n',
                            style: const TextStyle(color: AppColors.statusDone, fontSize: 11),
                          ),
                          TextSpan(
                            text: isCrumbling
                                ? '${item.activeHours.toStringAsFixed(1)} Jam • ${item.metersPerHour.toStringAsFixed(0)} m/jam'
                                : '${item.activeHours.toStringAsFixed(1)} Jam • ${item.spotsPerHour.toStringAsFixed(0)} spot/jam',
                            style: const TextStyle(color: AppColors.accentCyan, fontSize: 11),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= daily.length) return const SizedBox.shrink();
                        final dateStr = daily[index].date;
                        final parts = dateStr.split('-');
                        final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : dateStr;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          isCrumbling
                              ? '${NumberFormat.compact().format(value)}m'
                              : NumberFormat.compact().format(value),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: daily.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final barValue = isCrumbling ? item.metersDone : item.spotsDone.toDouble();
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: barValue,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isCrumbling
                              ? const [Color(0xFFEA580C), Color(0xFFFB923C)]
                              : const [Color(0xFF009A08), Color(0xFF00E676)],
                        ),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorLeaderboard(SpotSummary summary) {
    final ops = summary.operatorBreakdown;
    final isCrumbling = summary.isCrumbling;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
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
                  const Icon(Icons.badge_outlined, color: AppColors.accentCyan, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'KONTRIBUSI OPERATOR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              StatusBadge.cyan(label: '${ops.length} Operator'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCrumbling
                ? 'Rincian meter galian dan kecepatan tiap operator alat berat'
                : 'Rincian galian dan kecepatan tiap operator alat berat',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          if (ops.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Tidak ada data operator',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ops.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.borderSubtle, height: 16),
              itemBuilder: (context, index) {
                final op = ops[index];
                final percent = summary.doneSpots > 0
                    ? (op.spotsCount / summary.doneSpots * 100)
                    : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.surfaceElevated,
                              child: Text(
                                '#${index + 1}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentCyan),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              op.operatorId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isCrumbling
                              ? '${op.metersDone.toStringAsFixed(1)} m (${percent.toStringAsFixed(1)}%)'
                              : '${op.spotsCount} spot (${percent.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusDone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent / 100.0,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCrumbling ? const Color(0xFFFB923C) : AppColors.accentCyan,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Luas: ${op.areaHa.toStringAsFixed(3)} Ha',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          isCrumbling
                              ? '${op.activeHours.toStringAsFixed(1)} Jam • ${op.metersPerHour.toStringAsFixed(0)} m/jam'
                              : '${op.activeHours.toStringAsFixed(1)} Jam • ${op.spotsPerHour.toStringAsFixed(0)} spot/jam',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOperationalDetailsCard(SpotSummary summary) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');
    final minDateStr =
        summary.minTimestamp != null ? dateFormat.format(summary.minTimestamp!) : '-';
    final maxDateStr =
        summary.maxTimestamp != null ? dateFormat.format(summary.maxTimestamp!) : '-';
    final isCrumbling = summary.isCrumbling;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.accentCyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'DETAIL TELEMETRI & PERALATAN ALAT BERAT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildDetailItem(
                label: 'Waktu Galian Pertama',
                value: minDateStr,
                icon: Icons.play_arrow_outlined,
              ),
              _buildDetailItem(
                label: 'Waktu Galian Terakhir',
                value: maxDateStr,
                icon: Icons.stop_outlined,
              ),
              _buildDetailItem(
                label: 'Equipment / Excavator ID',
                value: summary.equipmentCounts.keys.join(', '),
                icon: Icons.precision_manufacturing_outlined,
              ),
              _buildDetailItem(
                label: isCrumbling ? 'Rata-rata Presisi As' : 'Rata-rata Akurasi RTK',
                value: isCrumbling
                    ? '±${summary.avgDeviationCm.toStringAsFixed(1)} cm'
                    : '${summary.averageAccuracy.toStringAsFixed(1)} mm',
                icon: Icons.gps_fixed,
              ),
              _buildDetailItem(
                label: isCrumbling ? 'Rata-rata Kedalaman' : 'Rata-rata Kedalaman Spot',
                value: isCrumbling
                    ? '${summary.averageDepth.toStringAsFixed(1)} cm'
                    : '${summary.averageDepth.toStringAsFixed(2)} m',
                icon: Icons.vertical_align_bottom,
              ),
              if (isCrumbling)
                _buildDetailItem(
                  label: 'Rata-rata Lebar Parit',
                  value: '${summary.avgTrenchWidthCm.toStringAsFixed(1)} cm',
                  icon: Icons.swap_horiz,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 64, color: AppColors.accentCyan),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Data GeoJSON',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan unggah file GeoJSON galian Anda atau muat dataset contoh di bawah ini untuk melihat hasil perhitungan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(datasetProvider.notifier).loadSampleCrumblingGeoJson(),
                  icon: const Icon(Icons.alt_route),
                  label: const Text('Muat Contoh Crumbling (Badak Culah)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB923C),
                    foregroundColor: const Color(0xFF0B1017),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.read(datasetProvider.notifier).loadSampleGeoJson(),
                  icon: const Icon(Icons.pin_drop),
                  label: const Text('Muat Contoh Spot (SBAE035803)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
