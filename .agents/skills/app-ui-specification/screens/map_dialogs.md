# Map Dialogs & Notification Blueprint
Path: `lib/features/map/widgets/`

Dokumen ini mendokumentasikan semua dialog dan notification widget yang digunakan oleh fitur Map Page:
1. `TimesheetStartDialog` — Gate dialog saat masuk map (mulai shift)
2. `TimesheetEndDialog` — Exit dialog sebelum keluar map (akhir shift)
3. `CrumblingDeviationBar` — LED bar indicator untuk mode CRUMBLING
4. Digging Notification — Notifikasi sistem "spot siap digali"

---

## 1. TimesheetStartDialog

**File**: `lib/features/map/widgets/timesheet_start_dialog.dart`

### 1.1 Class Declaration

```dart
class TimesheetStartDialog extends ConsumerStatefulWidget {
  const TimesheetStartDialog({super.key});
  @override
  ConsumerState<TimesheetStartDialog> createState() => _TimesheetStartDialogState();
}
```

### 1.2 State Variables

```dart
class _TimesheetStartDialogState extends ConsumerState<TimesheetStartDialog> {
  final _hmController = TextEditingController();
  List<TimesheetData> _activities = [];     // Daftar aktivitas dari Isar
  TimesheetData? _selectedActivity;          // Aktivitas yang dipilih di dropdown
  bool _isLoading = true;                   // Loading state selama fetch Isar
}
```

### 1.3 `initState` → `_loadActivities()`

```dart
@override
void initState() {
  super.initState();
  _loadActivities();
}

Future<void> _loadActivities() async {
  final isar = DatabaseService().isar;
  // Query HANYA activityType == 'OPERASIONAL'
  final data = await isar.timesheetDatas
      .filter()
      .activityTypeEqualTo('OPERASIONAL')
      .findAll();

  setState(() {
    _activities = data;
    if (data.isNotEmpty) _selectedActivity = data.first;  // Default pilih pertama
    _isLoading = false;
  });
}
```

> **Query filter**: Hanya `activityType == 'OPERASIONAL'`. Aktivitas lain (maintenance, dll) tidak muncul di dropdown ini.

### 1.4 `_start()` — Action

```dart
void _start() {
  final hmText = _hmController.text;
  final hmStart = int.tryParse(hmText) ?? 0;

  // Validasi
  if (_selectedActivity == null) return;
  if (hmText.isEmpty || hmStart <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid HM Start')),
    );
    return;
  }

  final auth = ref.read(authProvider);
  final driverId = auth.currentUser?.uid.toString() ?? '0';
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final newRecord = TimesheetRecord(
    id: Isar.autoIncrement,
    modeSystem: 'Manual',
    activityType: _selectedActivity!.activityType ?? 'operasional',
    activityName: _selectedActivity!.activityName ?? 'Unknown',
    totalTime: 0,
    startTime: now,
    endTime: now,          // Akan diupdate saat stop
    hmStart: hmStart,
    hmEnd: hmStart,        // Akan diupdate saat stop
    totalSpots: 0.0,
    workspeed: 0.0,
    personID: driverId,
  );

  ref.read(mapPresenterProvider.notifier).startTimesheet(newRecord);
  Navigator.of(context).pop();
}
```

### 1.5 Loading State

Jika `_isLoading == true`, tampilkan:

```dart
return const AlertDialog(
  content: SizedBox(
    height: 100,
    child: Center(child: CircularProgressIndicator()),
  ),
);
```

### 1.6 Build — AlertDialog Styling

```dart
AlertDialog(
  backgroundColor: const Color(0xFF0F1410),  // Very dark background
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  title: const Text(
    'Start Recording Activity',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  content: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Activity Dropdown ---
        const Text('Activity Name', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        // Dropdown wrapped in Theme to change canvasColor
        Theme(
          data: Theme.of(context).copyWith(canvasColor: const Color(0xFF1A211D)),
          child: DropdownButtonFormField<TimesheetData>(
            value: _selectedActivity,
            isExpanded: true,
            style: const TextStyle(color: Colors.white),
            items: _activities.map((a) => DropdownMenuItem(
              value: a,
              child: Text(a.activityName ?? 'Unknown'),
            )).toList(),
            onChanged: (val) => setState(() => _selectedActivity = val),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2ECC71)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2ECC71), width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // --- HM Start Input ---
        const Text('HM Start', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _hmController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter HM Start Value',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2ECC71)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2ECC71), width: 2),
            ),
          ),
        ),
      ],
    ),
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
    ),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
      ),
      onPressed: _start,
      child: const Text('START', style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  ],
)
```

### 1.7 Styling Tokens

| Token | Value |
|-------|-------|
| Dialog background | `Color(0xFF0F1410)` |
| Dialog border radius | `BorderRadius.circular(16)` |
| Dropdown canvas color | `Color(0xFF1A211D)` |
| Border color (enabled) | `Color(0xFF2ECC71)` |
| Border width (focused) | `2` |
| Cancel button color | `Colors.redAccent` |
| Confirm button bg | `Color(0xFF2ECC71)` |
| Confirm button fg | `Colors.white` |

---

## 2. TimesheetEndDialog

**File**: `lib/features/map/widgets/timesheet_end_dialog.dart`

### 2.1 Class Declaration

```dart
class TimesheetEndDialog extends ConsumerStatefulWidget {
  const TimesheetEndDialog({super.key});
  @override
  ConsumerState<TimesheetEndDialog> createState() => _TimesheetEndDialogState();
}

class _TimesheetEndDialogState extends ConsumerState<TimesheetEndDialog> {
  final _hmController = TextEditingController();
}
```

### 2.2 `_stop()` — Action

```dart
void _stop() async {
  final hmText = _hmController.text;
  final hmEnd = int.tryParse(hmText) ?? 0;

  // Validasi
  if (hmText.isEmpty || hmEnd <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid HM End')),
    );
    return;
  }

  await ref.read(mapPresenterProvider.notifier).stopTimesheet(hmEnd: hmEnd);

  if (context.mounted) {
    Navigator.of(context).pop(true);  // Return true = success, map page akan pop
  }
}
```

### 2.3 Cancel Action

```dart
Navigator.of(context).pop(false);  // Return false = user cancelled
```

**Di MapPage**: `if (shouldExit == true && context.mounted) Navigator.of(context).pop();`

### 2.4 Alert Dialog Styling

Identik dengan `TimesheetStartDialog` (`backgroundColor: Color(0xFF0F1410)`, dll).

```dart
AlertDialog(
  backgroundColor: const Color(0xFF0F1410),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  title: const Text('Stop Recording Activity',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  content: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Please enter HM End before exiting the map.',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        const Text('HM End', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _hmController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter HM End Value',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2ECC71)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2ECC71), width: 2),
            ),
          ),
        ),
      ],
    ),
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.of(context).pop(false),
      child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
    ),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
      ),
      onPressed: _stop,
      child: const Text('STOP & EXIT', style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  ],
)
```

---

## 3. CrumblingDeviationBar

**File**: `lib/features/map/widgets/crumbling_deviation_bar.dart`

### 3.1 Class Declaration

```dart
class CrumblingDeviationBar extends ConsumerWidget {
  const CrumblingDeviationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapPresenterProvider);
    final deviation = mapState.crumblingDeviation;
    // ...
  }
}
```

**Visibilitas**: Dikontrol dari `MapPage` via `if (mapState.isWorkMode && isCrumblingMode)`.

### 3.2 Dimensions

```dart
final size = MediaQuery.of(context).size;
final barWidth = size.width * 0.45;   // ~45% lebar layar
final barHeight = size.height * 0.15; // ~15% tinggi layar
```

### 3.3 Active Index Calculation

Widget memiliki **11 bar** (index 0–10). Center = index 5.

```dart
final displayDev = deviation ?? 0.0;
int activeIndex = 5;  // Default: center

if (deviation == null || (displayDev >= -10 && displayDev <= 10)) {
  activeIndex = 5;  // Center: deviasi dalam ±10cm
} else if (displayDev < -10) {
  // Belok kiri lebih dari 10cm
  int steps = ((displayDev + 10).abs() / 10).ceil();
  activeIndex = 5 - steps;
  if (activeIndex < 0) activeIndex = 0;  // Cap di kiri
} else {
  // Belok kanan lebih dari 10cm
  int steps = ((displayDev - 10) / 10).ceil();
  activeIndex = 5 + steps;
  if (activeIndex > 10) activeIndex = 10;  // Cap di kanan
}
```

### 3.4 Index & Deviation Mapping

| Deviation | activeIndex | Sisi |
|-----------|-------------|------|
| ≤ ±10 cm | 5 | Center |
| -11 to -20 | 4 | Kiri 1 |
| -21 to -30 | 3 | Kiri 2 |
| -31 to -40 | 2 | Kiri 3 |
| < -40 | 1–0 | Kiri jauh |
| +11 to +20 | 6 | Kanan 1 |
| +21 to +30 | 7 | Kanan 2 |
| +31 to +40 | 8 | Kanan 3 |
| > +40 | 9–10 | Kanan jauh |

### 3.5 Container Styling

```dart
Container(
  width: barWidth,
  height: barHeight,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    color: const Color(0xFF1E241E).withOpacity(0.95),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
  ),
  // ...
)
```

### 3.6 Bar Row (11 bars)

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Bar Row
    Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(11, (index) {
          if (index == 5) {
            // Center bar — selalu lebih besar dan selalu ada glow
            return _buildCenterBarItem(Colors.greenAccent, activeIndex == 5);
          }
          final isLit = index == activeIndex;
          Color litColor;
          if (isLit) {
            litColor = (index - 5).abs() >= 3 ? Colors.redAccent : Colors.orangeAccent;
          } else {
            litColor = Colors.green.withOpacity(0.1);
          }
          return _buildBarItem(isLit ? litColor : Colors.green.withOpacity(0.1), isLit);
        }),
      ),
    ),
    const SizedBox(height: 8),
    // Label Row
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('L', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54)),
        Text(
          deviation == null ? '-- cm' : '${displayDev.abs().toStringAsFixed(1)} cm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: activeIndex == 5 ? Colors.greenAccent : Colors.redAccent,
          ),
        ),
        const Text('R', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54)),
      ],
    ),
  ],
)
```

### 3.7 Bar Color Logic

| Kondisi | Bar Color |
|---------|-----------|
| `isLit && (index-5).abs() >= 3` | `Colors.redAccent` (ekstrem) |
| `isLit && (index-5).abs() < 3` | `Colors.orangeAccent` (dekat) |
| `!isLit` | `Colors.green.withOpacity(0.1)` (dim) |
| Center (index==5), `activeIndex == 5` | `Colors.greenAccent` (centered) |

### 3.8 Bar Helper Widgets

#### `_buildBarItem` (Regular Bar)

```dart
Widget _buildBarItem(Color color, bool isLit) {
  return Expanded(
    flex: 1,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: isLit
            ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)]
            : [],
      ),
    ),
  );
}
```

#### `_buildCenterBarItem` (Center Bar — Bigger)

```dart
Widget _buildCenterBarItem(Color color, bool isLit) {
  return Expanded(
    flex: 3,   // ← 3× lebar dari bar biasa
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 50,   // ← Lebih tinggi (50 vs 40)
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: isLit
            ? [BoxShadow(color: color.withOpacity(0.8), blurRadius: 12, spreadRadius: 3)]
            : [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, spreadRadius: 1)],
            // ← Center selalu punya glow, bahkan saat tidak aktif
      ),
    ),
  );
}
```

| Property | Regular Bar | Center Bar |
|----------|------------|------------|
| `Expanded.flex` | 1 | 3 |
| `height` | 40 | 50 |
| `margin horizontal` | 2 | 4 |
| `borderRadius` | 2 | 4 |
| Glow saat tidak aktif | Tidak | **Ya** (opacity 0.3) |
| Glow saat aktif | Ya (0.6, blur 10) | Ya (0.8, blur 12, spread 3) |

---

## 4. Digging Notification

**Dipanggil dari**: `MapPresenter.showDiggingNotification(context)`
**Trigger di MapPage**: `if (previous != null && !previous.diggingStatus && next.diggingStatus)`

```dart
// Di map_presenter.dart
void showDiggingNotification(BuildContext context) {
  NotificationService.showCommandNotification(
    context,
    title: 'Digging Status',
    message: 'Spot siap di gali',
    modeStr: 'READY',
    icon: Icons.agriculture,
    iconColor: Colors.greenAccent,
    headerColor: Colors.green.shade900,
  );
}
```

| Parameter | Value |
|-----------|-------|
| `title` | `'Digging Status'` |
| `message` | `'Spot siap di gali'` |
| `modeStr` | `'READY'` |
| `icon` | `Icons.agriculture` |
| `iconColor` | `Colors.greenAccent` |
| `headerColor` | `Colors.green.shade900` |

**Dipanggil dari `MapPage`** dengan passing context:
```dart
ref.read(mapPresenterProvider.notifier).showDiggingNotification(context);
```

---

## 5. DialogUtils.showDelayConfigDialog

**File referensi**: `lib/core/utils/dialog_utils.dart`

Dipanggil dari Settings button di menu map:

```dart
DialogUtils.showDelayConfigDialog(
  context: context,
  currentDelay: ref.read(mapPresenterProvider).spotCompletionDelay,
  onSave: (val) {
    ref.read(mapPresenterProvider.notifier).setSpotCompletionDelay(val);
  },
);
```

| Parameter | Type | Deskripsi |
|-----------|------|-----------|
| `context` | `BuildContext` | — |
| `currentDelay` | `double` | Nilai delay saat ini (default: 2.0 detik) |
| `onSave` | `Function(double)` | Callback saat user menyimpan nilai baru |

---

> [!IMPORTANT]
> `TimesheetStartDialog` harus dipanggil dengan `barrierDismissible: false` agar user tidak bisa menutupnya tanpa mengisi data. Demikian pula `TimesheetEndDialog`. Keduanya merupakan gate yang mengontrol lifecycle sesi kerja.

> [!NOTE]
> Unit deviasi pada `CrumblingDeviationBar` adalah **sentimeter (cm)**, bukan meter. Nilai dari `state.crumblingDeviation` sudah dalam cm (dikalikan 100 di presenter). Label ditampilkan sebagai absolute value (`displayDev.abs()`) dengan tanda L/R dari posisi bar.
