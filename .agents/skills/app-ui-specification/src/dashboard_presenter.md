# Dashboard Presenter Blueprint
Path: `lib/features/dashboard/dashboard_presenter.dart`

`DashboardPresenter` bertanggung jawab atas seluruh logika bisnis Dashboard: mengelola filter aktif, mengquery data `WorkingSpot` dari Isar, menghitung semua KPI (Produktivitas, Presisi, Produksi, Jam Kerja, Area), dan membangun data tren untuk grafik.

---

## 1. Provider Definition

```dart
final dashboardPresenterProvider =
    AsyncNotifierProvider<DashboardPresenter, DashboardData>(() {
  return DashboardPresenter();
});
```

- **Type**: `AsyncNotifierProvider<DashboardPresenter, DashboardData>`
- **Alasan**: State-nya bersifat async (bergantung pada query Isar), sehingga UI dapat langsung menggunakan `.when(data:, loading:, error:)` tanpa tambahan StreamProvider. Provider ini bersifat **global** (tidak auto-dispose) karena filter harus dipertahankan saat pengguna navigasi.

---

## 2. State Model (`DashboardData`)

`DashboardData` adalah objek immutable (tidak menggunakan `copyWith`) yang dibuat ulang setiap kali `_loadDashboardData()` selesai dieksekusi.

| Field | Type | Default | Deskripsi |
|-------|------|---------|-----------|
| `productivity` | `double` | `0` | Produktivitas dalam Spot/Hr atau Ha/Hr |
| `productivitySpotsHr` | `double` | `0` | Nilai mentah produktivitas (cadangan) |
| `percentageProductivity` | `double` | `0` | Progres 0.0–1.0 (target: 250 spot/hr) |
| `precision` | `double` | `0` | Rata-rata akurasi GPS dalam cm |
| `percentagePrecision` | `double` | `0` | Progres 0.0–1.0 (max: 10 cm) |
| `productionSpots` | `double` | `0.0` | Total produksi (spot count atau m² untuk CRUMBLING) |
| `productionSpotsTotal` | `double` | `0.0` | Sama dengan `productionSpots` (field cadangan) |
| `percentageProduction` | `double` | `0` | Progres 0.0–1.0 (target: 5000) |
| `workHours` | `String` | `'00:00'` | Format `'HH:mm'` dari total jam kerja |
| `percentageWorkHours` | `double` | `0` | Progres 0.0–1.0 (target: 12 jam) |
| `workHoursInSeconds` | `double` | `0` | Nilai detik internal untuk kalkulasi |
| `productivityTrend` | `List<FlSpot>` | `[]` | Data points grafik (X: epoch ms, Y: Ha) |
| `productionTrend` | `List<FlSpot>` | `[]` | Data points grafik (X: epoch ms, Y: spot/m²) |
| `areaHa` | `double` | `0` | Total area aktual dalam Hektar |
| `maxAreaHa` | `double` | `1` | Target area workfile dalam Hektar |
| `percentageProgress` | `double` | `0` | Progres 0.0–1.0 (areaHa / maxAreaHa) |
| `spacing` | `String` | `'4.0 m x 1.87 m'` | Label jarak tanam workfile aktif |
| `productivityMaxY` | `double` | `1.0` | Batas Y grafik produktivitas (dinamis) |
| `productionMaxY` | `double` | `100.0` | Batas Y grafik produksi (dinamis) |
| `trendInterval` | `double` | `7200000` | Interval label sumbu X dalam ms |
| `workfiles` | `List<WorkFile>` | `[]` | Semua workfile untuk dropdown di header |

---

## 3. Filter Model (`DashboardFilter`)

```dart
enum DashboardFilterType { morning, night, weekly, monthly, custom }
```

`DashboardFilter` adalah objek immutable dengan `copyWith`, disimpan sebagai field internal `_filter` di presenter.

| Field | Type | Deskripsi |
|-------|------|-----------|
| `type` | `DashboardFilterType` | Tipe filter aktif |
| `selectedDate` | `DateTime` | Tanggal referensi (untuk morning/night/weekly/monthly) |
| `customRange` | `DateTimeRange?` | Range kustom (hanya untuk tipe `custom`) |
| `selectedFileID` | `String?` | UID workfile yang dipilih |

---

## 4. Lifecycle & Initialization (`build`)

```
build() async
├── await DatabaseService().init()       ← Pastikan DB siap
├── _isar = DatabaseService().isar       ← Ambil instance Isar
├── ref.watch(authProvider)              ← Re-build jika auth berubah
├── [Auto-detect shift berdasarkan jam saat ini]
│   if (now.hour >= 19 || now.hour < 7) → set filter ke NIGHT
└── [Auto-pilih workfile pertama jika belum ada selectedFileID]
    → _isar.workFiles.where().findAll()
    → _filter.copyWith(selectedFileID: workfiles.first.uid.toString())
    → return _loadDashboardData()
```

---

## 5. Business Logic

### A. Action Handlers (UI Commands)

| Method | Efek |
|--------|------|
| `updateFilterType(type)` | Short-circuit jika tipe sama. Update `_filter.type`, panggil `refresh()`. |
| `updateDate(date)` | Update `_filter.selectedDate`, panggil `refresh()`. |
| `updateCustomRange(range)` | Set tipe ke `custom`, update `_filter.customRange`, panggil `refresh()`. |
| `updateSelectedFileID(fileID)` | Update `_filter.selectedFileID`, panggil `refresh()`. |
| `refresh()` | Set state ke `AsyncValue.loading()`, lalu re-run `_loadDashboardData()` via `AsyncValue.guard`. |

### B. Time Range Resolution (`_loadDashboardData` — Bagian Awal)

Berdasarkan `_filter.type`, rentang waktu `startTime` dan `endTime` ditentukan:

| Filter | startTime | endTime |
|--------|-----------|---------|
| `morning` | `selectedDate 07:00:00` | `selectedDate 18:59:59` |
| `night` | `selectedDate 19:00:00` | `selectedDate+1 06:59:59` |
| `weekly` | `selectedDate - 6 hari (00:00:00)` | `selectedDate 23:59:59` |
| `monthly` | `1st day of selectedDate's month` | `last day of selectedDate's month 23:59:59` |
| `custom` | `customRange.start` | `customRange.end 23:59:59` |

### C. Data Query (Isar)

```dart
_isar.workingSpots
  .filter()
  .fileIDEqualTo(fileID)
  .driverIDEqualTo(driverID)       ← dari authProvider.currentUser.uid
  .statusEqualTo(1)                ← hanya spot yang valid
  .modeEqualTo(systemMode)         ← 'SPOT' atau 'CRUMBLING'
  .lastUpdateBetween(startEpoch, endEpoch)
  .sortByLastUpdate()
  .findAll()
```

> Jika `spots.isEmpty` → langsung return `DashboardData(workfiles: workfiles, spacing: currentSpacing)` sebagai state kosong.

### D. KPI Calculations

#### Work Hours
Iterasi pasangan spot berurutan. Gap waktu dianggap valid hanya jika `diff <= 300` detik (5 menit). Gap lebih besar diabaikan sebagai idle/break.

```dart
if (diff <= 300) workHoursSeconds += diff;
```

Format akhir: `"HH:mm"` dari `Duration(seconds: workHoursSeconds.toInt())`.

#### Production
| Mode | Rumus |
|------|-------|
| `SPOT` | `spots.length.toDouble()` |
| `CRUMBLING` | `totalDistance * wfPanjang` (di mana `totalDistance` = sum jarak antar spot dalam 1 `spotID`) |

Jarak dihitung via `CoordinateService().getDistance(Position(lng, lat), ...)`.

#### Productivity
```dart
productivity = (production / workHoursSeconds) * 3600
```
Hanya dihitung jika `workHoursSeconds > 0`.

#### Precision
```dart
precision = spots.isNotEmpty ? (sum of spot.akurasi) / spots.length : 0.0
```

#### Area (Ha)
| Mode | Rumus |
|------|-------|
| `SPOT` | `production * (wfPanjang * wfLebar) / 10000` |
| `CRUMBLING` | `production / 10000` (production sudah dalam m²) |

`maxAreaHa` diambil dari `activeWorkfile.luasArea ?? 5.0`.

#### Persentase KPI
| KPI | Target | Rumus |
|-----|--------|-------|
| Productivity | 250 spot/hr | `(productivity / 250).clamp(0.0, 1.0)` |
| Precision | 10 cm | `(precision / 10).clamp(0.0, 1.0)` |
| Production | 5000 | `(production / 5000).clamp(0.0, 1.0)` |
| Work Hours | 43200 detik (12 jam) | `(workHoursSeconds / 43200).clamp(0.0, 1.0)` |
| Progress | `maxAreaHa` | `(areaHa / maxAreaHa).clamp(0.0, 1.0)` |

---

## 6. Trend Calculation (`_calculateTrend<T>`)

Fungsi generik untuk membangun `List<FlSpot>` dari raw spots berdasarkan interval waktu.

**Signature**:
```dart
List<FlSpot> _calculateTrend<T>(
  List<WorkingSpot> spots, {
  required DateTime startTime,
  required int intervalMinutes,
  required double Function(List<WorkingSpot>) valueMapper,
})
```

**Logika**:
1. **Grouping**: Setiap spot dikelompokkan ke dalam `Map<int, List<WorkingSpot>>` berdasarkan:
   ```dart
   intervalIndex = (dt.difference(startTime).inMinutes) ~/ intervalMinutes
   ```
   Spot dengan `diffMin < 0` (sebelum `startTime`) diabaikan.
2. **Point Generation**: Iterasi dari index `0` hingga `maxIndex`. Jika suatu index tidak memiliki data, `valueMapper([])` akan mengembalikan `0`.
3. **X Value**: `startTime + (i * intervalMinutes)` dikonversi ke epoch ms via `.millisecondsSinceEpoch.toDouble()`.

**Interval otomatis**:
| Durasi periode | `intervalMinutes` | `chartInterval` (ms) |
|----------------|-------------------|----------------------|
| ≤ 24 jam | `30` | `7200000` (2 jam) |
| > 24 jam | `60 * 24` (1 hari) | `86400000` (1 hari) |

**Dynamic Max Y (dengan 20% padding)**:
```dart
final productivityMaxY = prodMax == 0 ? 1.0 : prodMax * 1.2;
final productionMaxY   = productionMax == 0 ? 10.0 : productionMax * 1.2;
```

---

## 7. Dependencies

| Import | Kegunaan |
|--------|---------|
| `dart:async` | — (tidak digunakan langsung, warisan import) |
| `dart:math` | `max()` untuk temukan index tertinggi |
| `flutter_riverpod` | `AsyncNotifier`, `ref.watch`, `ref.read` |
| `isar_community` | Query `WorkingSpot` dan `WorkFile` |
| `fl_chart` | Tipe data `FlSpot` untuk tren grafik |
| `database_service.dart` | Akses instance Isar |
| `working_spot.dart` | Model data produksi |
| `workfile.dart` | Model konfigurasi workfile |
| `auth_state.dart` | Ambil `driverID` dan `systemMode` |
| `coordinate_service.dart` | Kalkulasi jarak antar koordinat GPS |

---
> [!IMPORTANT]
> `DashboardPresenter` tidak menggunakan `StreamProvider`. Seluruh reaktivitas dikontrol melalui `refresh()` yang dipanggil secara manual setiap kali filter berubah. Pastikan setiap action handler selalu memanggil `refresh()`.

> [!NOTE]
> Field `productivitySpotsHr` saat ini di-hardcode ke `250.0` di dalam `_loadDashboardData`. Ini adalah nilai referensi target yang belum diambil dari konfigurasi workfile.
