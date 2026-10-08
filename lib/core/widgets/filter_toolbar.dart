import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/spot_model.dart';
import '../../features/spot_provider.dart';
import '../theme/app_theme.dart';

class FilterToolbar extends ConsumerWidget {
  const FilterToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final globalSummary = ref.watch(globalSummaryProvider);
    final filteredSpots = ref.watch(filteredSpotsProvider);
    final isCrumbling = globalSummary.isCrumbling;

    // Collect unique operators and dates
    final operators = globalSummary.operatorBreakdown.map((e) => e.operatorId).toList();
    final dates = globalSummary.dailyBreakdown.map((e) => e.date).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Filter Chips (Status)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  _buildFilterChip(
                    label: 'Semua (${globalSummary.totalSpots})',
                    isSelected: filter.status == 'all',
                    color: AppColors.accentCyan,
                    onSelected: () => ref.read(filterProvider.notifier).setStatus('all'),
                  ),
                  _buildFilterChip(
                    label: 'Done (${globalSummary.doneSpots})',
                    isSelected: filter.status == 'done',
                    color: AppColors.statusDone,
                    onSelected: () => ref.read(filterProvider.notifier).setStatus('done'),
                  ),
                  if (isCrumbling && globalSummary.inProgressSpots > 0)
                    _buildFilterChip(
                      label: 'In Progress (${globalSummary.inProgressSpots})',
                      isSelected: filter.status == 'in_progress',
                      color: const Color(0xFFFB923C),
                      onSelected: () =>
                          ref.read(filterProvider.notifier).setStatus('in_progress'),
                    ),
                  _buildFilterChip(
                    label: 'Pending (${globalSummary.pendingSpots})',
                    isSelected: filter.status == 'pending',
                    color: AppColors.statusPending,
                    onSelected: () => ref.read(filterProvider.notifier).setStatus('pending'),
                  ),
                ],
              ),

              // Dropdowns & Search
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Operator Dropdown
                  if (operators.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: filter.operatorId ?? 'all',
                          dropdownColor: AppColors.surfaceElevated,
                          style:
                              const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.textSecondary, size: 18),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('Semua Operator'),
                            ),
                            ...operators.map((op) {
                              final cleanOp = op.replaceFirst('OP-', '');
                              return DropdownMenuItem(
                                value: cleanOp,
                                child: Text(op),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            ref.read(filterProvider.notifier).setOperator(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Date Dropdown
                  if (dates.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: filter.date ?? 'all',
                          dropdownColor: AppColors.surfaceElevated,
                          style:
                              const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          icon: const Icon(Icons.calendar_today,
                              color: AppColors.textSecondary, size: 14),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('Semua Tanggal'),
                            ),
                            ...dates.map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                )),
                          ],
                          onChanged: (val) {
                            ref.read(filterProvider.notifier).setDate(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Filtered count pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      isCrumbling
                          ? 'Tampil: ${filteredSpots.length} segmen'
                          : 'Tampil: ${filteredSpots.length} spot',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ),

                  if (filter.status != 'all' ||
                      filter.operatorId != null ||
                      filter.date != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Reset Filter',
                      icon: const Icon(Icons.refresh,
                          size: 18, color: AppColors.textMuted),
                      onPressed: () => ref.read(filterProvider.notifier).reset(),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Secondary Row for Crumbling QC 4-Quadrant Filter
          if (isCrumbling) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'QC 4-Kuadran: ',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
                _buildFilterChip(
                  label:
                      '🟢 Ideal (${globalSummary.qcDistribution[CrumblingQCStatus.idealPass] ?? 0})',
                  isSelected: filter.status == 'ideal',
                  color: const Color(0xFF2ECC71),
                  onSelected: () =>
                      ref.read(filterProvider.notifier).setStatus('ideal'),
                ),
                _buildFilterChip(
                  label:
                      '🔵 Overwidth (${globalSummary.qcDistribution[CrumblingQCStatus.overwidth] ?? 0})',
                  isSelected: filter.status == 'overwidth',
                  color: const Color(0xFF3B82F6),
                  onSelected: () =>
                      ref.read(filterProvider.notifier).setStatus('overwidth'),
                ),
                _buildFilterChip(
                  label:
                      '🟡 Kedalaman Out (${globalSummary.qcDistribution[CrumblingQCStatus.depthOutOfSpec] ?? 0})',
                  isSelected: filter.status == 'depth_out',
                  color: const Color(0xFFF59E0B),
                  onSelected: () =>
                      ref.read(filterProvider.notifier).setStatus('depth_out'),
                ),
                _buildFilterChip(
                  label:
                      '🔴 Gagal Keduanya (${globalSummary.qcDistribution[CrumblingQCStatus.failBoth] ?? 0})',
                  isSelected: filter.status == 'fail_both',
                  color: const Color(0xFFEF4444),
                  onSelected: () =>
                      ref.read(filterProvider.notifier).setStatus('fail_both'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
