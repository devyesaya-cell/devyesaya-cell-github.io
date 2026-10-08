import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class AppColors {
  // Industrial Dark SCADA Palette
  static const Color background = Color(0xFF0B1017);
  static const Color surface = Color(0xFF131B27);
  static const Color surfaceElevated = Color(0xFF1B2536);
  static const Color surfaceCard = Color(0xFF162030);
  static const Color border = Color(0xFF243248);
  static const Color borderSubtle = Color(0xFF1A2638);

  // Brand Accents
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentCyanGlow = Color(0x3300E5FF);
  static const Color primaryBlue = Color(0xFF2979FF);

  // Status & Telemetry
  static const Color statusDone = Color(0xFF00E676);
  static const Color statusDoneDark = Color(0xFF009A08);
  static const Color statusPending = Color(0xFFFF9100);
  static const Color statusError = Color(0xFFFF5252);
  static const Color statusInfo = Color(0xFF40C4FF);
  static const Color statusPurple = Color(0xFFB388FF);

  // Typography Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textMuted = Color(0xFF546E7A);
  static const Color textAccent = Color(0xFF80DEEA);

  // Gradients
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF162132),
      Color(0xFF111925),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
  );

  static const LinearGradient doneGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
  );

  static const LinearGradient statGoldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF9100)],
  );
}

class AppThemeData {
  final Color cardBackground;
  final Color cardBorder;
  final double overlayOpacity;
  final Color titleColor;
  final Color subtitleColor;
  final Color labelColor;
  final Color inputFill;
  final Color inputBorder;
  final Color inputFocusedBorder;
  final Color inputHintText;
  final Color inputTextColor;
  final Color inputIconColor;
  final Color visibilityIconColor;
  final Color dropdownBackground;
  final Color dropdownIcon;
  final Color dropdownItemText;
  final Color dropdownHintText;
  final Color modeButtonBackground;
  final Color modeButtonSelectedBackground;
  final Color modeButtonText;
  final Color modeButtonSelectedText;
  final Color primaryButtonBackground;
  final Color primaryButtonText;
  final Color primaryButtonShadow;
  final Color usbLabelColor;
  final Color logoBadgeBackground;
  final Color logoBadgeBorder;
  final Color pageBackground;
  final Color surfaceColor;
  final Color textOnSurface;
  final Color textSecondary;
  final Color loadingIndicatorColor;
  final Color appBarBackground;
  final Color appBarForeground;
  final Color appBarAccent;
  final Color iconBoxBackground;
  final Color iconBoxIcon;
  final Color menuBackground;
  final Color menuBorder;
  final Color menuSelectedBackground;
  final Color menuSelectedIcon;
  final Color menuSelectedText;
  final Color menuUnselectedIcon;
  final Color menuUnselectedText;
  final Color sectionHeaderColor;
  final Color dateTimeGradientStart;
  final Color dateTimeGradientEnd;
  final Color dateTimeBorder;
  final Color dateTimeClockColor;
  final Color dateTimeDateColor;
  final Color dateTimeIconBackground;
  final Color cardSurface;
  final Color cardBorderColor;
  final Color dialogBackground;
  final Color dividerColor;
  final Color mapGrid;
  final bool hasGlowEffect;

  const AppThemeData({
    required this.cardBackground,
    required this.cardBorder,
    required this.overlayOpacity,
    required this.titleColor,
    required this.subtitleColor,
    required this.labelColor,
    required this.inputFill,
    required this.inputBorder,
    required this.inputFocusedBorder,
    required this.inputHintText,
    required this.inputTextColor,
    required this.inputIconColor,
    required this.visibilityIconColor,
    required this.dropdownBackground,
    required this.dropdownIcon,
    required this.dropdownItemText,
    required this.dropdownHintText,
    required this.modeButtonBackground,
    required this.modeButtonSelectedBackground,
    required this.modeButtonText,
    required this.modeButtonSelectedText,
    required this.primaryButtonBackground,
    required this.primaryButtonText,
    required this.primaryButtonShadow,
    required this.usbLabelColor,
    required this.logoBadgeBackground,
    required this.logoBadgeBorder,
    required this.pageBackground,
    required this.surfaceColor,
    required this.textOnSurface,
    required this.textSecondary,
    required this.loadingIndicatorColor,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.appBarAccent,
    required this.iconBoxBackground,
    required this.iconBoxIcon,
    required this.menuBackground,
    required this.menuBorder,
    required this.menuSelectedBackground,
    required this.menuSelectedIcon,
    required this.menuSelectedText,
    required this.menuUnselectedIcon,
    required this.menuUnselectedText,
    required this.sectionHeaderColor,
    required this.dateTimeGradientStart,
    required this.dateTimeGradientEnd,
    required this.dateTimeBorder,
    required this.dateTimeClockColor,
    required this.dateTimeDateColor,
    required this.dateTimeIconBackground,
    required this.cardSurface,
    required this.cardBorderColor,
    required this.dialogBackground,
    required this.dividerColor,
    required this.mapGrid,
    required this.hasGlowEffect,
  });
}

class AppTheme {
  static const AppThemeData dark = AppThemeData(
    cardBackground: Color(0xFF1A2235),
    cardBorder: Color(0xFF2A3750),
    overlayOpacity: 0.40,
    titleColor: Color(0xFFFFFFFF),
    subtitleColor: Color(0xFF8A94A6),
    labelColor: Color(0xFF00BCD4),
    inputFill: Color(0xFF222B40),
    inputBorder: Color(0xFF2A3040),
    inputFocusedBorder: Color(0xFF00BCD4),
    inputHintText: Color(0xFF8A94A6),
    inputTextColor: Color(0xFFFFFFFF),
    inputIconColor: Color(0xFF8A94A6),
    visibilityIconColor: Color(0xFF8A94A6),
    dropdownBackground: Color(0xFF1A2235),
    dropdownIcon: Color(0xFF00BCD4),
    dropdownItemText: Color(0xFFFFFFFF),
    dropdownHintText: Color(0xFF8A94A6),
    modeButtonBackground: Colors.transparent,
    modeButtonSelectedBackground: Color(0xFF00BCD4),
    modeButtonText: Color(0xFF8A94A6),
    modeButtonSelectedText: Color(0xFF0D1118),
    primaryButtonBackground: Color(0xFF00BCD4),
    primaryButtonText: Color(0xFF0D1118),
    primaryButtonShadow: Color(0x8000BCD4),
    usbLabelColor: Color(0xFF8A94A6),
    logoBadgeBackground: Color(0x99000000),
    logoBadgeBorder: Color(0xFF00BCD4),
    pageBackground: Color(0xFF0D1118),
    surfaceColor: Color(0xFF1A2235),
    textOnSurface: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8A94A6),
    loadingIndicatorColor: Color(0xFF00BCD4),
    appBarBackground: Color(0xFF1C2030),
    appBarForeground: Color(0xFFFFFFFF),
    appBarAccent: Color(0xFF00BCD4),
    iconBoxBackground: Color(0xFF222B40),
    iconBoxIcon: Color(0xFF00BCD4),
    menuBackground: Color(0xFF0D1118),
    menuBorder: Color(0xFF2A3750),
    menuSelectedBackground: Color(0xFF1C2030),
    menuSelectedIcon: Color(0xFF00BCD4),
    menuSelectedText: Color(0xFFFFFFFF),
    menuUnselectedIcon: Color(0xFF8A94A6),
    menuUnselectedText: Color(0xFF8A94A6),
    sectionHeaderColor: Color(0xFF8A94A6),
    dateTimeGradientStart: Color(0xFF1A2235),
    dateTimeGradientEnd: Color(0xFF0D1118),
    dateTimeBorder: Color(0x4D00BCD4),
    dateTimeClockColor: Color(0xFF00BCD4),
    dateTimeDateColor: Color(0xFF8A94A6),
    dateTimeIconBackground: Color(0x1A00BCD4),
    cardSurface: Color(0xFF1A2235),
    cardBorderColor: Color(0xFF2A3750),
    dialogBackground: Color(0xFF1A2235),
    dividerColor: Color(0xFF2A3040),
    mapGrid: Color(0xFF162032),
    hasGlowEffect: true,
  );

  static const AppThemeData light = AppThemeData(
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFF00BCD4),
    overlayOpacity: 0.15,
    titleColor: Color(0xFF1A1A2E),
    subtitleColor: Color(0xFF7A8290),
    labelColor: Color(0xFF00BCD4),
    inputFill: Color(0xFFF5F7FA),
    inputBorder: Color(0xFFD0D4DA),
    inputFocusedBorder: Color(0xFF00BCD4),
    inputHintText: Color(0xFF7A8290),
    inputTextColor: Color(0xFF1A1A2E),
    inputIconColor: Color(0xFF7A8290),
    visibilityIconColor: Color(0xFF7A8290),
    dropdownBackground: Color(0xFFFFFFFF),
    dropdownIcon: Color(0xFF00BCD4),
    dropdownItemText: Color(0xFF1A1A2E),
    dropdownHintText: Color(0xFF7A8290),
    modeButtonBackground: Colors.transparent,
    modeButtonSelectedBackground: Color(0xFF00BCD4),
    modeButtonText: Color(0xFF7A8290),
    modeButtonSelectedText: Color(0xFFFFFFFF),
    primaryButtonBackground: Color(0xFF00BCD4),
    primaryButtonText: Color(0xFFFFFFFF),
    primaryButtonShadow: Color(0x6000BCD4),
    usbLabelColor: Color(0xFF7A8290),
    logoBadgeBackground: Color(0xCCFFFFFF),
    logoBadgeBorder: Color(0xFF00BCD4),
    pageBackground: Color(0xFFE8ECF0),
    surfaceColor: Color(0xFFFFFFFF),
    textOnSurface: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF7A8290),
    loadingIndicatorColor: Color(0xFF00BCD4),
    appBarBackground: Color(0xFFFFFFFF),
    appBarForeground: Color(0xFF1A1A2E),
    appBarAccent: Color(0xFF00BCD4),
    iconBoxBackground: Color(0xFFF5F7FA),
    iconBoxIcon: Color(0xFF00BCD4),
    menuBackground: Color(0xFFFFFFFF),
    menuBorder: Color(0xFFD0D4DA),
    menuSelectedBackground: Color(0xFFF5F7FA),
    menuSelectedIcon: Color(0xFF00BCD4),
    menuSelectedText: Color(0xFF1A1A2E),
    menuUnselectedIcon: Color(0xFF7A8290),
    menuUnselectedText: Color(0xFF7A8290),
    sectionHeaderColor: Color(0xFF7A8290),
    dateTimeGradientStart: Color(0xFFF5F7FA),
    dateTimeGradientEnd: Color(0xFFFFFFFF),
    dateTimeBorder: Color(0x6000BCD4),
    dateTimeClockColor: Color(0xFF00BCD4),
    dateTimeDateColor: Color(0xFF7A8290),
    dateTimeIconBackground: Color(0x1A00BCD4),
    cardSurface: Color(0xFFFFFFFF),
    cardBorderColor: Color(0xFF00BCD4),
    dialogBackground: Color(0xFFFFFFFF),
    dividerColor: Color(0xFFD0D4DA),
    mapGrid: Color(0xFFD5DCE4),
    hasGlowEffect: false,
  );

  static AppThemeData of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark ? dark : light;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0284C7),
        secondary: Color(0xFF2563EB),
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
        error: Color(0xFFDC2626),
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentCyan,
        secondary: AppColors.primaryBlue,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.statusError,
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentCyan,
          foregroundColor: const Color(0xFF0B1017),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }
}
