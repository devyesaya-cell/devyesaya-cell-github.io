# Side Menu Widget
Path: `lib/features/home/widgets/side_menu.dart`

The `SideMenu` is the persistent global navigation sidebar occupying the left side of the `HomePage`. It is always visible and controls which feature page is displayed in the content area.

## Dependencies
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/auth_state.dart';   // authProvider, SystemMode enum
import '../../../core/utils/app_theme.dart';    // AppTheme.of(context), AppThemeData
```

---

## State Management

### `MenuNotifier` (Riverpod Notifier)
```dart
class MenuNotifier extends Notifier<int> {
  @override
  int build() {
    return 1; // Default to Dashboard (index 1)
  }

  void setIndex(int index) {
    state = index;
  }
}

final selectedMenuProvider = NotifierProvider<MenuNotifier, int>(
  MenuNotifier.new,
);
```
- **Default index**: `1` (Dashboard is the landing page after login).
- **Used by**: `SideMenu` to highlight the active item, `HomePage` to switch content.

---

## Widget Type
`ConsumerWidget` — watches `selectedMenuProvider` for reactive menu highlighting.

---

## Root Container
```dart
Container(
  width: MediaQuery.of(context).size.width * 0.25,  // 25% of screen width
  decoration: BoxDecoration(
    color: theme.menuBackground,
    border: Border(right: BorderSide(color: theme.menuBorder, width: 1.5)),
  ),
  child: Column(...)
)
```

---

## UI Hierarchy — `Column` children

### 1. Logo Area
```dart
Padding(
  padding: const EdgeInsets.all(24.0),
  child: Image.asset(
    'images/banner.png',
    height: MediaQuery.of(context).size.height * 0.1,  // 10% of viewport height
    fit: BoxFit.contain,
  ),
)
```

### 2. Navigation List (`Expanded` → `ListView`)
```dart
Expanded(
  child: ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [
      // "Menu" section
      _buildSectionHeader('Menu', theme),
      _buildMenuItem(..., index: 0, icon: Icons.folder_open,         label: 'Work Files'),
      _buildMenuItem(..., index: 1, icon: Icons.dashboard_outlined,  label: 'Dashboard'),
      _buildMenuItem(..., index: 2, icon: Icons.timeline,            label: 'Timesheet'),
      _buildMenuItem(..., index: 3, icon: Icons.notifications_none,  label: 'Voice Logs'),

      const SizedBox(height: 24),

      // "System" section
      _buildSectionHeader('System', theme),
      _buildMenuItem(..., index: 4, icon: Icons.settings_outlined,   label: 'Setup'),

      const SizedBox(height: 24),

      // System Status card
      _buildSystemStatus(ref, theme),
    ],
  ),
)
```

### 3. Real-time Clock
```dart
_DateTimeWidget(theme: theme),
const SizedBox(height: 16),
```

---

## Helper Widgets

### `_buildSectionHeader(String title, AppThemeData theme)`
```dart
Padding(
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
)
```

### `_buildMenuItem(context, ref, theme, {index, icon, label, isSelected})`
```dart
InkWell(
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
        Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.menuSelectedText : theme.menuUnselectedText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
)
```
**Key details**:
- Active pill shape: Only right corners rounded (`Radius.circular(30)`), flush left edge.
- `margin: EdgeInsets.only(right: 16)` — inset from the right border only.
- Icon: `size: 20`.
- Text weight: `bold` when selected, `w500` when unselected.

### `_buildSystemStatus(WidgetRef ref, AppThemeData theme)`
Reads `authProvider` to display the current `SystemMode`.

```dart
// Mode mapping (semantic colors — fixed regardless of theme)
switch (mode) {
  case SystemMode.spot:
    modeLabel = 'SPOT';
    modeIcon  = Icons.settings_suggest;
    modeColor = Colors.orange;
  case SystemMode.crumbling:
    modeLabel = 'CRUMBLING';
    modeIcon  = Icons.school;
    modeColor = Colors.blue;
  case SystemMode.maintenance:
    modeLabel = 'MAINTENANCE';
    modeIcon  = Icons.build;
    modeColor = Colors.red;
}
```

**Layout:**
```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  child: Column(
    children: [
      Container(
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
            Column(
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
          ],
        ),
      ),
    ],
  ),
)
```

---

## `_DateTimeWidget` (Private StatefulWidget)

### Type
`StatefulWidget` (not a ConsumerWidget — no Riverpod dependency, purely renders time).

### Constructor
```dart
final AppThemeData theme;
const _DateTimeWidget({required this.theme});
```

### Lifecycle
```dart
@override
void initState() {
  super.initState();
  _now = DateTime.now();
  _timer = Timer.periodic(const Duration(seconds: 1), (_) {
    setState(() {
      _now = DateTime.now();
    });
  });
}

@override
void dispose() {
  _timer.cancel();
  super.dispose();
}
```

### Date/Time Formatting
```dart
// Time: "HH:MM:SS"
final timeString =
    "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}";

// Month and weekday names
const monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
const dayNames = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
final monthString = monthNames[_now.month - 1];
final dayString = dayNames[_now.weekday - 1];

// Date: "Wed, 31 Mar 2026"
final dateString = "$dayString, ${_now.day} $monthString ${_now.year}";
```

### Widget Layout
```dart
Container(
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
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Left: time + date stacked
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeString,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: theme.dateTimeClockColor,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateString,
            style: TextStyle(
              color: theme.dateTimeDateColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      // Right: clock icon in circle
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.dateTimeIconBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.access_time_filled,
          color: theme.dateTimeClockColor,
          size: 24,
        ),
      ),
    ],
  ),
)
```

---

## Menu Index ↔ Page Mapping (in `HomePage`)
| Index | Menu Label  | Widget             | Icon                       |
|-------|-------------|--------------------|----------------------------|
| `0`   | Work Files  | `WorkfilePage()`   | `Icons.folder_open`        |
| `1`   | Dashboard   | `DashboardPage()`  | `Icons.dashboard_outlined` |
| `2`   | Timesheet   | `TimesheetPage()`  | `Icons.timeline`           |
| `3`   | Voice Logs  | `AlarmPage()`      | `Icons.notifications_none` |
| `4`   | Setup       | `SetupPage()`      | `Icons.settings_outlined`  |

## Required Assets
- `images/banner.png` — Application banner logo displayed at the top of the menu.
