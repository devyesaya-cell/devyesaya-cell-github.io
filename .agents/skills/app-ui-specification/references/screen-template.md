# Screen Specification & Template Standard (screen-template.md)

> **Scope**: The 11-Section Screen Specification Standard and Production Implementation Skeletons for UI Development.  
> **Source of Truth**: This document is the single canonical source of truth for the screen contract and architectural guidelines. When creating a new screen spec in `screens/[name].md`, copy the ready blueprint at `screens/_TEMPLATE.md`.  

---

## 1. The 11-Section Screen Specification Standard

When specifying or auditing any screen (e.g. in `screens/[screen_name].md`), the document **MUST** adhere to the following 11 canonical sections:

| # | Section | Mandate & Contents |
|---|---------|-------------------|
| **1** | **Purpose** | Operational purpose, user persona (Operator, Surveyor, Admin), workflow context, and operational mode (SPOT, CRUMBLING, or SHARED). |
| **2** | **Layout & Regions Table** | Visual widget tree breakdown, layout grid selection (Single-view, 3:1 Grid, Tabbed Container, Responsive Grid), and regions table defining dimensions, flex ratios, and responsive behavior. |
| **3** | **Menu Structure & Navigation** | Route path, entry points, AppBar actions, breadcrumbs, Back navigation rules, and associated `SideMenu` active item ID. |
| **4** | **Components Used** | Comprehensive table of design system components, design tokens consumed (`theme.pageBackground`, `theme.cardSurface`, etc.), and required props. |
| **5** | **Buttons & Clickable Elements** | Catalog of all interactive elements: Hitbox size ($\ge 48\times48\text{ px}$ for touch), trigger handlers (`on<Action>Pressed`), dispatched actions, target states, and disabled conditions. |
| **6** | **Data Display & Calculations** | All telemetry and data fields: Raw source, formatting, units, update frequency, and angle capping normalization ($\le 360.00^\circ$). |
| **7** | **Screen States** | Complete UI state matrix: `loading`, `normal` (active), `offline_stale` (watchdog alert), `error`, and `empty` states. |
| **8** | **Events & Side Effects** | Internal and external events using `domain:pastTense` naming, payload schemas, and imperative side effects handled via `ref.listen` (dialogs, snacks, audio alerts). |
| **9** | **Accessibility & Ergonomics** | Gloved touch target audit ($\ge 48\times48\text{ px}$), contrast verification ($\ge 4.5:1$ text, $\ge 7:1$ critical telemetry), multi-modal redundancy (icon + label), and `cursor: pointer`. |
| **10** | **Test Cases** | Matrix of verification scenarios: Dark/Light theme rendering, button action dispatch, telemetry stale watchdog transitions, and window resize flex safety. |
| **11** | **Open Questions & Assumptions** | Open UX decisions, pending hardware calibrations, backend assumptions, and edge cases under review. |

---

## 2. Empty Specification Blueprint (`_TEMPLATE.md`)

When creating a new screen specification file in `screens/`, copy the empty template structure below:

```markdown
# Screen: [Screen Name]
> **File Target**: `lib/features/[feature]/pages/[screen_name]_page.dart`  
> **Widget Type**: `ConsumerWidget` / `ConsumerStatefulWidget`  
> **Presenter / Provider**: `[feature]PresenterProvider`  
> **Operational Mode**: SPOT / CRUMBLING / SHARED  

## 1. Purpose
[Describe operational workflow, user persona, and primary operator intent]

## 2. Layout & Regions Table
[Widget Tree and Layout Table: Header, Primary Canvas, Telemetry Rail, Footer]

## 3. Menu Structure & Navigation
[Route name, entry points, back button logic, active drawer item]

## 4. Components Used
[Table of Design System components and tokens consumed]

## 5. Buttons & Clickable Elements
[Table: Element ID, Label/Icon, Touch Target >= 48px, Handler, Action, Disabled State]

## 6. Data Display & Calculations
[Table: Label, Raw Source, Formatting, Angle Capping (<= 360.00°), Frequency]

## 7. Screen States
[State Matrix: loading, normal, offline_stale, error, empty]

## 8. Events & Side Effects
[domain:pastTense events, payload schemas, ref.listen side effects]

## 9. Accessibility & Ergonomics
[Gloved touch check, contrast compliance, multi-modal redundancy, cursor pointer]

## 10. Test Cases
[TC-01 Theme, TC-02 User Actions, TC-03 Hardware Watchdog, TC-04 Responsive Layout]

## 11. Open Questions & Assumptions
[Assumptions, hardware dependencies, pending team reviews]
```

---

## 3. Production Implementation Skeletons

### 3.1 Skeleton A: Standard Single-View Feature Screen

#### Presenter (`lib/features/my_feature/presenter/my_feature_presenter.dart`)
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
      // Load initial state asynchronously
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

#### UI Page (`lib/features/my_feature/pages/my_feature_page.dart`)
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

---

### 3.2 Skeleton B: Calibration Layout (3:1 Grid Rule)

Mandatory structural standard for sensor calibration tabs (`BoomCalibrationTab`, `StickCalibrationTab`, etc.):
- **Left Column (flex: 3)**: Top visual reference schematic (e.g. 3D arm or diagram) + Bottom live calibration cluster with zero-calibration buttons.
- **Right Column (flex: 1)**: Real-time sensor parameter stack with numerical gauges and angle capping ($\le 360.00^\circ$).

```dart
class CalibrationLayout extends ConsumerWidget {
  const CalibrationLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: 3/4 Flex
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.cardBorder),
                  ),
                  child: const Center(child: Text('Visual Machine Schematic')),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.cardBorder),
                  ),
                  child: const Text('Calibration Controls'),
                ),
              ),
            ],
          ),
        ),

        // Right Column: 1/4 Flex
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.cardBorder),
            ),
            child: ListView(
              children: const [
                Text('Sensor Parameters', style: TextStyle(fontWeight: FontWeight.bold)),
                Divider(),
                // Telemetry parameter items
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```
