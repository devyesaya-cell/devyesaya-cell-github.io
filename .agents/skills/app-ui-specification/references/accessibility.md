# Industrial Accessibility & Assistive UX Specification (accessibility.md)

> **Toho EGS — Version 4.2.20 (Build 90)**  
> **Scope**: Gloved Touch Ergonomics, Multi-Modal Redundancy, High-Contrast SCADA, Web Accessibility  
> **Target Environments**:  
> 1. **Excavator Cab Industrial Tablet**: Extreme sunlight/glare, night vision preservation, high machine vibration, heavy work gloves, eyes-on-the-trench operational safety.  
> 2. **Flutter Web SCADA Dashboard**: Mouse pointer navigation, keyboard focus traversal, browser screen reader accessibility (TalkBack / NVDA / VoiceOver).  
> **Standards**: WCAG 2.1 Level AA/AAA (SCADA tailored), ISO 9241-110 Ergonomics of human-system interaction.

---

## 1. Core Principles of Industrial Accessibility

Industrial accessibility differs fundamentally from consumer mobile apps. A machine operator operating a 20-ton excavator in dust, rain, or direct sunlight needs immediate, unambiguous, multi-modal feedback.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   INDUSTRIAL ACCESSIBILITY PILLARS                     │
├──────────────────────────────────┬─────────────────────────────────────┤
│ 1. MULTI-MODAL REDUNDANCY        │ 2. CAB ERGONOMICS & HIT TARGETS     │
│ - Never convey info by color     │ - Min 48×48px hitbox (gloved hand)  │
│   alone (Pair Color + Icon +     │ - High touch tolerance (vibration)  │
│   Label + Audible Beep/TTS)      │ - Critical actions min 56×56px      │
├──────────────────────────────────┼─────────────────────────────────────┤
│ 3. DAYLIGHT & NIGHT CAB CONTRAST │ 4. ASSISTIVE DIGITAL READABILITY    │
│ - Min 4.5:1 for standard text    │ - Explicit Semantic Tree definitions│
│ - Min 7:1 for critical telemetry │ - Keyboard/keypad focus traversal   │
│ - Zero-glare dark SCADA at night │ - Screen reader unit expansion      │
└──────────────────────────────────┴─────────────────────────────────────┘
```

---

## 2. Rules Per Widget Type

### 2.1 Headers & Status Indicators (`GlobalAppBar`, `GlobalAppBarActions`)
*Widgets: `GlobalAppBarActions`, AppBar Icons*

| Component | Accessibility Rule | Implementation Pattern |
|---|---|---|
| **RS232 Connection Badge** | **Color + Icon + Text Redundancy**: Never show a standalone colored circle. Always pair semantic color with specific icon (`Icons.usb`, `Icons.sync`, `Icons.error_outline`) and text label (`RS232 Active`, `Connecting`, `RS232 Failed`). | `Semantics(label: 'Serial Hardware Status: $statusText', hint: 'Tap to open serial troubleshooting diagnostics', button: true)` |
| **Interactive Tap Target** | **Touch Padding**: Badge must provide at least $44\times40\text{ px}$ clickable area even if visual badge is compact. | `Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6))` wrapped in `InkWell` |
| **Operator Profile Pill** | **Multi-line Announcement**: Screen reader must announce both operator name and contractor organization. | `Semantics(label: 'Logged in operator: $name, Contractor: $contractor', hint: 'Tap to sign out', button: true)` |
| **Page Icon Box** | **Decorative Exclusion**: The 40×40 icon container is decorative if adjacent to the page title. | `ExcludeSemantics(child: Icon(...))` to avoid duplicate reading of title |

#### Code Example:
```dart
Semantics(
  button: true,
  label: 'RS232 Serial Status: $statusText',
  hint: 'Double tap to open diagnostics and hardware troubleshooting',
  child: InkWell(
    onTap: () => _showUsbTroubleshootDialog(context, ref, theme),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          statusIcon,
          const SizedBox(width: 6),
          Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  ),
)
```

---

### 2.2 Navigation Components (`SideMenu`, `TabBar`)
*Widgets: `SideMenu`, `TabBar`, `_DateTimeWidget`*

| Component | Accessibility Rule | Implementation Pattern |
|---|---|---|
| **Menu Items** | **Selected State Semantics**: Screen readers must announce whether the item is currently active (`selected: true`). | `Semantics(selected: isSelected, label: '$label Menu', button: true)` |
| **Touch Ergonomics** | **Full-Row Hitbox**: Menu item touch area must span the entire left-to-right drawer width ($>48\text{ px}$ height). | `Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12))` |
| **TabBar Tabs** | **Scrollable & Tab Role**: Announce tab index and total tabs (e.g. "Tab 2 of 5, Body Calibration"). | Standard Flutter `TabBar` handles this; keep `isScrollable: true` to prevent label truncation. |
| **Cab Digital Clock** | **Live Region Suppression**: Do NOT announce the clock every second to screen readers. Announce only upon user focus. | `Semantics(label: 'Current cab time: $timeString, Date: $dateString', liveRegion: false)` |

---

### 2.3 Telemetry & Data Cards (`SummaryCard`, `ProgressCard`, `WorkfileCard`)
*Widgets: `SummaryCard`, `WorkfileCard`*

| Component | Accessibility Rule | Implementation Pattern |
|---|---|---|
| **Abbreviated Units** | **Pronunciation Expansion**: Units like `m³`, `cm`, `HM`, `kts` must be expanded in semantics so screen readers pronounce "cubic meters" instead of "m-three". | `Semantics(label: '$title: $value cubic meters')` |
| **Circular Ring** | **Progress Semantics**: `CircularPercentIndicator` is a graphic; expose percent value as an accessible string. | `Semantics(value: '${(percent * 100).toInt()}% completed', child: CircularPercentIndicator(...))` |
| **Workfile Cards** | **Compound Data Reading**: Announce Area Name, Status, Dimension, and Completion rate in a single coherent sentence. | `Semantics(label: 'Workfile Area $areaName, Status $status, Dimensions $panjang by $lebar meters, Progress $done of $total spots completed')` |
| **Trend Direction** | **Non-Color Trend Icon**: Do not use green/red text alone. Pair with `Icons.trending_up` or `Icons.trending_down`. | Include directional arrow icon + semantic text: "Trend upward" |

---

### 2.4 Industrial Calibration & Kinematics (3:1 Grid Pattern)
*Widgets: `BoomCalibrationTab`, `ParameterCard`*

| Component | Accessibility Rule | Implementation Pattern |
|---|---|---|
| **Parameter Abbreviations** | **Full Name Expansion**: Abbreviations (`BL`, `BBH`, `ST`, `AT`) must have their full names announced to prevent operator ambiguity. | `Semantics(label: '$fullTitle, abbreviation $abbreviation, current value $value millimeters')` |
| **Tilt & Angle Values** | **Visual Capping ($360.00^\circ$) & Degree Unit**: Raw values exceeding 360 must display `360.00°`. Screen readers must pronounce "degrees". | `Text('${(val > 360 ? 360.0 : val).toStringAsFixed(2)}°')`<br>`Semantics(label: 'Boom tilt: ${val.toStringAsFixed(2)} degrees')` |
| **3D Schematic Image** | **Decorative Graphic**: The reference image (`calibrate_2.png`) must not distract assistive tech with raw filenames. | `ExcludeSemantics(child: Image.asset(...))` |
| **Calibration Reset Buttons** | **High Consequence Guard**: Reset buttons must have explicit warnings, minimum 48px hitboxes, and require confirmation dialog. | `IconButton(tooltip: 'Reset Boom Sensor Calibration', icon: Icon(Icons.refresh))` |

#### Accessible `ParameterCard` Blueprint:
```dart
Semantics(
  button: true,
  label: '$title, abbreviation $abbreviation, current value $value millimeters',
  hint: 'Double tap to enter a new numerical value',
  child: Card(
    color: theme.cardSurface,
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
                Text(abbreviation, style: TextStyle(color: theme.textOnSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(title, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
              ],
            ),
            Text(value.toString(), style: TextStyle(color: theme.appBarAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  ),
)
```

---

### 2.5 Form & Interactive Input Controls
*Widgets: `TextField`, `DropdownButton`, `SwitchListTile`, `Slider`*

| Component | Accessibility Rule | Implementation Pattern |
|---|---|---|
| **Text Fields** | **Visible Labels & Contrasting Fill**: Avoid placeholder-only fields. Always provide permanent label text. Input background fill must contrast with page background ($>3:1$). | `InputDecoration(labelText: '...', hintText: '...', filled: true, fillColor: theme.inputFill)` |
| **Switch Toggles** | **Deprecation & Toggled State**: Use modern `activeThumbColor`. Screen reader must announce current Boolean state. | `SwitchListTile(value: isEnabled, title: Text(...), activeThumbColor: theme.appBarAccent)` |
| **Sliders** | **Discrete Steps & Audio/Haptic Tick**: Sliders must have `divisions` and readable values (e.g. `15 m`). | `Slider(divisions: 7, label: '${val.toInt()} m', ...)` |
| **Dropdown Menus** | **Accessible Label & Monospace Items**: Options must have high contrast and clear current selection. | `DropdownButton<double>(underline: Container(), dropdownColor: theme.cardSurface, ...)` |

---

### 2.6 Modal Dialogs & Feedback Overlays
*Widgets: `DialogUtils`, `NotificationService`*

| Component | Accessibility Rule | Implementation Pattern |
|---|---|---|
| **Confirmation Dialog** | **Focus Trapping & Escape Dismiss**: Focus must land automatically on the dialog. `Esc` key on Web must dismiss safely. | Use `showDialog` with `barrierDismissible: true` and explicit Cancel/Confirm buttons. |
| **Destructive Action** | **Semantic Color Distinction**: Destructive buttons (Confirm Reset, Delete) must use `#EF4444` (Red) paired with bold white text. Cancel must be neutral. | `ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFEF4444)))` |
| **HUD Floating Toasts** | **Immediate Audible Feedback**: `NotificationService.showCommandNotification` must announce to screen readers via `SemanticsService.announce`. | `SemanticsService.announce('$title: $message', TextDirection.ltr)` |

---

## 3. High-Contrast SCADA Matrix (WCAG 2.1 AA/AAA)

To ensure daylight visibility through dirty excavator cab windows and direct sunlight reflections, tokens must meet these contrast thresholds:

| Element Pair | Dark SCADA Hex | Light SCADA Hex | Contrast Ratio | WCAG Compliance |
|---|---|---|---|---|
| **Primary Text on Page** | `#FFFFFF` on `#0D1118` | `#1A1A2E` on `#E8ECF0` | $>14:1$ | **AAA Pass** (Ultra Contrast) |
| **Secondary Text on Surface** | `#8A94A6` on `#1A2235` | `#7A8290` on `#FFFFFF` | $>4.6:1$ | **AA Pass** (Daylight Safe) |
| **Cyan Accent on Surface** | `#00BCD4` on `#1A2235` | `#00BCD4` on `#FFFFFF` | $>5.1:1$ | **AA Pass** (Clean Visibility) |
| **Green Success on Surface**| `#2ECC71` on `#1A2235` | `#2ECC71` on `#FFFFFF` | $>4.8:1$ | **AA Pass** (Status Clear) |
| **Destructive Red on Surface**| `#EF4444` on `#1A2235` | `#EF4444` on `#FFFFFF` | $>4.9:1$ | **AA Pass** (Warning Alert) |

---

## 4. Colorblindness Resilience (Deuteranopia, Protanopia, Tritanopia)

In heavy earthmoving operations, an operator who is red-green colorblind must never confuse a **"Within Tolerance (Dig Pass)"** spot with an **"Out of Tolerance (Over-dig/Hazard)"** spot.

```
┌────────────────────────────────────────────────────────────────────────┐
│                      COLORBLIND SAFETY STANDARD                        │
├───────────────┬────────────────────────────┬───────────────────────────┤
│ STATE         │ FORBIDDEN PATTERN          │ MANDATORY TOHO STANDARD   │
├───────────────┼────────────────────────────┼───────────────────────────┤
│ Done / Safe   │ Plain green dot            │ Green + Check Icon +      │
│               │                            │ Text 'DONE (Status 1)'    │
├───────────────┼────────────────────────────┼───────────────────────────┤
│ Block / Halt  │ Plain yellow dot           │ Yellow + Square Icon +    │
│               │                            │ Text 'BLOCK (Status 2)'   │
├───────────────┼────────────────────────────┼───────────────────────────┤
│ Alarm / Error │ Plain red dot              │ Red + Triangle Warning +  │
│               │                            │ Audio Beep / Voice Alert  │
└───────────────┴────────────────────────────┴───────────────────────────┘
```

---

## 5. Web & Tablet Keyboard Traversal Standards

When Toho EGS runs on **Flutter Web** or industrial tablets equipped with physical hardware keypads:

1. **Tab Navigation Order**: Focus traversal must follow logical reading order:
   - Header $\rightarrow$ Side Menu $\rightarrow$ Main View Content $\rightarrow$ Controls $\rightarrow$ Actions.
2. **Focus Indicators**: Every interactive widget must render a distinct focus outline:
   ```dart
   focusNode: FocusNode(),
   // Active focus uses theme.inputFocusedBorder (Cyan #00BCD4, width: 2)
   ```
3. **Hardware Key Shortcuts**:
   - `Enter` / `Space`: Activate selected button, toggle checkbox.
   - `Escape`: Close active modal dialog or troubleshoot popup.
   - `Arrow Keys (Up/Down)`: Adjust `Slider` values or navigate `ListView`.

---

## 6. Developer Accessibility Checklist (Pre-Commit SOP)

Before declaring any UI task complete, developers must verify:

- [ ] **Touch Target Size**: Are all touchable elements $\ge 44\times44\text{ px}$ (or $\ge 48\times48\text{ px}$ for field operations)?
- [ ] **Multi-Modal Redundancy**: Does any status indicator rely *only* on color? (If yes, add an icon or text label).
- [ ] **Semantic Pronunciation**: Are abbreviated units (`m³`, `cm`, `BL`, `BBH`) expanded in `Semantics(label: ...)`?
- [ ] **Angle Capping Rule**: Are angles capped at $360.00^\circ$ and appended with `°`?
- [ ] **Decorative Graphic Exclusion**: Are background images wrapped in `ExcludeSemantics`?
- [ ] **Screen Reader Announcement**: Do critical sensor commands trigger `SemanticsService.announce`?
- [ ] **Keyboard / Mouse Focus**: Can dialogs and forms be navigated with the `Tab` and `Enter` keys on Flutter Web?
- [ ] **Text Overflow**: Does every flexible label have `maxLines` and `overflow: TextOverflow.ellipsis`?
