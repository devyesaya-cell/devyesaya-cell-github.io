# Map Page Blueprint
Path: `lib/features/map/map_page.dart`

`MapPage` adalah halaman utama GIS yang menampilkan peta real-time, posisi excavator, dan panduan penggalian. Halaman ini menggunakan `ConsumerStatefulWidget` karena membutuhkan state lokal (`_controller`, `_showMenu`, `_hasInitialCenter`) sekaligus mengonsumsi Riverpod provider.

---

## 1. File Structure & Imports

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'map_presenter.dart';
import 'widgets/guidance_widget.dart';
import 'widgets/map_info_panel.dart';
import 'widgets/timesheet_start_dialog.dart';
import 'widgets/timesheet_end_dialog.dart';
import 'widgets/crumbling_deviation_bar.dart';
import '../../core/state/auth_state.dart';
import '../../core/utils/dialog_utils.dart';
```

---

## 2. Class Declaration & Local State

```dart
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});
  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  static const double _defaultZoom = 14.0;
  bool _showMenu = false;           // Kontrol visibilitas menu floating buttons
  MapController? _controller;       // Handle ke MapLibre controller
  bool _hasInitialCenter = false;   // Flag: apakah kamera sudah di-center pertama kali
}
```

### Local State Variables

| Variable | Type | Default | Deskripsi |
|----------|------|---------|-----------|
| `_defaultZoom` | `double` (const) | `14.0` | Zoom level awal saat map dibuka |
| `_showMenu` | `bool` | `false` | Toggle visibilitas Zoom & Mode menu |
| `_controller` | `MapController?` | `null` | Controller MapLibre, diisi saat `onMapCreated` |
| `_hasInitialCenter` | `bool` | `false` | Mencegah auto-center ganda saat standby mode |

---

## 3. initState — Timesheet Gate

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final mapState = ref.read(mapPresenterProvider);
    if (mapState.activeTimesheet == null) {
      showDialog(
        context: context,
        barrierDismissible: false,  // WAJIB: user harus isi form
        builder: (ctx) => const TimesheetStartDialog(),
      );
    }
  });
}
```

> **Aturan**: Selalu gunakan `addPostFrameCallback` agar dialog tidak muncul saat widget tree belum selesai di-build. `barrierDismissible: false` mencegah user menutup dialog tanpa mengisi data.

---

## 4. Camera Helper — `_toZoom`

```dart
void _toZoom(double zoom, double lon, double lat) async {
  if (_controller == null) return;
  _controller?.moveCamera(
    zoom: zoom,
    center: Geographic(lon: lon, lat: lat),
  );
}
```

Digunakan oleh tombol Zoom In (`zoom: 21.2`) dan Zoom Out (`zoom: 19.0`).

---

## 5. `build()` — Providers & Derived State

```dart
final mapState = ref.watch(mapPresenterProvider);
final authState = ref.watch(authProvider);
final isCrumblingMode = authState.mode.name.toUpperCase() == 'CRUMBLING';
final size = MediaQuery.of(context).size;
```

| Variable | Source | Deskripsi |
|----------|--------|-----------|
| `mapState` | `mapPresenterProvider` | State lengkap Map (GPS, spots, mode, dll) |
| `authState` | `authProvider` | Auth state termasuk mode sistem |
| `isCrumblingMode` | Derived | `true` jika mode adalah `'CRUMBLING'` (case-insensitive) |
| `size` | `MediaQuery` | Ukuran layar untuk perhitungan positioning |

---

## 6. `ref.listen` — Reactive Side Effects

`ref.listen` dipanggil di dalam `build()` untuk bereaksi terhadap perubahan state tanpa membangun ulang UI.

### A. GPS Location Update → Camera & Excavator

```dart
ref.listen(mapPresenterProvider, (previous, next) {
  if (next.currentLat != null && next.currentLng != null && _controller != null) {
    // Auto Center Logic
    if (next.isWorkMode || !_hasInitialCenter) {
      _controller?.moveCamera(
        center: Geographic(lon: next.currentLng!, lat: next.currentLat!),
        bearing: next.targetBearing ?? next.heading,
      );
      if (!_hasInitialCenter) _hasInitialCenter = true;
    }

    // Update Excavator Position on Map
    if (next.fullGps != null) {
      ref.read(mapPresenterProvider.notifier)
         .updateExcavatorPosition(_controller!, next.fullGps!);
    }
  }

  // B. Auto-reload Spots jika spotDone counter naik
  if (previous != null && next.spotDone > previous.spotDone && _controller != null) {
    ref.read(mapPresenterProvider.notifier).loadSpots(_controller!);
  }

  // C. Show Digging Notification
  if (previous != null && !previous.diggingStatus && next.diggingStatus) {
    ref.read(mapPresenterProvider.notifier).showDiggingNotification(context);
  }
});
```

### Auto-Center Rules

| Kondisi | Aksi |
|---------|------|
| `isWorkMode == true` | SELALU pindahkan kamera ke posisi excavator |
| `!_hasInitialCenter` | Hanya center SEKALI saat pertama kali GPS diterima (Standby mode) |
| Setelah center pertama | Set `_hasInitialCenter = true`, center tidak berulang di Standby mode |

**Camera bearing**: `next.targetBearing ?? next.heading` — gunakan target bearing jika ada, fallback ke heading GPS.

---

## 7. Widget Tree — Scaffold & Stack

```
Scaffold
└── body: Stack
    ├── [1] AbsorbPointer → MapLibreMap         ← BASE LAYER
    ├── [2] Positioned (top-left)  → Menu Button
    ├── [3] Positioned (right-bottom) → Zoom & Action Buttons (conditional: _showMenu)
    ├── [4] Positioned (right)     → GuidanceWidget (conditional: isWorkMode && !isCrumblingMode)
    ├── [5] Positioned (top-center) → CrumblingDeviationBar (conditional: isWorkMode && isCrumblingMode)
    ├── [6] Positioned (top-right) → Connection Status + Exit Button
    └── [7] Positioned (bottom)    → MapInfoPanel
```

---

## 8. Layer 1: MapLibreMap (Base Layer)

```dart
AbsorbPointer(
  absorbing: mapState.isWorkMode,  // Lock map gestures di Work Mode
  child: MapLibreMap(
    onMapCreated: (controller) {
      _controller = controller;
    },
    onStyleLoaded: (_) {
      if (_controller != null) {
        ref.read(mapPresenterProvider.notifier)
           .addExcavatorLayers(_controller!);
      }
    },
    options: const MapOptions(
      initCenter: Geographic(lon: 106.8456, lat: -6.2088),
      initZoom: _defaultZoom,   // 14.0
      initBearing: 0,
    ),
  ),
)
```

> **AbsorbPointer**: Saat `isWorkMode == true`, semua gesture (pan, pinch) pada peta diblokir agar excavator selalu terpusat.

---

## 9. Layer 2: Menu Button (Top-Left)

**Positioning**: `top: size.height * 0.05`, `left: size.width * 0.02`

```dart
Positioned(
  top: size.height * 0.05,
  left: size.width * 0.02,
  child: Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1E241E).withOpacity(0.9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.withOpacity(0.5)),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
    ),
    child: IconButton(
      onPressed: () => setState(() { _showMenu = !_showMenu; }),
      icon: const Icon(Icons.menu_rounded, color: Colors.greenAccent),
      tooltip: 'Menu',
    ),
  ),
)
```

---

## 10. Layer 3: Zoom & Action Menu (Conditional, Right-Bottom)

**Condition**: `if (_showMenu)`

**Positioning**: `right: size.width * 0.02`, `bottom: size.height * 0.12`

```dart
Positioned(
  right: size.width * 0.02,
  bottom: size.height * 0.12,
  child: Column(
    children: [
      // Zoom In → zoom: 21.2
      _buildFloatingButton(
        icon: Icons.zoom_in,
        onPressed: () => _toZoom(21.2, mapState.currentLng!, mapState.currentLat!),
      ),
      const SizedBox(height: 10),
      // Zoom Out → zoom: 19.0
      _buildFloatingButton(
        icon: Icons.zoom_out,
        onPressed: () => _toZoom(19.0, mapState.currentLng!, mapState.currentLat!),
      ),
      const SizedBox(height: 10),
      // Work Mode Toggle
      _buildFloatingButton(
        icon: mapState.isWorkMode ? Icons.stop : Icons.play_arrow,
        color: mapState.isWorkMode ? Colors.red : Colors.green,
        onPressed: () => ref.read(mapPresenterProvider.notifier)
                            .toggleWorkMode(_controller),
      ),
      const SizedBox(height: 10),
      // Settings (Delay Config)
      _buildFloatingButton(
        icon: Icons.settings,
        color: Colors.amber,
        onPressed: () {
          final currentDelay = ref.read(mapPresenterProvider).spotCompletionDelay;
          DialogUtils.showDelayConfigDialog(
            context: context,
            currentDelay: currentDelay,
            onSave: (val) => ref.read(mapPresenterProvider.notifier)
                                .setSpotCompletionDelay(val),
          );
        },
      ),
    ],
  ),
)
```

### Floating Button Colors

| Tombol | Icon | Color |
|--------|------|-------|
| Zoom In | `Icons.zoom_in` | `Colors.greenAccent` (default) |
| Zoom Out | `Icons.zoom_out` | `Colors.greenAccent` (default) |
| Work Mode (aktif) | `Icons.stop` | `Colors.red` |
| Work Mode (standby) | `Icons.play_arrow` | `Colors.green` |
| Settings | `Icons.settings` | `Colors.amber` |

---

## 11. Layer 4: GuidanceWidget (Conditional, Right)

**Condition**: `if (mapState.isWorkMode && !isCrumblingMode)`

**Positioning**: `right: size.width * 0.01`, `top: size.height * 0.09`

```dart
if (mapState.isWorkMode && !isCrumblingMode)
  Positioned(
    right: size.width * 0.01,
    top: size.height * 0.09,
    child: const GuidanceWidget(),
  ),
```

---

## 12. Layer 5: CrumblingDeviationBar (Conditional, Top-Center)

**Condition**: `if (mapState.isWorkMode && isCrumblingMode)`

```dart
if (mapState.isWorkMode && isCrumblingMode)
  Positioned(
    top: size.height * 0.05,
    left: 0,
    right: 0,
    child: Align(
      alignment: Alignment.topCenter,
      child: const CrumblingDeviationBar(),
    ),
  ),
```

---

## 13. Layer 6: Connection Status + Exit (Top-Right)

**Positioning**: `top: size.height * 0.05`, `right: size.width * 0.02`

```dart
Positioned(
  top: size.height * 0.05,
  right: size.width * 0.02,
  child: Row(
    children: [
      // --- Connection Status Box ---
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(        // Shared map overlay style
          color: const Color(0xFF1E241E).withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Conn: ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(width: 8),
            Icon(
              Icons.circle,
              color: mapState.usbConnected ? Colors.greenAccent : Colors.redAccent,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              mapState.usbConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: mapState.usbConnected ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      // --- Exit Button ---
      Container(
        decoration: BoxDecoration(        // Shared map overlay style
          color: const Color(0xFF1E241E).withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.red),
          tooltip: 'Exit Map',
          onPressed: () async { /* Exit logic below */ },
        ),
      ),
    ],
  ),
)
```

### Exit Button Logic

```dart
onPressed: () async {
  final mapState = ref.read(mapPresenterProvider);
  if (mapState.activeTimesheet != null) {
    // Timesheet aktif → wajib isi HM End sebelum exit
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,  // WAJIB isi form
      builder: (ctx) => const TimesheetEndDialog(),
    );
    if (shouldExit == true && context.mounted) {
      Navigator.of(context).pop();
    }
  } else {
    // Tidak ada timesheet → langsung exit
    if (context.mounted) Navigator.of(context).pop();
  }
}
```

---

## 14. Layer 7: MapInfoPanel (Bottom)

**Positioning**: `bottom: size.height * 0.02`, `left: size.width * 0.02`, `right: size.width * 0.02`

```dart
Positioned(
  bottom: size.height * 0.02,
  left: size.width * 0.02,
  right: size.width * 0.02,
  child: const MapInfoPanel(),
)
```

---

## 15. Helper Widget — `_buildFloatingButton`

```dart
Widget _buildFloatingButton({
  required IconData icon,
  required VoidCallback onPressed,
  Color? color,
}) {
  final bgColor = const Color(0xFF1E241E).withOpacity(0.9);
  final fgColor = color ?? Colors.greenAccent;
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.green.withOpacity(0.5)),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
    ),
    child: FloatingActionButton(
      mini: true,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 0,
      onPressed: onPressed,
      child: Icon(icon),
    ),
  );
}
```

---

## 16. Theme / Color System

Semua overlay menggunakan token warna yang sama:

| Token | Value | Penggunaan |
|-------|-------|------------|
| Overlay Background | `Color(0xFF1E241E).withOpacity(0.9)` | Background semua container overlay |
| Overlay Border | `Colors.green.withOpacity(0.5)` | Border semua container overlay |
| Overlay Shadow | `Colors.black26, blurRadius: 4` | BoxShadow semua container overlay |
| Border Radius (square) | `BorderRadius.circular(8)` | Menu, Status, Exit buttons |
| USB Connected Color | `Colors.greenAccent` | Indikator koneksi aktif |
| USB Disconnected Color | `Colors.redAccent` | Indikator koneksi putus |
| Work Mode Active | `Colors.red` | Warna toggle saat mode aktif |
| Work Mode Standby | `Colors.green` | Warna toggle saat mode standby |
| Settings Icon | `Colors.amber` | Ikon pengaturan delay |
| Default FAB FG | `Colors.greenAccent` | Warna foreground FAB default |

---

## 17. Overlay Position Formula Summary

| Layer | Top | Left | Right | Bottom |
|-------|-----|------|-------|--------|
| Menu Button | `h * 0.05` | `w * 0.02` | — | — |
| Zoom+Action Menu | — | — | `w * 0.02` | `h * 0.12` |
| GuidanceWidget | `h * 0.09` | — | `w * 0.01` | — |
| CrumblingDevBar | `h * 0.05` | `0` | `0` | — |
| Connection + Exit | `h * 0.05` | — | `w * 0.02` | — |
| MapInfoPanel | — | `w * 0.02` | `w * 0.02` | `h * 0.02` |

---

## 18. Dialog Flow Summary

| Trigger | Dialog | `barrierDismissible` | Return Value |
|---------|--------|----------------------|-------------|
| `initState` (no active timesheet) | `TimesheetStartDialog` | `false` | void |
| Exit button (active timesheet exists) | `TimesheetEndDialog` | `false` | `bool` (`true` = success, `false` = cancel) |
| Settings button | `DialogUtils.showDelayConfigDialog` | default | `double` (via callback) |

---

> [!IMPORTANT]
> Map bearing pada `moveCamera` hanya dikirimkan ketika sistem mendeteksi target spot baru (`isNewTargetSpot`) menggunakan `next.targetBearing` (arah bearing dari body excavator ke target spot). Pada pergerakan biasa atau saat tidak ada target baru, `bearing` bernilai `null` sehingga peta tidak berputar mengikuti arah hadap (`heading`) excavator. Ini memastikan orientasi peta stabil dan hanya berputar mengarah ke target kerja saat target berganti.

> [!NOTE]
> `_controller` adalah state lokal (tidak di Riverpod) karena `MapController` bukan objek serializable dan terikat erat dengan lifecycle widget. Presenter menerima controller sebagai parameter di setiap method yang membutuhkannya.
