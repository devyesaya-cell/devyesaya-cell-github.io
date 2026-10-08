import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badge.dart';
import '../config/config_page.dart';
import '../dashboard/dashboard_page.dart';
import '../map/map_page.dart';
import '../spot_provider.dart';
import 'widgets/side_menu.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  Future<void> _quickUpload() async {
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
              content: Text('✅ File ${file.name} berhasil diunggah!'),
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final selectedIndex = ref.watch(selectedMenuProvider);
    final datasetState = ref.watch(datasetProvider);
    final summary = ref.watch(globalSummaryProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Page title and icons according to active side menu selection
    final String pageTitle;
    final IconData pageIcon;
    switch (selectedIndex) {
      case 0:
        pageTitle = 'EGS DASHBOARD';
        pageIcon = Icons.dashboard_outlined;
        break;
      case 1:
        pageTitle = 'PETA GALIAN (MAP LIBRE GIS)';
        pageIcon = Icons.map_outlined;
        break;
      case 2:
      default:
        pageTitle = 'KONFIGURASI & TOLERANSI QC';
        pageIcon = Icons.settings_outlined;
        break;
    }

    final modeLabel = datasetState.isCrumbling ? 'CRUMBLING' : 'SPOT';

    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Row(
        children: [
          // Left: Persistent Global Side Menu
          const SideMenu(),

          // Right: Content Area (Header + Subpage View)
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.appBarBackground,
                    border: Border(
                      bottom: BorderSide(color: theme.cardBorderColor, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                      // Active Page Title & Mode Badge
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: theme.iconBoxBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              pageIcon,
                              color: theme.iconBoxIcon,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pageTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: 16,
                                  color: theme.appBarForeground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SYSTEM MODE: $modeLabel',
                                style: TextStyle(
                                  color: theme.appBarAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Right Actions & Stats Pill
                      Row(
                        children: [
                          if (datasetState.datasetName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.cardSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.cardBorderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    datasetState.isCrumbling
                                        ? Icons.alt_route
                                        : Icons.place,
                                    size: 14,
                                    color: datasetState.isCrumbling
                                        ? const Color(0xFFFB923C)
                                        : theme.appBarAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    datasetState.datasetName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textOnSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(
                                    label: modeLabel,
                                    color: datasetState.isCrumbling
                                        ? const Color(0xFFFB923C)
                                        : theme.appBarAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    datasetState.isCrumbling
                                        ? '• ${summary.totalLengthMeters.toStringAsFixed(0)} m (${summary.totalAreaHa.toStringAsFixed(2)} Ha)'
                                        : '• ${summary.totalAreaHa.toStringAsFixed(3)} Ha',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00E676),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Sample data dropdown menu
                          PopupMenuButton<String>(
                            tooltip: 'Pilih Sampel Data',
                            color: theme.cardSurface,
                            icon: Icon(
                              Icons.folder_special_outlined,
                              color: theme.appBarAccent,
                              size: 20,
                            ),
                            onSelected: (val) {
                              if (val == 'crumbling') {
                                ref
                                    .read(datasetProvider.notifier)
                                    .loadSampleCrumblingGeoJson();
                              } else if (val == 'spot') {
                                ref
                                    .read(datasetProvider.notifier)
                                    .loadSampleGeoJson();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'crumbling',
                                child: Row(
                                  children: [
                                    const Icon(Icons.alt_route,
                                        size: 16, color: Color(0xFFFB923C)),
                                    const SizedBox(width: 8),
                                    Text('Sampel Crumbling (Badak Culah)',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textOnSurface)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'spot',
                                child: Row(
                                  children: [
                                    Icon(Icons.place,
                                        size: 16, color: theme.appBarAccent),
                                    const SizedBox(width: 8),
                                    Text('Sampel Spot (SBAE035803)',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textOnSurface)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),

                          // Quick upload button
                          ElevatedButton.icon(
                            onPressed: _quickUpload,
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Unggah GeoJSON'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Header theme quick toggle
                          IconButton(
                            tooltip: isDark ? 'Beralih ke Mode Terang' : 'Beralih ke Mode Gelap',
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: isDark ? const Color(0xFFF59E0B) : theme.appBarAccent,
                              size: 20,
                            ),
                            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                          ),
                        ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

                // Main Page Body (IndexedStack to preserve MapLibre state across menu switches)
                Expanded(
                  child: IndexedStack(
                    index: selectedIndex.clamp(0, 2),
                    children: [
                      DashboardPage(
                        onNavigateToMap: () =>
                            ref.read(selectedMenuProvider.notifier).setIndex(1),
                      ),
                      const MapPage(),
                      const ConfigPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
