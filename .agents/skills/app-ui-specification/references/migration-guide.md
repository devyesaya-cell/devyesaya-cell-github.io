# Migration Guide: Reverse-Documenting & Modernizing Legacy Screens

> **Target**: Refactoring legacy screens into modern application standards  
> **Core Paradigms**: Thin UI (`ConsumerWidget`), Riverpod 3 Presenter (`Notifier<T>`), Design Tokens (`AppTheme`), Atomic Persistence, and Web/Ergonomic Accessibility.

---

## 1. Overview & 5-Phase Migration Workflow

Older screens in the codebase or prototype implementations often exhibit typical legacy technical debt:
- Monolithic `StatefulWidget` with excessive inline `setState()` calls.
- Inline database writes (`isar.writeTxn`) and serial port access inside widget build methods.
- Hardcoded inline hex colors (`Color(0xFF1A2235)`) instead of `AppTheme.of(context)` tokens.
- Raw `StreamBuilder` widgets listening directly to streams without lifecycle protection.
- Unhandled render overflows (`RenderFlex overflowed`) when window size changes.
- Direct `dart:io` imports that crash when compiled to **Flutter Web**.

To safely refactor any legacy screen, follow this systematic **5-Phase Migration Pipeline**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        5-PHASE MIGRATION PIPELINE                      │
├─────────────────┬──────────────────┬─────────────────┬─────────────────┤
│ PHASE 1         │ PHASE 2          │ PHASE 3         │ PHASE 4         │
│ DISCOVERY       │ SCAFFOLD         │ REVERSE-DOCUMENT│ VALIDATION      │
│ Audit & Map     │ Dir & Presenter  │ 11-Section Spec │ QA & Analysis   │
├─────────────────┴──────────────────┴─────────────────┴─────────────────┤
│ PHASE 5                                                                │
│ ADOPTION & ROUTE REPLACEMENT                                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Phase 1: Discovery (Audit Legacy Inventory)

Perform a comprehensive inventory of the existing screen before touching any code:

```markdown
### Legacy Screen Discovery Card: [ScreenName]
- **Legacy File**: `lib/features/.../old_screen.dart`
- **Primary Operational Mode**: SPOT / CRUMBLING / SHARED
- **Hardware Dependencies**: RS232 Serial (OpCodes), GNSS, IMU Tilts
- **Database Collections**: Person, Equipment, Workfile, MapConfig, TimesheetRecord
- **State Inventory**:
  - `isLoading`: bool
  - `selectedItem`: Entity?
  - `sensorValue`: double
- **Timers & Subscriptions**:
  - `Timer.periodic(...)` (for live polling or calculations)
  - `StreamSubscription<GPSLoc>`
- **User Actions**:
  - Tap button -> sends command to port
  - Change slider -> updates local value and writes to DB
```

---

## 3. Phase 2: Scaffold (Directory & Presenter Architecture)

1. Create target feature directory:
   ```
   lib/features/[feature_name]/
   ├── pages/
   │   └── [feature_name]_page.dart
   ├── presenter/
   │   └── [feature_name]_presenter.dart
   └── widgets/
       └── [feature_specific_widgets].dart
   ```
2. Create immutable state class (`[Feature]State`) with `final` fields and `copyWith`.
3. Create Presenter class (`[Feature]Presenter extends Notifier<[Feature]State>`) and declare `NotifierProvider` using tear-off syntax (`[Feature]Presenter.new`).
4. Relocate all business algorithms, timers, and database persistence into the presenter.

---

## 4. Phase 3: Reverse-Document (The 11-Section Specification)

Create or update `screens/[feature_name].md` using the canonical 11-section template (`screens/_TEMPLATE.md`):
1. **Purpose**: User persona, goal, and operational mode.
2. **Layout & Regions Table**: Layout grid and dimension allocation.
3. **Menu Structure**: Route path and navigation associations.
4. **Components Used**: Design system elements and tokens consumed.
5. **Buttons & Clickable Elements**: Touch targets ($\ge 48\times48\text{ px}$), handlers, and actions.
6. **Data Display & Calculations**: Units, precision, and angle capping ($\le 360.00^\circ$).
7. **Screen States**: `loading`, `normal`, `offline_stale`, `error`, and `empty`.
8. **Events & Side Effects**: `domain:pastTense` events and `ref.listen` side effects.
9. **Accessibility & Ergonomics**: Gloved touch, contrast ratios, and `cursor: pointer`.
10. **Test Cases**: Verification scenarios.
11. **Open Questions**: Unresolved assumptions.

---

## 5. Phase 4: Validation (Tokenize, Thin UI & QA Pass)

1. **Tokenize Theme**: Replace all hardcoded colors, opacities, and raw decorations with `AppTheme.of(context)` tokens.
2. **Decouple UI to Thin Widget**: Build `ConsumerWidget`, binding view reactively to `ref.watch(provider)` and dispatching actions via `ref.read(provider.notifier).action()`.
3. **Flex & Overflow Validation**: Wrap text in flex rows/columns with `maxLines: 1` and `overflow: TextOverflow.ellipsis`.
4. **Web Pointer Ergonomics**: Ensure all clickable cards/buttons show `cursor: SystemMouseCursors.click`.
5. **Mode Isolation Check**: Verify SPOT and CRUMBLING modes remain strictly partitioned.
6. **Static Analysis**: Execute `flutter analyze` ensuring **zero warnings and zero errors**.

---

## 6. Phase 5: Adoption (Route Wiring & Legacy Deprecation)

1. **Route Swap**: Update router or `SideMenu` navigation to point to the newly constructed `[Feature]Page`.
2. **Regression Testing**: Verify that all functional requirements, telemetry streams, and database transactions operate seamlessly.
3. **Deprecate & Remove Legacy Code**: Safely delete the old monolithic file after verifying clean compilation and test passes.

---

## 7. Migration Example: Before & After

### 7.1 Legacy Screen (Anti-Pattern)
```dart
// ❌ LEGACY CODE (Monolithic, hardcoded colors, inline DB write)
class OldSettingPage extends StatefulWidget {
  const OldSettingPage({super.key});
  @override
  _OldSettingPageState createState() => _OldSettingPageState();
}

class _OldSettingPageState extends State<OldSettingPage> {
  bool _loading = false;
  double _tilt = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _tilt = 12.5; // Direct poll
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1118), // Hardcoded color
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Column(
          children: [
            Text('Tilt: $_tilt'), // Missing 360° capping, missing unit
            ElevatedButton(
              onPressed: () {
                // Direct database write inside button callback
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}
```

### 7.2 Migrated Modern Screen (Clean MVVM)
```dart
// ✅ MODERN CODE (Thin ConsumerWidget, tokens, presenter isolation)
class ModernSettingPage extends ConsumerWidget {
  const ModernSettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final state = ref.watch(modernSettingProvider);

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
              child: Icon(Icons.settings, color: theme.iconBoxIcon, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 18,
                    color: theme.appBarForeground,
                  ),
                ),
                Text(
                  'HARDWARE CONFIGURATION',
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Capped at 360° with degree symbol
            Text(
              '${(state.tilt > 360 ? 360.0 : state.tilt).toStringAsFixed(2)}°',
              style: TextStyle(
                color: theme.textOnSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryButtonBackground,
                foregroundColor: theme.primaryButtonText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // Dispatch action cleanly to Presenter
                ref.read(modernSettingProvider.notifier).saveConfiguration();
              },
              child: const Text('SAVE SETTINGS'),
            ),
          ],
        ),
      ),
    );
  }
}
```
