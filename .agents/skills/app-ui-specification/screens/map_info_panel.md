# MapInfoPanel Widget Blueprint
Path: `lib/features/map/widgets/map_info_panel.dart`

`MapInfoPanel` adalah widget `ConsumerWidget` yang ditampilkan di bagian bawah halaman Map. Berfungsi sebagai panel telemetri terpadu yang menampilkan 6 item informasi kritis real-time dalam satu baris horizontal.

---

## 1. Class Declaration

```dart
class MapInfoPanel extends ConsumerWidget {
  const MapInfoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapPresenterProvider);
    // ... RTK color logic ...
    return Container(...);
  }
}
```

**Dependencies**: Hanya membaca `mapPresenterProvider`. Tidak ada state lokal.

---

## 2. RTK Color Logic

```dart
Color rtkColor = Colors.red;  // Default: NO RTK
if (mapState.rtkStatus == 'RTK') {
  rtkColor = Colors.green;
} else if (mapState.rtkStatus == 'FLOAT') {
  rtkColor = Colors.orange;
}
// 'NO RTK' → tetap Colors.red
```

| rtkStatus | Color |
|-----------|-------|
| `'RTK'` | `Colors.green` |
| `'FLOAT'` | `Colors.orange` |
| `'NO RTK'` | `Colors.red` |

---

## 3. Container Root Styling

```dart
Container(
  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  decoration: BoxDecoration(
    color: const Color(0xFF1E241E).withOpacity(0.95),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [ /* 6 items + 5 dividers */ ],
  ),
)
```

| Token | Value |
|-------|-------|
| Background | `Color(0xFF1E241E).withOpacity(0.95)` |
| Border Radius | `BorderRadius.circular(16)` |
| Border | `Colors.green.withOpacity(0.4)`, width 1 |
| Shadow | `Colors.black54`, blurRadius 8 |

---

## 4. Panel Items (6 Items)

Panel ditata dalam `Row` dengan `MainAxisAlignment.spaceEvenly`. Setiap item dipisahkan oleh `_buildDivider()`.

### Item 1: Alert Status

```dart
_buildPanelItem(
  context: context,
  icon: Icons.warning_amber_rounded,
  label: mapState.lastError?.alertType ?? '-',
  color: mapState.lastError != null ? Colors.red : Colors.grey,
  onTap: () => _showAlertDetail(context, mapState),
)
```

### Item 2: Spot Progress

```dart
Builder(builder: (context) {
  final done = mapState.spotDone;
  final total = mapState.totalSpot;
  final pct = total > 0 ? (done / total * 100).toStringAsFixed(0) : '0';
  return _buildPanelItem(
    context: context,
    icon: Icons.forest_rounded,
    label: '$done/$total | $pct%',
    color: Colors.green,
    width: 160,   // ← Fixed width untuk prevent overflow
    onTap: () => _showProgressDetail(context),
  );
})
```

### Item 3: RTK Status (Text Only)

```dart
_buildPanelItem(
  context: context,
  label: mapState.rtkStatus,    // "RTK", "FLOAT", atau "NO RTK"
  color: rtkColor,              // Dinamis berdasarkan status
  isTextOnly: true,             // Tidak ada icon
  onTap: () => _showGpsDetail(context, mapState),
)
```

### Item 4: Heading

```dart
_buildPanelItem(
  context: context,
  icon: Icons.explore,
  label: '${mapState.heading?.toStringAsFixed(0) ?? '--'}°',
  color: Colors.orange,
)
```

### Item 5: Arm Length

```dart
_buildPanelItem(
  context: context,
  icon: Icons.construction,
  label: '${mapState.armLength.toStringAsFixed(1)} m',
  color: Colors.orange,
)
```

### Item 6: Pitch / Roll (Image-Based)

```dart
InkWell(
  onTap: () => _showPitchRollDetail(context, mapState),
  child: Row(
    children: [
      // Pitch (Side View)
      _buildRotatedImage('images/exca_left_color.png', mapState.fullGps?.pitch ?? 0),
      const SizedBox(width: 4),
      Text((mapState.fullGps?.pitch ?? 0).toStringAsFixed(1),
          style: const TextStyle(color: Colors.white)),
      const SizedBox(width: 12),
      // Roll (Back View)
      _buildRotatedImage('images/exca_back_color.png', mapState.fullGps?.roll ?? 0),
      const SizedBox(width: 4),
      Text((mapState.fullGps?.roll ?? 0).toStringAsFixed(1),
          style: const TextStyle(color: Colors.white)),
    ],
  ),
)
```

### Panel Items Summary

| # | Icon | Label Format | Color | onTap | Width |
|---|------|-------------|-------|-------|-------|
| 1 | `warning_amber_rounded` | `alertType` atau `'-'` | `Colors.red` / `Colors.grey` | `_showAlertDetail` | auto |
| 2 | `forest_rounded` | `'done/total \| pct%'` | `Colors.green` | `_showProgressDetail` | `160` |
| 3 | — (text only) | `rtkStatus` | `rtkColor` (dinamis) | `_showGpsDetail` | auto |
| 4 | `explore` | `'heading°'` | `Colors.orange` | — | auto |
| 5 | `construction` | `'armLength m'` | `Colors.orange` | — | auto |
| 6 | Image asset | pitch + roll values | `Colors.white` | `_showPitchRollDetail` | auto |

---

## 5. Helper Widgets

### `_buildPanelItem`

```dart
Widget _buildPanelItem({
  required BuildContext context,
  IconData? icon,
  String? label,
  Widget? labelWidget,
  Color color = Colors.black,
  double? width,
  bool isTextOnly = false,
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isTextOnly && icon != null) ...[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
          ],
          labelWidget ?? Text(
            label ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTextOnly ? color : Colors.white70,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
```

**Style rules**:
- Jika `isTextOnly: true` → text color = `color` parameter
- Jika `isTextOnly: false` → text color = `Colors.white70` (icon menggunakan `color`)
- Font: `FontWeight.bold`, `fontSize: 14`

### `_buildRotatedImage`

```dart
Widget _buildRotatedImage(String assetPath, double degrees) {
  return Transform.rotate(
    angle: degrees * (math.pi / 180),  // Konversi derajat ke radian
    child: Image.asset(assetPath, height: 30, width: 30),
  );
}
```

**Assets yang digunakan**:
- `images/exca_left_color.png` → Pitch indicator (tampak samping)
- `images/exca_back_color.png` → Roll indicator (tampak belakang)

### `_buildDivider`

```dart
Widget _buildDivider() {
  return Container(
    height: 24,
    width: 1,
    color: Colors.green.withOpacity(0.3),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}
```

---

## 6. Dialogs

Semua dialog menggunakan `DialogUtils.showDetailDialog` sebagai wrapper.

### 6.1 Alert Detail Dialog — `_showAlertDetail`

```
Guard: if (state.lastError == null) return;
```

Konten dialog (`Column`, `crossAxisAlignment.start`):
- `DialogUtils.buildKeyValue("Source ID", state.lastError!.sourceID)`
- `DialogUtils.buildKeyValue("Type", state.lastError!.alertType)`
- `DialogUtils.buildKeyValue("Message", state.lastError!.message)`
- `DialogUtils.buildKeyValue("Time", state.lastError!.timestamp.toString())`

### 6.2 GPS Detail Dialog — `_showGpsDetail`

```
Guard: if (state.fullGps == null && state.fullBase == null) return;
```

Status color resolusi sama dengan RTK Color Logic (section 2).

Konten dialog:
```
1. Colored status container:
   Container(padding: EdgeInsets.all(8), color: statusColor.withOpacity(0.1)):
   → buildKeyValue("Overall Status", state.rtkStatus, valueColor: statusColor)

2. buildKeyValue("Bucket Position", "${lat}, ${lng}")

3. buildSection("GPS 1")
   - buildKeyValue("Status", fullGps.status)
   - buildKeyValue("Accuracy (H/V)", "${hAcc1} / ${vAcc1} mm")
   - buildKeyValue("Satellites", "${satelit}")

4. buildSection("GPS 2")
   - buildKeyValue("Status", fullGps.status2)
   - buildKeyValue("Accuracy (H/V)", "${hAcc2} / ${vAcc2} mm")
   - buildKeyValue("Satellites", "${satelit2}")

5. buildSection("Base Station")
   - buildKeyValue("Status", fullBase.status)
   - buildKeyValue("Accuracy", "${fullBase.akurasi} mm")
   - buildKeyValue("Distance", "${fullGps.bsDistance} m")
   - buildKeyValue("Satellites", "${fullBase.satelit}")
   - buildKeyValue("RSSI", "${fullGps.rssi}")
   - buildKeyValue("Voltage", "${fullBase.batteryVoltage} V")
   - buildKeyValue("Current", "${fullBase.batteryCurrent} A")
```

### 6.3 Pitch/Roll Detail Dialog — `_showPitchRollDetail`

Konten: `Row` dengan `mainAxisAlignment.spaceAround`, dua kolom:
```
Left Column:               Right Column:
  Text("Pitch")              Text("Roll")
  SizedBox(h:8)              SizedBox(h:8)
  _buildRotatedImage(        _buildRotatedImage(
    'images/exca_left_color.png',  'images/exca_back_color.png',
    pitch)                   roll)
  SizedBox(h:8)              SizedBox(h:8)
  Text("${pitch}°", bold)    Text("${roll}°", bold)
```

### 6.4 Progress Detail Dialog — `_showProgressDetail`

```dart
DialogUtils.showDetailDialog(
  context: context,
  title: 'Work Progress',
  content: const Text('Not Implemented Yet'),
);
```

> [!NOTE]
> Dialog ini belum diimplementasikan. Placeholder untuk future development.

---

> [!NOTE]
> Item 6 (Pitch/Roll) tidak menggunakan `_buildPanelItem` helper. Ia menggunakan custom `InkWell` → `Row` langsung karena strukturnya berbeda (dua image + dua text dalam satu item).
