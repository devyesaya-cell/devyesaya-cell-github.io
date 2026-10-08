# Screen Specification Template (11-Section Standard)

> **Template Relationship**: Direct blueprint instance of `references/screen-template.md` (Single Source of Truth). Edit `references/screen-template.md` for standard/spec rule changes; copy this file when instantiating a new screen spec in `screens/[name].md`.  
> **File Target**: `lib/features/[feature_name]/pages/[screen_name]_page.dart`  
> **Widget Type**: `ConsumerWidget` (or `ConsumerStatefulWidget` if local animations/controllers needed)  
> **Presenter/State**: `[featureName]PresenterProvider`  
> **Primary Mode**: SPOT / CRUMBLING / SHARED  

---

## 1. Purpose

Briefly summarize the screen's operational purpose, user persona (e.g. Heavy Equipment Operator, Surveyor, Site Manager), and context of use.

- **Primary User Goal**: What is the operator trying to accomplish on this screen?
- **Workflow Context**: How did the operator arrive here? Where do they go next?
- **Operational Mode**: Is this exclusive to SPOT, CRUMBLING, or global across both?

---

## 2. Layout & Regions Table

Describe the visual structure, layout system (Single-view, 3:1 Calibration Grid, Tabbed Container, or Responsive Collection), and coordinate breakdown.

### Visual Architecture (Widget Tree)
```
Scaffold (backgroundColor: theme.pageBackground)
├── AppBar (kToolbarHeight = 56)
│   ├── Leading / Title Row (IconBox 40x40 + Title 18px + Subtitle 10px)
│   └── Actions [GlobalAppBarActions]
└── Body
    └── [Main Layout Container: e.g. Row(flex: 3, flex: 1) or Column]
        ├── Region A (e.g. Live Visualizer / Map / Workspace)
        └── Region B (e.g. Telemetry Cards / Control Cluster)
```

### Regions Breakdown
| Region ID | Area / Flex | Primary Contents | Responsive Behavior |
|-----------|-------------|------------------|---------------------|
| `header` | Fixed 56px | Icon, Title, Mode Badge, Global Actions | Stays sticky on top |
| `primary_work` | Flex: 3 | Main visual canvas, guidance bars, camera | Scales with window aspect ratio |
| `telemetry_rail`| Flex: 1 | Parameter stack, calibration cards, KPI gauges | Scrolls vertically if height < 600px |
| `bottom_bar` | Fixed 64px | Primary action buttons (Confirm, Save, Exit) | Full width footer |

---

## 3. Menu Structure & Navigation

- **Route Name**: `/[feature-name]`
- **Navigation Type**: Pushed via Router / Side Menu / Modal Dialog
- **Side Menu Association**: Which item in `SideMenu` is active (if applicable)?
- **Back Navigation**: Does pressing back discard unsaved changes? Show confirmation dialog?
- **Deep Linking / Parameters**: Query parameters or entity IDs required (e.g. `workfileId: int`).

---

## 4. Components Used

List all reusable design-system components and design tokens consumed.

| Component Name | Source / Package | Design Tokens Consumed | Configuration / Props |
|----------------|------------------|------------------------|-----------------------|
| `IconBox` | Design System | `theme.iconBoxBackground`, `theme.iconBoxIcon` | Size: 40×40, Icon: relevant icon |
| `SummaryCard` | Design System | `theme.cardSurface`, `theme.cardBorder` | Title, metric value, accent color |
| `SCADATextField`| Design System | `theme.inputBackground`, `theme.inputBorder` | Label, controller, validator |
| `StatusBadge` | Design System | `theme.statusActive` / `Standby` / `Inactive` | Multi-modal icon + status text |

---

## 5. Buttons & Clickable Elements

Every interactive element on this screen must be cataloged here.

| Element ID | Label / Icon | Min Touch Target | Trigger Handler | Dispatched Event / Action | Disabled When |
|------------|--------------|------------------|-----------------|---------------------------|---------------|
| `btn_save` | "SIMPAN" | $\ge 48\times48\text{ px}$ | `onSavePressed()` | `ref.read(presenter.notifier).save()` | `state.isLoading == true` |
| `btn_cancel`| "BATAL" | $\ge 48\times48\text{ px}$ | `onCancelPressed()`| `Navigator.of(context).pop()` | Never |
| `switch_mode`| Mode Switch | $\ge 48\times48\text{ px}$ | `onModeChanged(val)` | `ref.read(presenter.notifier).toggleMode(val)` | `state.isStreaming == true` |

---

## 6. Data Display & Calculations

All numeric, textual, and sensor values presented on screen.

| Display Field | Raw Source | Unit / Formatting | Angle Capping / Normalization | Update Frequency |
|---------------|------------|-------------------|-------------------------------|------------------|
| `boom_angle` | `IMU.boomPitch` | Degrees (`°`, 2 decimals) | Capped at $360.00^\circ$ (`min(v, 360.0)`) | 10 Hz (Serial telemetry) |
| `productivity`| `Presenter.productivity` | Spots / hour (`%d spots/hr`) | Positive integer | On spot completion |
| `rtk_accuracy`| `GPSLoc.accuracy` | Centimeters (`cm`, 1 decimal) | Highlight amber if $> 5.0\text{ cm}$ | 1 Hz |

---

## 7. Screen States

Document every valid visual state of the screen.

| State Name | Trigger / Condition | Visual Representation | User Actions Permitted |
|------------|---------------------|-----------------------|------------------------|
| `loading` | Initial startup / fetching DB | Centered spinner with `theme.loadingIndicatorColor` | Read-only; back navigation allowed |
| `normal` | Data loaded & telemetry active | Full interactive interface, green badges | All actions enabled |
| `offline_stale` | No serial packet for $\ge 2$s | Amber watchdog badge, frozen telemetry values | Reconnect button enabled |
| `error` | DB read failure or bad config | Error card with retry button and error details | Retry button, Return Home |
| `empty` | Zero records found | Empty placeholder illustration + "Add New" CTA | Create new record |

---

## 8. Events & Side Effects

Document all internal/external events and side-effects.

### Dispatched Events (`domain:pastTense`)
- `feature:initialized` — Emitted when presenter finishes initial loading.
- `feature:saved` — Emitted when user persists entity to local DB.
- `telemetry:staleDetected` — Emitted by watchdog when telemetry stream stalls.

### Side Effects (`ref.listen`)
- **Success Notification**: Triggered on `feature:saved` -> `NotificationService.showSuccess(context, 'Data tersimpan')`.
- **Audio Warning**: Triggered when bucket depth exceeds target threshold -> Play audio tone.
- **Auto-Navigation**: Pop dialog or navigate back to dashboard when operation completes.

---

## 9. Accessibility & Ergonomics

Verify all industrial and web accessibility mandates:
- [ ] **Gloved Touch Targets**: All clickable hitboxes $\ge 48\times48\text{ px}$ (cab standard).
- [ ] **Contrast Compliance**: Normal text $\ge 4.5:1$, critical telemetry numbers $\ge 7:1$ against surface.
- [ ] **Multi-Modal Redundancy**: No information communicated solely by color; always include text + icon.
- [ ] **Angle Capping Constraint**: All angular telemetry values capped at $360.00^\circ$ with `°` unit appended.
- [ ] **Web Pointer Cursor**: Clickable elements specify `cursor: SystemMouseCursors.click`.
- [ ] **Flex Safety**: Flex children wrap text with `maxLines: 1` and `TextOverflow.ellipsis`.

---

## 10. Test Cases

| Test Case ID | Description | Input / Condition | Expected Result |
|--------------|-------------|-------------------|-----------------|
| `TC-UI-01` | Renders correctly in Dark Mode | Theme = Dark SCADA | Background is `0xFF0D1118`, text legible |
| `TC-UI-02` | Renders correctly in Light Mode | Theme = Light SCADA | Background is `0xFFF5F7FA`, contrast $\ge 4.5:1$ |
| `TC-UI-03` | Save Button triggers presenter | Tap `#btn_save` | Calls `presenter.save()`, shows loader |
| `TC-UI-04` | Telemetry Stale Watchdog | No data for 2.1 seconds | Badge changes from Green to Amber |
| `TC-UI-05` | Responsive Web Resize | Resize window to 1024×768 | No `RenderFlex overflowed` warnings |

---

## 11. Open Questions & Assumptions

- [ ] *Question 1*: Confirm baud rate with hardware team (Default: 115200 8N1).
- [ ] *Question 2*: Should the auto-save interval trigger every 30 seconds or on screen blur?
- [ ] *Assumption*: Operator has valid credentials stored locally in Isar database.

---

## Appendix: Implementation Code Skeletons

### Presenter Skeleton (`lib/features/my_feature/presenter/my_feature_presenter.dart`)
```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class MyFeatureState {
  final bool isLoading;
  final String? errorMessage;
  final List<String> dataList;

  const MyFeatureState({
    this.isLoading = false,
    this.errorMessage,
    this.dataList = const [],
  });

  MyFeatureState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<String>? dataList,
  }) {
    return MyFeatureState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      dataList: dataList ?? this.dataList,
    );
  }
}

class MyFeaturePresenter extends Notifier<MyFeatureState> {
  @override
  MyFeatureState build() {
    Future.microtask(_initAsync);
    ref.onDispose(() {
      // Cancel timers or subscriptions
    });
    return const MyFeatureState(isLoading: true);
  }

  Future<void> _initAsync() async {
    try {
      // Fetch initial state asynchronously
      state = state.copyWith(isLoading: false, dataList: ['Item A', 'Item B']);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _initAsync();
  }
}

final myFeatureProvider = NotifierProvider<MyFeaturePresenter, MyFeatureState>(
  MyFeaturePresenter.new,
);
```

### UI Page Skeleton (`lib/features/my_feature/pages/my_feature_page.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/widgets/global_app_bar_actions.dart';
import '../presenter/my_feature_presenter.dart';

class MyFeaturePage extends ConsumerWidget {
  const MyFeaturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final state = ref.watch(myFeatureProvider);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
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
              child: Icon(Icons.featured_play_list, color: theme.iconBoxIcon, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FEATURE TITLE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 18,
                      color: theme.appBarForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'SUBTITLE / MODE',
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
        actions: const [
          GlobalAppBarActions(),
          SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.loadingIndicatorColor))
          : state.errorMessage != null
              ? Center(child: Text('Error: ${state.errorMessage}', style: const TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: state.dataList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(state.dataList[index], style: TextStyle(color: theme.textOnSurface)),
                      );
                    },
                  ),
                ),
    );
  }
}
```
