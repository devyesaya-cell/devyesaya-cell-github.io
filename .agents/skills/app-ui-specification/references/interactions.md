# State Management & Interaction Architecture (Riverpod 3 + MVVM)

> **Architecture**: MVVM (Model-View-ViewModel) with Presenter Pattern  
> **Framework**: Flutter + `flutter_riverpod: ^3.2.1` + `isar_community: 3.3.0-dev.3`  
> **Key Implementations**: Feature Presenters (`lib/features/*/presenter/*_presenter.dart`), Services (`lib/core/services/`), State Stores (`lib/core/state/`)

---

## 1. Architectural Overview

The application strictly enforces the **Presenter Pattern (MVVM)** powered by **Riverpod 3**. All application state, hardware telemetry, business rules, and database persistence are decoupled from the UI layer.

```
┌────────────────────────────────────────────────────────────────────────┐
│                               UI LAYER                                 │
│   Thin Widgets (ConsumerWidget / ConsumerStatefulWidget)               │
│   - Renders state via ref.watch(provider)                              │
│   - Dispatches user intent via ref.read(provider.notifier).action()    │
│   - Listens to side effects via ref.listen(provider, ...)              │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │  Reactive State / User Actions
┌───────────────────────────────────▼────────────────────────────────────┐
│                           PRESENTER LAYER                              │
│   Riverpod Notifier<State> (e.g. MapPresenter, TimesheetNotifier)      │
│   - Encapsulates business logic & kinematics calculations              │
│   - Emits immutable state updates (copyWith)                           │
│   - Coordinates atomic database transactions with AppRepository        │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │  Streams / DTOs / Persistence
┌───────────────────────────────────▼────────────────────────────────────┐
│                    DATA & HARDWARE SERVICE LAYER                       │
│   ComService (RS232/USB) │ Isar DB (AppRepository) │ CoordinateService │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Standard Feature Implementation Pattern

Every feature module consists of three core elements:
1. **Immutable State Class** (`FeatureState`)
2. **Presenter Class** (`FeaturePresenter` extending `Notifier<FeatureState>`)
3. **Global Provider Definition** (`NotifierProvider` using modern constructor tear-offs)

### 2.1 Immutable State Class Blueprint
State classes are immutable data holders. All fields must be `final`, have sensible defaults, and provide a comprehensive `copyWith` method.

```dart
@immutable
class FeatureState {
  final bool isLoading;
  final String? errorMessage;
  final List<WorkItem> items;
  final double progressPercent;

  const FeatureState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.progressPercent = 0.0,
  });

  FeatureState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<WorkItem>? items,
    double? progressPercent,
  }) {
    return FeatureState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      items: items ?? this.items,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }
}
```

### 2.2 Feature Presenter (Notifier) Blueprint
The Presenter isolates business rules, timers, and database operations:

```dart
class FeaturePresenter extends Notifier<FeatureState> {
  Timer? _periodicTimer;

  @override
  FeatureState build() {
    // 1. Return synchronous default initial state
    // 2. Schedule any async startup or database reads safely
    Future.microtask(_initFeatureAsync);

    // 3. Register teardown listener
    ref.onDispose(() {
      _periodicTimer?.cancel();
    });

    return const FeatureState(isLoading: true);
  }

  Future<void> _initFeatureAsync() async {
    try {
      final repo = ref.read(appRepositoryProvider);
      final items = await repo.loadWorkItems();
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// User action: add or modify item
  Future<void> addItem(WorkItem item) async {
    final repo = ref.read(appRepositoryProvider);
    await repo.saveWorkItem(item);
    state = state.copyWith(items: [...state.items, item]);
  }
}
```

### 2.3 Provider Declaration (Riverpod 3 Tear-off Syntax)
In accordance with Riverpod 3 standards, instantiate providers using constructor tear-offs (`FeaturePresenter.new`):

```dart
final featureProvider = NotifierProvider<FeaturePresenter, FeatureState>(
  FeaturePresenter.new,
);
```

---

## 3. Interaction, Event & Error Conventions

To maintain strict consistency and eliminate ambiguous callback implementations across all screens, follow these unified interaction conventions:

### 3.1 Handler Naming & Signatures
All UI event handlers must follow a strict, standardized naming convention:
- **Button taps / Click events**: `on<Action>Pressed()` or `on<Action>Tapped()` (e.g. `onSavePressed()`, `onDeleteConfirmed()`, `onCancelTapped()`).
- **Value changes**: `on<Field>Changed(<Type> value)` (e.g. `onSearchQueryChanged(String query)`, `onFilterModeChanged(SystemMode mode)`).
- **Confirmation dialog triggers**: `on<Action>Requested()` prior to confirmation; `on<Action>Confirmed()` on dialog approval.
- **Presenter methods called**: Use verb-first action names on presenters (e.g. `presenter.saveItem()`, `presenter.deleteRecord()`, `presenter.startSession()`).

### 3.2 Event Naming & Payload Schema Rules
When emitting telemetry events, audit logs, or cross-module domain notifications, use the lowercase colon-separated `domain:pastTense` standard.

#### Payload Schema Constraints:
1. **Compactness**: Maximum **5 fields** per event payload to prevent cognitive bloat and excessive memory overhead.
2. **Timestamps**: Integer Unix epoch seconds (`int timestamp`) for consistency across platforms.
3. **Binary Data**: Use `Uint8List` or hex strings (`"0x..."`) for binary payloads; never raw unencoded string streams.
4. **Idempotency**: Include a client UUID (`uuid: string`) for any event triggering database writes or cloud synchronization.

| Domain | Event Identifier | Description | Payload Schema |
|---|---|---|---|
| **Auth** | `auth:signedIn` | Operator logged into cab system | `{ operatorId: int, mode: string, timestamp: int }` |
| **Auth** | `auth:signedOut` | Operator logged out | `{ operatorId: int, durationSeconds: int, timestamp: int }` |
| **Workfile** | `workfile:selected` | Operator activated workfile | `{ workfileId: int, workfileName: string, timestamp: int }` |
| **Spot** | `spot:completed` | Bucket reached target depth on spot | `{ spotId: int, devX: double, devY: double, depth: double }` |
| **Calibration** | `calibration:calibrated` | Arm sensor zero-offset saved | `{ sensorType: string, offsetAngle: double, timestamp: int }` |
| **Telemetry** | `telemetry:staleDetected` | Watchdog noticed $>2$s packet gap | `{ channel: string, elapsedSeconds: double, timestamp: int }` |

### 3.3 Error Classification & Response Mapping (`AppError`)
All system errors are encapsulated into typed domain exceptions mapped directly to standardized UI responses:

```dart
sealed class AppError {
  final String message;
  final int timestamp;
  const AppError(this.message, this.timestamp);
}

class NetworkError extends AppError {
  final int? statusCode;
  const NetworkError(super.message, super.timestamp, [this.statusCode]);
}

class HardwareError extends AppError {
  final String portName;
  const HardwareError(super.message, super.timestamp, this.portName);
}

class ValidationError extends AppError {
  final String fieldName;
  const ValidationError(super.message, super.timestamp, this.fieldName);
}

class DatabaseError extends AppError {
  const DatabaseError(super.message, super.timestamp);
}
```

#### UI Feedback Mapping Table:
| Error Category | UI Feedback Pattern | User Action Permitted |
|---|---|---|
| `NetworkError` | Non-intrusive SnackBar (`NotificationService.showError`) | Background queue auto-retries; UI continues operating offline |
| `HardwareError` | Status badge turns Amber/Red; audio alarm tone | Reconnect button enabled; manual port re-scan |
| `ValidationError` | Field border turns Red (`theme.inputErrorBorder`); error text below field | Form submit disabled until field is valid |
| `DatabaseError` | Modal alert dialog with technical details | Retry button or dismiss |

### 3.4 Side Effects Handling (`ref.listen`)
**RULE**: Never trigger imperative side effects (snackbars, navigation, modals, audio alerts) directly within `build()`. Always consume `ref.listen` inside the widget's `build` method:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Listen for error updates
  ref.listen<FeatureState>(featureProvider, (previous, next) {
    if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
      NotificationService.showError(context, next.errorMessage!);
    }
  });

  // Listen for navigation triggers
  ref.listen<bool>(featureProvider.select((s) => s.isComplete), (prev, isComplete) {
    if (isComplete == true) {
      Navigator.of(context).pop();
    }
  });

  return ...;
}
```

### 3.5 Debounce Delays & Throttling
- **Search & Filter Inputs**: Debounce user typing by **300ms** before triggering query re-computation.
- **Telemetry UI Refresh**: Throttle high-frequency RS232 sensor telemetry ($>20\text{ Hz}$) to a maximum of **10 Hz** (100ms) for visual widget rendering to prevent UI thread frame drops.

---

## 4. Real-Time Telemetry & Stream Management

The system receives high-frequency RS232 binary telemetry from Rover and Sensor nodes (GNSS coordinates, RTK fix, IMU tilts).

### 4.1 Service-Level Broadcast Controllers
In `ComService` (`lib/core/coms/com_service.dart`), raw incoming packets are parsed and streamed via `StreamController<T>.broadcast()`:

```dart
class ComService extends Notifier<UsbState> {
  final StreamController<GPSLoc> _gpsController = StreamController<GPSLoc>.broadcast();
  final StreamController<CalibrationData> _calibController = StreamController<CalibrationData>.broadcast();

  Stream<GPSLoc> get gpsStream => _gpsController.stream;
  Stream<CalibrationData> get calibStream => _calibController.stream;
}
```

### 4.2 Riverpod `StreamProvider` Wrapper
Telemetry streams are exposed to the UI via `StreamProvider.autoDispose` with `ref.keepAlive()`:

```dart
final gpsStreamProvider = StreamProvider.autoDispose<GPSLoc>((ref) {
  ref.keepAlive();
  return ref.watch(comServiceProvider.notifier).gpsStream;
});

final calibStreamProvider = StreamProvider.autoDispose<CalibrationData>((ref) {
  ref.keepAlive();
  return ref.watch(comServiceProvider.notifier).calibStream;
});
```

### 4.3 UI Stream Consumption Rule
**NEVER** use inline `StreamBuilder` widgets inside UI components. Always consume Riverpod `StreamProvider` via `.when(...)`:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final calibAsync = ref.watch(calibStreamProvider);

  return calibAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (err, stack) => Text('Telemetry Error: $err', style: const TextStyle(color: Colors.red)),
    data: (data) => Column(
      children: [
        Text('Boom Tilt: ${(data.boomTilt > 360 ? 360.0 : data.boomTilt).toStringAsFixed(2)}°'),
      ],
    ),
  );
}
```

---

## 5. UI Interaction Contract & State Ownership (Thin UI Pattern)

The UI layer must remain pure presentation. UI widgets (`ConsumerWidget` or `ConsumerStatefulWidget`) must follow these interaction rules:
- **`ref.watch(provider)`**: Used inside `build()` to trigger widget re-renders when state changes.
- **`ref.read(provider.notifier).action()`**: Used inside event handlers (`onPressed`, `onTap`, callbacks) to dispatch user intent. **NEVER** use `ref.watch` inside callbacks.
- **`ref.listen(provider, (prev, next) { ... })`**: Used inside `build()` to trigger imperative side-effects (e.g. showing a SnackBar, opening a dialog, playing audio alerts).

### 5.1 Single Store Ownership Principle
Each slice of application state belongs to exactly **one** store:
- `FeaturePresenter` owns the presentation state of its feature view (`isLoading`, `selectedItem`, `filterQuery`).
- `ComService` exclusively owns hardware serial port state (`UsbState`, connection status, baud rate).
- `AuthState` exclusively owns operator identity, authentication token, and operational mode (`SystemMode`).
- `AppRepository` owns database cache and transaction execution boundaries.

**Rule**: Never mutate another store's private state. Invoke only public action methods on that store's notifier.

---

## 6. Atomic Persistence Standard (Isar Resilience)

Multiple concurrent writes to the local Isar database can cause transaction conflicts (`writeTxn`). To ensure persistence integrity:
1. **Atomic Presenter Methods**: Group related field updates and database writes into a single atomic presenter method.
2. **Single Transaction Boundary**: Execute database writes in a single `isar.writeTxn(...)` block via `AppRepository`.
3. **Preserve Entity IDs**: When persisting existing configuration objects, always preserve the existing database `id` to prevent entity duplication.

---

## 7. Hand-Off Rules to Peer Skills

To maintain clean separation of concerns, the UI specification layer strictly delegates non-UI domain tasks:

| Domain | Responsible Peer Skill | UI Layer Boundary |
|---|---|---|
| **Binary RS-232 Framing & OpCodes** | `command-protocol` | UI never parses `0xAA 0x55` frames, validates CRC, or serializes OpCodes. |
| **Physical Serial / BLE Link State** | `transport-operations` | UI only observes abstract `ConnectionStatus` (Disconnected, Connected, etc.). |
| **Payload Formatting & Cloud Sync** | `response-preparation` | UI never crafts HTTP REST sync payloads or manages file I/O locks directly. |
| **Project Creation & Scaffolding** | `project-scaffolding` | UI skill specifies per-screen widgets; scaffolding sets up framework & build configs. |

---

## 8. Mode Isolation Guardrail (SPOT vs CRUMBLING)

The application operates under two mutually exclusive operational modes:
- **SPOT Mode**: Spot-by-spot excavator bucket positioning and circular tolerance verification.
- **CRUMBLING Mode**: Trench/contour guidance, Level of Detail (LoD) line simplification, and 2m sub-segment sweep tracking.

```
┌─────────────────────────────────────────────────────────────┐
│                    MODE ISOLATION RULE                      │
├──────────────────────────────┬──────────────────────────────┤
│          SPOT MODE           │        CRUMBLING MODE        │
│  - Spot grid calculation     │  - Segment sweep progress    │
│  - Spot completion delay     │  - Crumbling radius window   │
│  - Tolerance devX / devY     │  - Crumbling bend threshold  │
└──────────────────────────────┴──────────────────────────────┘
```

> [!CAUTION]
> When modifying or debugging logic in **SPOT Mode**, developers and AI assistants are **STRICTLY PROHIBITED** from touching or altering logic in **CRUMBLING Mode**, and vice-versa. Any shared architectural modifications require prior user confirmation.
