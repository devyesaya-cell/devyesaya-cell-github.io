# Theme System & UI Architecture Reference

> **Toho EGS — Version 4.2.20 (Build 90)**  
> **Target File**: `lib/core/utils/app_theme.dart`  
> **Target Platform**: Android Industrial Tablet (10-inch Cab-Mounted Excavator Guidance System)

---

## 1. Overview & Architecture

The **Toho EGS** application uses a custom dual-theme system (**Dark SCADA** / **Light SCADA**) designed specifically for harsh outdoor mining and earthmoving environments. High contrast and visibility are maintained whether operating in direct sunlight or nighttime cab conditions.

The system is managed entirely through a single `AppThemeData` class and a static `AppTheme` accessor. There is **no reliance** on Flutter's built-in `ThemeData` — all color tokens and surface values are resolved manually via `AppTheme.of(context)`.

```
                  ┌───────────────────────────────┐
                  │    AppTheme (Static Accessor) │
                  └──────────────┬────────────────┘
                                 │
                 MediaQuery.platformBrightness
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
       ┌───────────────────┐           ┌───────────────────┐
       │   AppTheme.dark   │           │   AppTheme.light  │
       │    (Dark SCADA)   │           │   (Light SCADA)   │
       └───────────────────┘           └───────────────────┘
                 │                               │
                 └───────────────┬───────────────┘
                                 ▼
                     AppThemeData (All Tokens)
                                 │
                                 ▼
                    AppTheme.of(context).token
```

### 1.1 `AppThemeData` (Data Class)
A plain `const` data class holding **every** design token used across the application. Every UI widget reads its colors from this instance, eliminating arbitrary inline hex definitions.

### 1.2 `AppTheme` (Static Accessor)
```dart
class AppTheme {
  AppTheme._(); // Private constructor, static usage only

  static const AppThemeData dark = AppThemeData(...);
  static const AppThemeData light = AppThemeData(...);

  /// Resolves the active theme variant based on platform brightness.
  static AppThemeData of(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
```

### 1.3 Usage Pattern (Every Widget)
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final theme = AppTheme.of(context);

  return Container(
    color: theme.pageBackground,
    child: Text(
      'ACTIVE WORKFILE',
      style: TextStyle(
        color: theme.textOnSurface,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
```

---

## 2. Complete Token Reference

### 2.1 Login Card Tokens
Used on `LoginPage` (`lib/features/auth/pages/login_page.dart`) for authentication, mode selection, and access code authorization.

| Token | Dark (SCADA) | Light (SCADA) | Purpose |
|---|---|---|---|
| `cardBackground` | `0xFF1A2235` | `0xFFFFFFFF` | Login form card background surface |
| `cardBorder` | `0xFF2A3750` | `0xFF00BCD4` | Login card border outline |
| `overlayOpacity` | `0.40` | `0.15` | Background graphic overlay darkness |
| `titleColor` | `0xFFFFFFFF` | `0xFF1A1A2E` | Primary form header text |
| `subtitleColor` | `0xFF8A94A6` | `0xFF7A8290` | Subtitle / guidance note text |
| `labelColor` | `0xFF00BCD4` | `0xFF00BCD4` | Form field labels (Cyan/Teal accent) |
| `inputFill` | `0xFF222B40` | `0xFFF5F7FA` | Text field container background fill |
| `inputBorder` | `0xFF2A3040` | `0xFFD0D4DA` | Field border in normal state |
| `inputFocusedBorder` | `0xFF00BCD4` | `0xFF00BCD4` | Field border when focused/active |
| `inputHintText` | `0xFF8A94A6` | `0xFF7A8290` | Placeholder hint text |
| `inputTextColor` | `0xFFFFFFFF` | `0xFF1A1A2E` | Typed user input text |
| `inputIconColor` | `0xFF8A94A6` | `0xFF7A8290` | Leading icons inside form fields |
| `visibilityIconColor`| `0xFF8A94A6` | `0xFF7A8290` | Password visibility toggle icon |
| `dropdownBackground` | `0xFF1A2235` | `0xFFFFFFFF` | Dropdown popup surface background |
| `dropdownIcon` | `0xFF00BCD4` | `0xFF00BCD4` | Dropdown expand/collapse arrow |
| `dropdownItemText` | `0xFFFFFFFF` | `0xFF1A1A2E` | Dropdown selection item text |
| `dropdownHintText` | `0xFF8A94A6` | `0xFF7A8290` | Dropdown placeholder text |
| `modeButtonBackground` | `Colors.transparent` | `Colors.transparent` | Unselected operational mode button fill |
| `modeButtonSelectedBackground` | `0xFF00BCD4` | `0xFF00BCD4` | Selected operational mode button fill |
| `modeButtonText` | `0xFF8A94A6` | `0xFF7A8290` | Unselected operational mode button text |
| `modeButtonSelectedText` | `0xFF0D1118` | `0xFFFFFFFF` | Selected operational mode button text |
| `primaryButtonBackground` | `0xFF00BCD4` | `0xFF00BCD4` | Main CTA button background (Sign In) |
| `primaryButtonText` | `0xFF0D1118` | `0xFFFFFFFF` | Main CTA button typography |
| `primaryButtonShadow` | `0x8000BCD4` | `0x6000BCD4` | Glow/drop shadow color for CTA button |
| `usbLabelColor` | `0xFF8A94A6` | `0xFF7A8290` | Hardware USB status label on login card |
| `logoBadgeBackground` | `0x99000000` | `0xCCFFFFFF` | System logo badge background |
| `logoBadgeBorder` | `0xFF00BCD4` | `0xFF00BCD4` | System logo badge border outline |

### 2.2 Global Layout Tokens
Standard tokens applied across top-level screens, pages, and content wrappers.

| Token | Dark (SCADA) | Light (SCADA) | Purpose |
|---|---|---|---|
| `pageBackground` | `0xFF0D1118` | `0xFFE8ECF0` | Scaffold and base application background |
| `surfaceColor` | `0xFF1A2235` | `0xFFFFFFFF` | Surface of cards, panels, and side drawer |
| `textOnSurface` | `0xFFFFFFFF` | `0xFF1A1A2E` | Primary typography placed on card/surface |
| `textSecondary` | `0xFF8A94A6` | `0xFF7A8290` | Muted, caption, and secondary typography |
| `loadingIndicatorColor` | `0xFF00BCD4` | `0xFF00BCD4` | Circular progress indicator spinner color |

### 2.3 AppBar Tokens
Used across global page headers inside `HomePage` (`lib/features/home/pages/home_page.dart`) and sub-pages.

| Token | Dark (SCADA) | Light (SCADA) | Purpose |
|---|---|---|---|
| `appBarBackground` | `0xFF1C2030` | `0xFFFFFFFF` | AppBar background container |
| `appBarForeground` | `0xFFFFFFFF` | `0xFF1A1A2E` | Main page title and icon foreground |
| `appBarAccent` | `0xFF00BCD4` | `0xFF00BCD4` | Subtitle accent & operational mode label |
| `iconBoxBackground` | `0xFF222B40` | `0xFFF5F7FA` | Rounded square container for page icon |
| `iconBoxIcon` | `0xFF00BCD4` | `0xFF00BCD4` | Material icon inside the icon box |

### 2.4 Side Menu Tokens
Used in `SideMenu` (`lib/features/home/widgets/side_menu.dart`) navigation drawer.

| Token | Dark (SCADA) | Light (SCADA) | Purpose |
|---|---|---|---|
| `menuBackground` | `0xFF0D1118` | `0xFFFFFFFF` | Left navigation drawer background |
| `menuBorder` | `0xFF2A3750` | `0xFFD0D4DA` | Vertical dividing border on the right edge |
| `menuSelectedBackground` | `0xFF1C2030` | `0xFFF5F7FA` | Pill background for active menu selection |
| `menuSelectedIcon` | `0xFF00BCD4` | `0xFF00BCD4` | Icon color for active menu item |
| `menuSelectedText` | `0xFFFFFFFF` | `0xFF1A1A2E` | Typography for active menu item |
| `menuUnselectedIcon` | `0xFF8A94A6` | `0xFF7A8290` | Icon color for inactive menu items |
| `menuUnselectedText` | `0xFF8A94A6` | `0xFF7A8290` | Typography for inactive menu items |
| `sectionHeaderColor` | `0xFF8A94A6` | `0xFF7A8290` | Group headers (`MENU`, `SYSTEM`) |

### 2.5 DateTime Widget Tokens
Used in the persistent live cab clock at the bottom of `SideMenu`.

| Token | Dark (SCADA) | Light (SCADA) | Purpose |
|---|---|---|---|
| `dateTimeGradientStart` | `0xFF1A2235` | `0xFFF5F7FA` | Linear gradient top-left start |
| `dateTimeGradientEnd` | `0xFF0D1118` | `0xFFFFFFFF` | Linear gradient bottom-right end |
| `dateTimeBorder` | `0x4D00BCD4` | `0x6000BCD4` | Card boundary border |
| `dateTimeClockColor` | `0xFF00BCD4` | `0xFF00BCD4` | High-visibility HH:mm:ss digital time digits |
| `dateTimeDateColor` | `0xFF8A94A6` | `0xFF7A8290` | Date subtitle text (`Wed, 7 Oct 2026`) |
| `dateTimeIconBackground` | `0x1A00BCD4` | `0x1A00BCD4` | Circular badge container behind clock icon |

### 2.6 Generic Card & Dialog Tokens

| Token | Dark (SCADA) | Light (SCADA) | Purpose |
|---|---|---|---|
| `cardSurface` | `0xFF1A2235` | `0xFFFFFFFF` | Standard card surface background |
| `cardBorderColor` | `0xFF2A3750` | `0xFF00BCD4` | Standard card border outline |
| `dialogBackground` | `0xFF1A2235` | `0xFFFFFFFF` | Modal dialog card background |
| `dividerColor` | `0xFF2A3040` | `0xFFD0D4DA` | Horizontal and vertical partition lines |

### 2.7 SCADA Specifics

| Token | Dark (SCADA) | Light (SCADA) | Purpose |
|---|---|---|---|
| `mapGrid` | `0xFF162032` | `0xFFD5DCE4` | Vector tile and radar background gridlines |
| `hasGlowEffect` | `true` | `false` | Enables neon teal shadows on active states |

---

## 3. SideMenu Navigation Architecture

The `SideMenu` represents the primary navigation structure of the application:

```
┌───────────────────────────────────────────────┐
│ [Banner Logo: images/banner.png]              │
├───────────────────────────────────────────────┤
│ MENU                                          │
│   📁  Work Files       (Index 0)              │
│   📊  Dashboard        (Index 1 - Default)    │
│   📈  Timesheet        (Index 2)              │
│   🔔  Voice Logs       (Index 3 - Premium)    │
│   🎓  Training         (Index 5)              │
├───────────────────────────────────────────────┤
│ SYSTEM                                        │
│   ⚙️  Setup            (Index 4)              │
├───────────────────────────────────────────────┤
│ [System Mode Card: SPOT / CRUMBLING / MAINT]  │
├───────────────────────────────────────────────┤
│ [DateTimeWidget: 11:58:32 - Wed, 7 Oct 2026]  │
└───────────────────────────────────────────────┘
```

### 3.1 System Mode Status Indicators (Fixed Semantic Colors)
Displayed in the dedicated System Mode card inside `SideMenu`:
- **SPOT Mode**: `Colors.orange` (`Icons.settings_suggest`)
- **CRUMBLING Mode**: `Colors.blue` (`Icons.school`)
- **MAINTENANCE Mode**: `Colors.red` (`Icons.build`)

### 3.2 Real-Time Cab Clock (`_DateTimeWidget`)
- Powered by a periodic 1-second `Timer`.
- Formatted as 24-hour digital clock: `HH:mm:ss` (`fontSize: 22`, `letterSpacing: 2.0`, `theme.dateTimeClockColor`).
- Calendar line: `DayName, DD Month YYYY` (`theme.dateTimeDateColor`).

---

## 4. Standard AppBar Pattern (Non-Tabbed Pages)

Every top-level page inside `HomePage` adheres to this standardized layout:

```dart
appBar: AppBar(
  backgroundColor: theme.appBarBackground,
  foregroundColor: theme.appBarForeground,
  elevation: 0,
  title: Row(
    children: [
      // 1. Icon Box
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.iconBoxBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.dashboard, color: theme.iconBoxIcon, size: 24),
      ),
      const SizedBox(width: 16),
      // 2. Title + Subtitle Column
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EGS DASHBOARD',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 18,
              color: theme.appBarForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'SYSTEM MODE: ${systemMode.toUpperCase()}',
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
  actions: const [
    GlobalAppBarActions(),
    SizedBox(width: 16),
  ],
)
```

---

## 5. Interactive `GlobalAppBarActions` & Diagnostics System

Path: `lib/core/widgets/global_app_bar_actions.dart`

A reusable Riverpod `ConsumerWidget` included on the right side of every AppBar. It integrates real-time hardware status monitoring, interactive serial diagnostics, and operator profile management.

```
┌───────────────────────────────────────────────────────────────┐
│ [RS232 Badge (Tap)]  │  [Avatar] Operator Name (Contractor)   │
└───────────────────────────────────────────────────────────────┘
```

### 5.1 Interactive RS232 Connection States

The USB badge listens to `comServiceProvider` and computes streaming liveness (`lastDataReceived` within 2 seconds):

| State | Badge Text | Semantic Color | Icon / Visual | Interaction |
|---|---|---|---|---|
| **Active Streaming** | `RS232 Active` | `Colors.greenAccent` | `Icons.usb` | Tap opens Diagnostics Dialog |
| **Connected Standby** | `RS232 Standby` | `Colors.amber` | `Icons.usb` | Tap opens Diagnostics Dialog |
| **Connecting / Retrying** | `Connecting (X/Y)...` | `Colors.amber` | `CircularProgressIndicator` (stroke 2) | Tap opens Diagnostics Dialog |
| **Connection Failed** | `RS232 Failed (Tap)`| `Colors.redAccent` | `Icons.error_outline` | Tap opens Diagnostics Dialog |
| **Disconnected / Inactive**| `RS232 Inactive (Tap)`| `Colors.red` | `Icons.usb_off` | Tap opens Diagnostics Dialog |

### 5.2 RS232 Diagnostics Modal (`_showUsbTroubleshootDialog`)
Tapping the RS232 badge opens the serial diagnostics modal featuring:
1. **Live State Badge**: Displays current state (`CONNECTED`, `CONNECTING`, `CONNECTION FAILED`, `DISCONNECTED`).
2. **Error Message Stream**: Outputs `usbState.lastErrorMessage` if any communication fault occurs.
3. **Detected USB Hardware List**: Queries Android USB Host manager and lists all detected USB devices with **Product Name**, **VID**, and **PID** in monospace typography.
4. **Field SOP Troubleshooting Guide**: 3-step actionable instructions for excavator operators.
5. **Interactive Retry Action**: `COBA HUBUNGKAN (RETRY)` button invoking `comServiceProvider.notifier.manualRetryConnect()`.

### 5.3 Operator Profile & Safe Logout
Tapping the operator profile pill triggers the sign-out confirmation dialog:
- Displays `CircleAvatar` with operator photo or default excavator avatar.
- Displays full operator name (`theme.appBarForeground`) and contractor name (`theme.appBarAccent`).
- **Safety Mechanism**: If a Timesheet work session is currently running, the logout handler **automatically stops** the timesheet (`timesheetProvider.notifier.stopActivity()`) before calling `authProvider.notifier.logout()`, preventing dangling or corrupt database sessions.

---

## 6. Standard Tabbed AppBar Pattern

For multi-view management pages (such as `CalibrationPage` and `SetupPage`), use `DefaultTabController` with actions placed inside the title row:

```dart
return DefaultTabController(
  length: 5,
  child: Scaffold(
    backgroundColor: theme.pageBackground,
    appBar: AppBar(
      backgroundColor: theme.appBarBackground,
      foregroundColor: theme.appBarForeground,
      elevation: 0,
      title: Row(
        children: [
          // Icon Box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.iconBoxBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.precision_manufacturing, color: theme.iconBoxIcon, size: 24),
          ),
          const SizedBox(width: 16),
          // Title + Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EQUIPMENT CALIBRATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 18,
                  color: theme.appBarForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'EGS CALIBRATION V${AppConstants.appVersion}',
                style: TextStyle(
                  color: theme.appBarAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Actions inside title row
          const GlobalAppBarActions(),
          const SizedBox(width: 16),
        ],
      ),
      bottom: TabBar(
        isScrollable: true,
        indicatorColor: theme.appBarAccent,
        labelColor: theme.appBarAccent,
        unselectedLabelColor: theme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'OFFSET CALIBRATION'),
          Tab(text: 'BODY CALIBRATION'),
          Tab(text: 'BOOM CALIBRATION'),
          Tab(text: 'STICK CALIBRATION'),
          Tab(text: 'ATTACHMENT CALIBRATION'),
        ],
      ),
    ),
    body: Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.cardBorderColor)),
      ),
      child: const TabBarView(
        children: [
          OffsetCalibrationTab(),
          BodyCalibrationTab(),
          BoomCalibrationTab(),
          StickCalibrationTab(),
          AttachmentCalibrationTab(),
        ],
      ),
    ),
  ),
);
```

---

## 7. Calibration Layout Specification (3:1 Grid Rule)

Mandatory structural standard for all hardware sensor and arm calibration tabs (`BoomCalibrationTab`, `StickCalibrationTab`, `AttachmentCalibrationTab`, `BodyCalibrationTab`):

```
┌─────────────────────────────────────────────────────────────┬───────────────────────────┐
│ LEFT COLUMN (Expanded flex: 3)                              │ RIGHT COLUMN (flex: 1)    │
│ ┌─────────────────────────────────────────────────────────┐ │ ┌───────────────────────┐ │
│ │                                                         │ │ │      PARAMETERS       │ │
│ │ TOP IMAGE REGION (Expanded flex: 3)                     │ │ ├───────────────────────┤ │
│ │ Reference 3D graphic / sensor schematic (BoxFit.contain)│ │ │ [BL] Boom Length      │ │
│ │                                                         │ │ │                  3400 │ │
│ └─────────────────────────────────────────────────────────┘ │ │                       │ │
│ [SizedBox(height: 16)]                                      │ │ [BBH] Boom Base H     │ │
│ ┌─────────────────────────────────────────────────────────┐ │ │                  1620 │ │
│ │ BOTTOM CONTROL REGION (Expanded flex: 1)                │ │ │                       │ │
│ │ [Tilt Value & Calibrate]  │  [Accelerometer & Reset]    │ │ │ (Scrollable ListView) │ │
│ └─────────────────────────────────────────────────────────┘ │ └───────────────────────┘ │
└─────────────────────────────────────────────────────────────┴───────────────────────────┘
```

### 7.1 Grid Specifications
1. **Outer Margin**: Single `Padding(padding: EdgeInsets.all(16.0))` wrapping the entire `Row`.
2. **Horizontal 3:1 Divide**:
   - **Left Column**: `Expanded(flex: 3)` housing the visual reference and live controls.
   - **Right Column**: `Expanded(flex: 1)` housing the parameter stack.
3. **Left Column Vertical Split**:
   - **Top Image Region** (`Expanded(flex: 3)`): Container decorated with `theme.cardSurface`, `BorderRadius.circular(16)`, and `Border.all(color: theme.cardBorderColor)`.
   - **Spacer**: `SizedBox(height: 16)`.
   - **Bottom Control Region** (`Expanded(flex: 1)`): Decorated identical to the top image container. Uses `Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly)` with vertical dividers (`theme.dividerColor`) separating control clusters.
4. **Right Column (Parameter Stack)**:
   - Header: Centered text `"PARAMETERS"` (`theme.textOnSurface`, `fontWeight: FontWeight.bold`, `letterSpacing: 1.2`, `fontSize: 16`).
   - Divider: `Divider(color: theme.dividerColor)`.
   - Body: `Expanded(child: ListView(children: [...]))` containing `ParameterCard` items.

### 7.2 Parameter Card Blueprint
```dart
Card(
  color: theme.cardSurface,
  margin: const EdgeInsets.symmetric(vertical: 6.0),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: theme.cardBorderColor),
  ),
  child: InkWell(
    onTap: () => _showSetParamDialog(context, title, type, value),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                abbreviation,
                style: TextStyle(
                  color: theme.textOnSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: theme.appBarAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),
)
```

### 7.3 Tilt & Angle Values Capping Constraint
- **Angle Capping**: ANY value representing an Angle or Tilt (Pitch, Roll, Boom/Stick/Bucket Tilt) **MUST** be visually capped at a maximum of `360.00`. If raw value > 360, display `360.00` (or modulo `% 360` if intended).
- **Degree Formatting**: ALWAYS append the degree symbol `°` to displayed angle values.
```dart
Text(
  '${(data.boomTilt > 360 ? 360.0 : data.boomTilt).toStringAsFixed(2)}°',
  style: TextStyle(
    color: theme.textOnSurface,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
)
```

### 7.4 Parameter Edit Modal (`_showSetParamDialog`)
```dart
AlertDialog(
  backgroundColor: theme.dialogBackground,
  title: Text('Set $title', style: TextStyle(color: theme.textOnSurface)),
  content: TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    style: TextStyle(color: theme.textOnSurface),
    decoration: InputDecoration(
      filled: true,
      fillColor: theme.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      hintText: 'Enter new value',
      hintStyle: TextStyle(color: theme.textSecondary),
    ),
  ),
  actions: [
    TextButton(
      child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
      onPressed: () => Navigator.of(context).pop(),
    ),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryButtonBackground,
        foregroundColor: theme.primaryButtonText,
      ),
      child: const Text('Set'),
      onPressed: () async {
        // Dispatch SetParam command (OpCode 0x53)
      },
    ),
  ],
)
```

---

## 8. Semantic Colors Reference (Theme-Independent)

These colors maintain identical values across both Dark and Light modes to convey unambiguous operational meaning:

| Context | Color Token | Value | Purpose |
|---|---|---|---|
| **USB Active** | `Colors.greenAccent` | `#69F0AE` | Active RS232 connection with live binary telemetry |
| **USB Standby** | `Colors.amber` | `#FFC107` | Port open but telemetry stream paused / waiting |
| **USB Retrying** | `Colors.amber` | `#FFC107` | Automatic reconnect loop in progress |
| **USB Failed** | `Colors.redAccent` | `#FF5252` | Serial handshake failed / port error |
| **USB Inactive** | `Colors.red` | `#F44336` | Serial port completely disconnected |
| **SPOT Mode** | `Colors.orange` | `#FFA500` | Operational spot guidance mode |
| **CRUMBLING Mode**| `Colors.blue` | `#2196F3` | Operational crumbling guidance mode |
| **MAINT Mode** | `Colors.red` | `#F44336` | Maintenance mode active |
| **Destructive** | `Color(0xFFEF4444)`| `#EF4444` | Reset calibration, delete record confirmation |
| **Success/Valid** | `Color(0xFF2ECC71)`| `#2ECC71` | Sensor calibration pass, command ACK |
| **Status Block (Yellow)** | `Colors.amberAccent`| `#FFE57F` | Excavated spot marked as Block (Status 2) |
| **Status Done (Green)** | `Colors.green` | `#4CAF50` | Excavated spot marked as Done (Status 1) |
| **GeoJSON Export**| `Color(0xFF3B82F6)`| `#3B82F6` | Crumbling GeoJSON download action |

---

## 9. Typography Rules & SCADA Aesthetics

### 9.1 Hierarchy
- **AppBar Page Title**: UPPERCASE, `fontSize: 18`, `fontWeight: FontWeight.bold`, `letterSpacing: 1.2`, color `theme.appBarForeground`.
- **AppBar Subtitle / System Mode**: UPPERCASE, `fontSize: 10`, `fontWeight: FontWeight.w600`, `letterSpacing: 0.5`, color `theme.appBarAccent`.
- **SideMenu Section Headers**: UPPERCASE, `fontSize: 10`, `fontWeight: FontWeight.bold`, `letterSpacing: 1.1`, color `theme.sectionHeaderColor`.
- **Parameter Abbreviation**: `fontSize: 16`, `fontWeight: FontWeight.bold`, color `theme.textOnSurface`.
- **Parameter Display Value**: `fontSize: 18`, `fontWeight: FontWeight.bold`, color `theme.appBarAccent`.
- **Live Cab Clock**: `fontSize: 22`, `fontWeight: FontWeight.bold`, `letterSpacing: 2.0`, color `theme.dateTimeClockColor`.

### 9.2 Modern Deprecation Standards
- **Color Opacity**: NEVER use `.withOpacity(alpha)`. ALWAYS use modern Flutter `.withValues(alpha: ...)`.
- **Switch Widgets**: NEVER use deprecated `activeColor`. ALWAYS use `activeThumbColor` and `activeTrackColor`.
- **Zero Hardcoded Colors**: UI widgets must never declare inline hex colors (e.g. `Color(0xFF1A2235)`) for layout surfaces. All surfaces must be bound to `theme.*` tokens.
