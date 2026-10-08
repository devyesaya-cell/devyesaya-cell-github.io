# GuidanceWidget Blueprint
Path: `lib/features/map/widgets/guidance_widget.dart`

`GuidanceWidget` adalah widget `ConsumerWidget` yang ditampilkan di sisi kanan peta saat Work Mode aktif (khusus mode SPOT, bukan CRUMBLING). Widget ini menampilkan panduan arah berbasis bar images ke 4 arah (kanan, kiri, atas, bawah) berdasarkan nilai deviasi `devX` dan `devY` dari presenter.

---

## 1. Class Declaration

```dart
class GuidanceWidget extends ConsumerWidget {
  const GuidanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapPresenterProvider);
    // ...
  }
}
```

**Visibilitas**: Dikontrol oleh `MapPage` via kondisi `if (mapState.isWorkMode && !isCrumblingMode)`.

---

## 2. Deviation & Bar Calculation

```dart
final devX = mapState.devX ?? 0.0;   // + = kanan, - = kiri
final devY = mapState.devY ?? 0.0;   // + = maju, - = mundur

int getActiveBars(double dev) {
  if (dev < 0.1) return 0;             // Threshold minimum: 10cm
  return (dev / 0.1).floor().clamp(0, 4);  // 1 bar per 10cm, max 4 bars
}

final int rightActive  = getActiveBars(devX);    // devX > 0
final int leftActive   = getActiveBars(-devX);   // devX < 0
final int topActive    = getActiveBars(devY);    // devY > 0 (Forward)
final int bottomActive = getActiveBars(-devY);   // devY < 0 (Backward)
```

### Bar Count Logic

| Deviasi (cm) | Active Bars |
|--------------|------------|
| < 10 cm | 0 |
| 10–19 cm | 1 |
| 20–29 cm | 2 |
| 30–39 cm | 3 |
| ≥ 40 cm | 4 (max) |

---

## 3. Scale Factor Calculation

```dart
final screenSize = MediaQuery.of(context).size;
final widgetSize = screenSize.height * 0.5;   // Widget = 50% tinggi layar
final double scale = widgetSize / 300.0;       // Referensi desain 300px
final double centerXY = widgetSize / 2;        // Center point widget
final double centerGap = 19.0 * scale;         // Gap dari center ke bar pertama
```

**Widget dimensions**: `width: widgetSize`, `height: widgetSize` (kotak, bukan persegi panjang).

---

## 4. Center Lock Logic

```dart
final bool isCenterLocked =
    mapState.targetSpot != null &&   // Harus ada target
    devX.abs() < 0.1 &&              // Dalam 10cm horizontal
    devY.abs() < 0.1;                // Dalam 10cm vertikal
```

Jika `isCenterLocked`:
- Center image → `images/done_icon.png` (dengan `color: Colors.greenAccent`)
- Semua bar = 0 (karena devX dan devY < 0.1)

---

## 5. Widget Tree — Stack Structure

```
SizedBox(width: widgetSize, height: widgetSize)
└── Stack(alignment: Alignment.center)
    ├── Background Image: 'images/target_bg.png' (full size)
    ├── Center Target Image (isCenterLocked ? done_icon : ic_cirle)
    ├── Right Bars (Positioned left: centerXY + centerGap)
    ├── Left Bars (Positioned right: centerXY + centerGap)
    ├── Bottom Bars (Positioned top: centerXY + centerGap)
    └── Top Bars (Positioned bottom: centerXY + centerGap)
```

---

## 6. Directional Bar Sets

Setiap arah memiliki 4 bar yang di-generate via `List.generate(4, ...)`.

### 6.1 Right Bars (East — devX > 0)

**Positioning**: `left: centerXY + centerGap`

```dart
Positioned(
  left: centerXY + centerGap,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      4,
      (index) => _buildBar(
        'images/right_tg.png',     // Active asset
        'images/right_no_tg.png',  // Inactive asset
        index < rightActive,       // Lit jika index < jumlah bar aktif
        width: 25 * scale,
        height: 40 * scale,
        padding: 2.0 * scale,
      ),
    ), // Inner → Outer order
  ),
)
```

### 6.2 Left Bars (West — devX < 0)

**Positioning**: `right: centerXY + centerGap`

```dart
Positioned(
  right: centerXY + centerGap,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      4,
      (index) => _buildBar(
        'images/left_tg.png',
        'images/left_no_tg.png',
        index < leftActive,
        width: 25 * scale,
        height: 40 * scale,
        padding: 2.0 * scale,
      ),
    ).reversed.toList(), // ← REVERSED: Outer → Inner (bar terdekat ke center = index 0)
  ),
)
```

### 6.3 Bottom Bars (South — devY < 0, Backward)

**Positioning**: `top: centerXY + centerGap`

```dart
Positioned(
  top: centerXY + centerGap,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      4,
      (index) => _buildBar(
        'images/down_tg.png',
        'images/down_no_tg.png',
        index < bottomActive,
        width: 40 * scale,
        height: 25 * scale,
        padding: 2.0 * scale,
      ),
    ), // Inner → Outer order
  ),
)
```

### 6.4 Top Bars (North — devY > 0, Forward)

**Positioning**: `bottom: centerXY + centerGap`

```dart
Positioned(
  bottom: centerXY + centerGap,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      4,
      (index) => _buildBar(
        'images/top_tg.png',
        'images/top_no_tg.png',
        index < topActive,
        width: 40 * scale,
        height: 25 * scale,
        padding: 2.0 * scale,
      ),
    ).reversed.toList(), // ← REVERSED: Outer → Inner
  ),
)
```

### Bar Dimensions Summary

| Direction | width | height | Row/Column |
|-----------|-------|--------|------------|
| Right / Left | `25 * scale` | `40 * scale` | `Row` |
| Top / Bottom | `40 * scale` | `25 * scale` | `Column` |

**padding**: `2.0 * scale` untuk semua arah.

---

## 7. Helper — `_buildBar`

```dart
Widget _buildBar(
  String activePath,
  String inactivePath,
  bool isActive, {
  double width = 20,
  double height = 20,
  double padding = 2.0,
}) {
  return Padding(
    padding: EdgeInsets.all(padding),
    child: Image.asset(
      isActive ? activePath : inactivePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    ),
  );
}
```

---

## 8. Image Assets Catalog

| Asset Path | Digunakan Untuk |
|------------|-----------------|
| `images/target_bg.png` | Background layer (crosshair/target background) |
| `images/ic_cirle.png` | Center icon — normal state (no target / not locked) |
| `images/done_icon.png` | Center icon — locked state (target dalam jangkauan) |
| `images/right_tg.png` | Right bar — active (lit) |
| `images/right_no_tg.png` | Right bar — inactive (dim) |
| `images/left_tg.png` | Left bar — active |
| `images/left_no_tg.png` | Left bar — inactive |
| `images/top_tg.png` | Top/Forward bar — active |
| `images/top_no_tg.png` | Top/Forward bar — inactive |
| `images/down_tg.png` | Bottom/Backward bar — active |
| `images/down_no_tg.png` | Bottom/Backward bar — inactive |

---

## 9. Center Image Logic

```dart
// Center Target
Image.asset(
  isCenterLocked ? 'images/done_icon.png' : 'images/ic_cirle.png',
  width: 40 * scale,
  height: 40 * scale,
  color: isCenterLocked ? Colors.greenAccent : null,  // Tint green saat locked
)
```

| State | Asset | Color Tint |
|-------|-------|-----------|
| No target / searching | `ic_cirle.png` | none |
| Target terkunci (< 10cm) | `done_icon.png` | `Colors.greenAccent` |

---

## 10. Reversed vs Non-Reversed

**Aturan ordering bar** (menentukan visual dari center ke luar):

| Arah | Order Generate | Hasil |
|------|---------------|-------|
| Right | Normal (0→3) | Bar 0 (inner) di dekat center, bar 3 (outer) di luar |
| Left | `.reversed` | Bar 3 (outer) di luar, bar 0 (inner) di dekat center |
| Bottom | Normal (0→3) | Bar 0 (inner) di dekat center |
| Top | `.reversed` | Bar 3 (outer) di atas, bar 0 (inner) di dekat center |

**Logika**: Bar yang paling dekat ke center selalu merupakan intensitas pertama. Bar menyala dari dalam ke luar sesuai intensitas deviasi.

---

> [!IMPORTANT]
> Widget ini hanya muncul saat `isWorkMode && !isCrumblingMode`. Untuk mode CRUMBLING, gunakan `CrumblingDeviationBar` sebagai gantinya. Kedua widget ini saling eksklusif dan dikontrol sepenuhnya dari `MapPage`.

> [!NOTE]
> Nilai `devX` dan `devY` dari `mapPresenterProvider` berada dalam satuan **meter**. Konversi ke bar: setiap 10cm (0.1m) = 1 bar. Jika `devX = null` (belum ada target), semua bar = 0 karena `devX ?? 0.0`.
