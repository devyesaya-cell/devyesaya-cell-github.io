# UI Component System & Web Compatibility Specification

> **Target Platforms**: Android Industrial Tablet (10" 1280×800 / 1920×1200) & Web Browser (Desktop SCADA Monitoring)  
> **Design Philosophy**: High-stress industrial readability (glare/night shifts) + responsive desktop web ergonomics.

---

## 1. Design Philosophy & Web Compatibility Principles

```
┌────────────────────────────────────────────────────────────────────────┐
│                   HYBRID INDUSTRIAL & WEB ARCHITECTURE                 │
├──────────────────────────────────┬─────────────────────────────────────┤
│     TABLET CAB TOUCHSCREEN       │          WEB BROWSER                │
│ - Min 48×48px Touch Targets      │ - Mouse Pointer (SystemMouseCursors)│
│ - Ultra-High Contrast SCADA      │ - Hover & Focus Highlight States    │
│ - Direct Sunlight Outdoor Tokens │ - Responsive Desktop Viewports      │
│ - Single-Handed Cab Ergonomics   │ - Mouse Wheel Scrolling Physics     │
└──────────────────────────────────┴─────────────────────────────────────┘
```

### 1.1 Golden Rules for Web Compatibility
1. **Constraint-Based Layouts**: Never hardcode fixed screen dimensions (`width: 1280`). Always use `Expanded`, `Flexible`, `LayoutBuilder`, or `MediaQuery` to gracefully handle browser window resizing.
2. **Platform Guardrails (`kIsWeb`)**: Never import `dart:io` (`Platform.isAndroid`) directly into UI widgets. When dealing with hardware-specific services, abstract behind interfaces with web fallback mock streams.
3. **Mouse & Pointer Feedback**: All clickable cards and buttons must use `InkWell` or `MouseRegion` with `cursor: SystemMouseCursors.click` to guarantee expected desktop pointer behavior.
4. **Text Ellipsis & Overflow Safety**: Every data label and header must define `maxLines` and `overflow: TextOverflow.ellipsis` inside `Flexible`/`Expanded` to prevent web layout rendering overflows (`RenderFlex overflowed`).
5. **Scroll Physics & Viewport Containment**: Modal dialogs and lists must wrap content in `SingleChildScrollView` or `ListView` with `Scrollbar` support so desktop mouse wheels scroll naturally.

---

## 2. Navigation & Header Components

### 2.1 Standard AppBar Header
- **Purpose**: Unified per-page brand identity, title, system mode, and action bar.

#### Structured Props Table:
| Prop Name | Type | Required / Default | Token Consumed | Description |
|---|---|---|---|---|
| `title` | `String` | Required | `theme.appBarForeground` | Main screen title, rendered in uppercase, 18px bold |
| `subtitle` | `String` | Optional (`''`) | `theme.appBarAccent` | Operational mode or subtitle, 10px teal bold |
| `icon` | `IconData` | Required | `theme.iconBoxIcon` | Icon rendered in the 40×40 icon container |
| `actions` | `List<Widget>` | Optional (`[GlobalAppBarActions()]`) | N/A | Actions displayed on the right edge |

```dart
AppBar(
  backgroundColor: theme.appBarBackground,
  foregroundColor: theme.appBarForeground,
  elevation: 0,
  title: Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.iconBoxBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.iconBoxIcon, size: 24),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 18,
                color: theme.appBarForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle.toUpperCase(),
              style: TextStyle(
                color: theme.appBarAccent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  ),
  actions: actions ?? const [GlobalAppBarActions(), SizedBox(width: 16)],
)
```

---

### 2.2 `GlobalAppBarActions`
- **Purpose**: Real-time RS232 hardware link indicator, interactive diagnostics trigger, and operator profile pill with safe logout.

#### Structured Props Table:
| Element | Dimensions / Styling | Semantic Colors / States | Notes |
|---|---|---|---|
| `StatusBadge` | `Padding: h:6, v:4`, `Radius: 8px` | Active: `Colors.greenAccent`<br>Standby: `Colors.amber`<br>Connecting: `Colors.amber`<br>Failed: `Colors.redAccent` | Multi-modal icon + status label |
| `Divider` | `width: 1`, `height: 24` | `color: theme.menuBorder` | Vertical partition between badge & user |
| `ProfileAvatar`| `radius: 16` (32×32 px circle) | Fallback asset icon | Displays operator initials or avatar |
| `OperatorText` | `fontSize: 12`, `FontWeight.bold` | `color: theme.appBarForeground` | Active operator display name |
| `ContractorText`| `fontSize: 10`, `FontWeight.normal`| `color: theme.appBarAccent` | Contractor or fleet company name |

---

### 2.3 `SideMenu` (Responsive Navigation Drawer)
- **Purpose**: Multi-section application navigation, brand logo banner, live mode monitor, and digital cab clock.

#### Structured Props Table:
| Component | Dimensions & Styling | Tokens Consumed | Notes |
|---|---|---|---|
| `Drawer Width` | `MediaQuery.of(context).size.width * 0.25` | Min: `220px`, Max: `320px` | Clamped width for responsive tablets/desktops |
| `Border` | `Border(right: BorderSide(width: 1.5))` | `theme.menuBorder` | Right boundary separator |
| `Menu Item Pill`| `Padding: h:24, v:12`, `Margin: right 16` | Active: `theme.menuSelectedBackground` | Rounded pill `Radius.horizontal(right: 30)` |
| `Menu Icon` | `size: 20` | Active: `theme.menuSelectedIcon`, Inactive: `theme.menuUnselectedIcon` | Scaled icon |
| `Menu Label` | `fontSize: 14`, `FontWeight.bold` | Active: `theme.menuSelectedText`, Inactive: `theme.menuUnselectedText` | Text label |

---

## 3. Data & Metric Visualization Cards

### 3.1 `SummaryCard` (Circular Percent Metric Card)
- **Purpose**: Displays KPI production stats (e.g. Daily Progress, Accuracy, Volume, Digging Speed) with a round progress ring.

#### Structured Props Table:
| Prop Name | Type | Required / Default | Token Consumed | Description |
|---|---|---|---|---|
| `title` | `String` | Required | `theme.textSecondary` | Metric title (e.g. "PRODUKTIVITAS") |
| `value` | `String` | Required | `theme.textOnSurface` | Primary numerical value (e.g. "128.5") |
| `subUnit` | `String` | Optional (`''`) | `theme.appBarAccent` | Unit symbol (e.g. "m³", "spots/hr") |
| `percent` | `double` | Required | N/A | Fractional progress value ($0.0 \dots 1.0$) |
| `progressColor`| `Color` | Required | Semantic | Hex color for ring (Green, Blue, Orange) |

```dart
Widget buildSummaryCard(BuildContext context, {
  required String title,
  required String value,
  String subUnit = '',
  required double percent,
  required Color progressColor,
}) {
  final theme = AppTheme.of(context);
  return LayoutBuilder(
    builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 220;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.pageBackground,
          border: Border.all(color: theme.cardBorderColor, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: theme.textSecondary, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(value, style: TextStyle(fontSize: isCompact ? 18 : 24, fontWeight: FontWeight.bold, color: theme.textOnSurface)),
                      const SizedBox(width: 4),
                      Text(subUnit, style: TextStyle(fontSize: 12, color: theme.appBarAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            if (!isCompact)
              CircularPercentIndicator(
                radius: 35.0,
                lineWidth: 8.0,
                percent: percent.clamp(0.0, 1.0),
                center: Text(
                  "${(percent * 100).toStringAsFixed(1)}%",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.textOnSurface),
                ),
                progressColor: progressColor,
                backgroundColor: theme.cardSurface,
                circularStrokeCap: CircularStrokeCap.round,
              ),
          ],
        ),
      );
    },
  );
}
```

---

### 3.2 `WorkfileCard` (Project Job File Card)
- **Purpose**: Selectable job file container displaying area, grid spacing, progress bar, and status pill.

#### Structured Props Table:
| Prop Name | Type | Required / Default | Token Consumed | Description |
|---|---|---|---|---|
| `workfileName`| `String` | Required | `theme.textOnSurface` | Display title of workfile |
| `areaName` | `String` | Required | `theme.textSecondary` | Geographic site area name |
| `gridDimensions`| `String` | Required | `theme.appBarAccent` | Spacing dimensions (e.g. `4.0x1.87 m`) |
| `progress` | `double` | Required | Semantic / Status | Completion ratio ($0.0 \dots 1.0$) |
| `onTap` | `VoidCallback`| Required | N/A | Tap selection handler |

---

## 4. Calibration Layout & Hardware Controls (3:1 Grid)

Mandatory structural standard for sensor and arm calibration:

```
┌─────────────────────────────────────────────────────────────┬───────────────────────────┐
│ LEFT COLUMN (Expanded flex: 3)                              │ RIGHT COLUMN (flex: 1)    │
│ ┌─────────────────────────────────────────────────────────┐ │ ┌───────────────────────┐ │
│ │ TOP IMAGE REGION (Expanded flex: 3)                     │ │ │      PARAMETERS       │ │
│ │ Reference 3D graphic / sensor schematic (BoxFit.contain)│ │ │ [BL] Boom Length 3400 │ │
│ └─────────────────────────────────────────────────────────┘ │ │ [BBH] Boom Base H 1620│ │
│ ┌─────────────────────────────────────────────────────────┐ │ │                       │ │
│ │ BOTTOM CONTROL REGION (Expanded flex: 1)                │ │ │ (Scrollable ListView) │ │
│ │ [Tilt Value & Calibrate]  │  [Accelerometer & Reset]    │ │ └───────────────────────┘ │
│ └─────────────────────────────────────────────────────────┘ │                           │
└─────────────────────────────────────────────────────────────┴───────────────────────────┘
```

### 4.1 `ParameterCard` Specification

#### Structured Props Table:
| Prop Name | Type | Required / Default | Token Consumed | Description |
|---|---|---|---|---|
| `abbreviation` | `String` | Required | `theme.textOnSurface` | 2-3 char code (e.g. `BL`, `BBH`, `SL`) |
| `title` | `String` | Required | `theme.textSecondary` | Full parameter label (e.g. "Boom Length") |
| `value` | `num` | Required | `theme.appBarAccent` | Current numerical parameter value |
| `onTap` | `VoidCallback`| Required | N/A | Opens parameter editing modal |

---

## 5. Form & Interactive Input Controls

### 5.1 `SCADATextField`
#### Structured Props Table:
| Prop Name | Type | Required / Default | Token Consumed | Description |
|---|---|---|---|---|
| `controller` | `TextEditingController` | Required | N/A | Manages text input state |
| `hintText` | `String` | Optional (`''`) | `theme.inputHintText` | Placeholder text |
| `isPassword` | `bool` | Optional (`false`) | N/A | Obscures text entry |
| `onChanged` | `ValueChanged<String>?` | Optional (`null`) | N/A | Debounced value change callback |

---

### 5.2 `SCADASwitchTile`
#### Structured Props Table:
| Prop Name | Type | Required / Default | Token Consumed | Description |
|---|---|---|---|---|
| `title` | `String` | Required | `theme.textOnSurface` | Primary switch label |
| `subtitle` | `String` | Optional (`''`) | `theme.textSecondary` | Explanatory description |
| `value` | `bool` | Required | N/A | Current toggle state |
| `onChanged` | `ValueChanged<bool>` | Required | N/A | Dispatched boolean mutation |

---

### 5.3 `SCADASlider`
#### Structured Props Table:
| Prop Name | Type | Required / Default | Token Consumed | Description |
|---|---|---|---|---|
| `value` | `double` | Required | `theme.appBarAccent` | Slider current value |
| `min` | `double` | Optional (`0.0`) | N/A | Lower numeric bound |
| `max` | `double` | Optional (`100.0`)| N/A | Upper numeric bound |
| `divisions` | `int?` | Optional (`null`) | N/A | Discrete steps count |
| `onChanged` | `ValueChanged<double>`| Required | N/A | Continuous slide callback |

---

## 6. Modal Dialogs & HUD Floating Alerts

### 6.1 `DialogUtils.showConfirmationDialog`
#### Structured Props Table:
| Prop Name | Type | Required / Default | Description |
|---|---|---|---|
| `title` | `String` | Required | Header title of the modal |
| `message` | `String` | Required | Body explanation text |
| `confirmLabel`| `String` | Optional (`'Confirm'`)| Primary action button label (Destructive red) |
| `cancelLabel` | `String` | Optional (`'Cancel'`) | Secondary action button label |

---

## 7. Flutter Web Compatibility Checklist & Developer SOP

| Verification Item | Requirement | Code Standard |
|---|---|---|
| **1. Mouse Cursor** | Clickable areas show pointer cursor | `InkWell` or `MouseRegion(cursor: SystemMouseCursors.click)` |
| **2. Text Overflow** | No RenderFlex overflow on small browser viewports | `Text(..., maxLines: 1, overflow: TextOverflow.ellipsis)` |
| **3. Scrollability** | Dialogs and panels scroll cleanly with mouse wheel | Wrap in `SingleChildScrollView` + `Scrollbar` |
| **4. Color Tokens** | Zero hardcoded layout colors | Use `theme.pageBackground`, `theme.cardSurface`, etc. |
| **5. Deprecation** | Modern Flutter opacity API | Use `.withValues(alpha: ...)` instead of `.withOpacity(...)` |
| **6. Touch Target** | Adequate button hitboxes | Minimum height/width: $\ge 48\times48\text{ px}$ |
| **7. Web Imports** | No `dart:io` crashes on browser build | Guard with `kIsWeb` or use conditional imports |
| **8. Responsive Width** | Grids adapt to browser window size | `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 380)` |
