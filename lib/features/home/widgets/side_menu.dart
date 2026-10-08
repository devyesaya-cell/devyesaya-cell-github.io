import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_theme.dart';
import '../../spot_provider.dart';

// --- State Management ---

class MenuNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // Default to Dashboard (index 0)
  }

  void setIndex(int index) {
    state = index;
  }
}

final selectedMenuProvider = NotifierProvider<MenuNotifier, int>(
  MenuNotifier.new,
);

// --- SideMenu Widget ---

class SideMenu extends ConsumerWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.25).clamp(240.0, 280.0);

    return Container(
      width: drawerWidth,
      decoration: BoxDecoration(
        color: theme.menuBackground,
        border: Border(
          right: BorderSide(color: theme.menuBorder, width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Logo Area
          _buildLogo(context, theme),

          // 2. Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // "Menu" section
                _buildSectionHeader('Menu', theme),
                _buildMenuItem(
                  context,
                  ref,
                  theme,
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                ),
                _buildMenuItem(
                  context,
                  ref,
                  theme,
                  index: 1,
                  icon: Icons.map_outlined,
                  label: 'Peta Galian (Map)',
                ),

                const SizedBox(height: 20),

                // "System" section
                _buildSectionHeader('System', theme),
                _buildMenuItem(
                  context,
                  ref,
                  theme,
                  index: 2,
                  icon: Icons.settings_outlined,
                  label: 'Konfigurasi (Config)',
                ),

                const SizedBox(height: 20),

                // System Status card (SPOT / CRUMBLING)
                _buildSystemStatus(ref, theme),

                const SizedBox(height: 12),

                // Light / Dark Theme Switcher
                _buildThemeToggle(context, ref, theme),
              ],
            ),
          ),

          // 3. Real-time Clock
          _DateTimeWidget(theme: theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.radar,
                color: Color(0xFF0B1017),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SPOT MONITORING',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: theme.textOnSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TOHO EGS • SCADA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: theme.appBarAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.sectionHeaderColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    WidgetRef ref,
    AppThemeData theme, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selectedIndex = ref.watch(selectedMenuProvider);
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () {
        ref.read(selectedMenuProvider.notifier).setIndex(index);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: isSelected
            ? BoxDecoration(
                color: theme.menuSelectedBackground,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(30),
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? theme.menuSelectedIcon : theme.menuUnselectedIcon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.menuSelectedText : theme.menuUnselectedText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus(WidgetRef ref, AppThemeData theme) {
    final datasetState = ref.watch(datasetProvider);
    final isCrumbling = datasetState.isCrumbling;

    final String modeLabel;
    final IconData modeIcon;
    final Color modeColor;

    if (isCrumbling) {
      modeLabel = 'CRUMBLING';
      modeIcon = Icons.school;
      modeColor = Colors.blue;
    } else {
      modeLabel = 'SPOT';
      modeIcon = Icons.settings_suggest;
      modeColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.cardBorderColor),
        ),
        child: Row(
          children: [
            Icon(modeIcon, size: 16, color: modeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SYSTEM MODE',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.sectionHeaderColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    modeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textOnSurface,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: modeColor,
                boxShadow: [
                  BoxShadow(
                    color: modeColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    WidgetRef ref,
    AppThemeData theme,
  ) {
    final currentMode = ref.watch(themeModeProvider);
    final isDark = currentMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.cardBorderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  size: 16,
                  color: isDark ? theme.appBarAccent : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                Text(
                  'TEMA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: theme.sectionHeaderColor,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.menuSelectedBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.cardBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      size: 13,
                      color:
                          isDark ? theme.appBarAccent : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isDark ? 'Gelap' : 'Terang',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.textOnSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Real-time Clock Widget ---

class _DateTimeWidget extends StatefulWidget {
  final AppThemeData theme;
  const _DateTimeWidget({required this.theme});

  @override
  State<_DateTimeWidget> createState() => _DateTimeWidgetState();
}

class _DateTimeWidgetState extends State<_DateTimeWidget> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Time: "HH:MM:SS"
    final timeString =
        "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}";

    // Month and weekday names
    const monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    const dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final monthString = monthNames[_now.month - 1];
    final dayString = dayNames[_now.weekday - 1];

    // Date: "Wed, 8 Oct 2026"
    final dateString = "$dayString, ${_now.day} $monthString ${_now.year}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.dateTimeGradientStart, theme.dateTimeGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dateTimeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: time + date stacked
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    timeString,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.dateTimeClockColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dateString,
                    style: TextStyle(
                      color: theme.dateTimeDateColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: clock icon in circle
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: theme.dateTimeIconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_filled,
              color: theme.dateTimeClockColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
