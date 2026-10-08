# Map Presenter Blueprint
Path: `lib/features/map/map_presenter.dart`

`MapPresenter` adalah Riverpod `Notifier` yang mengelola seluruh logika bisnis halaman Map: GPS stream processing, spot targeting, Crumbling mode deviation, excavator visualization di peta, dan sesi timesheet.

---

## 1. Provider Definition

```dart
final mapPresenterProvider = NotifierProvider<MapPresenter, MapState>(
  MapPresenter.new,
);
```

- **Type**: `NotifierProvider<MapPresenter, MapState>` (synchronous, bukan `AsyncNotifierProvider`)
- **Alasan**: State awal (`MapState()`) dapat dibuat secara synchronous. Operasi async (GPS, Isar) terjadi via stream subscription dan method calls.

---

## 2. State Model — `MapState`

`MapState` adalah objek immutable dengan `copyWith`. Semua field memiliki nilai default.

### 2.1 GPS & Sensor Fields

| Field | Type | Default | Deskripsi |
|-------|------|---------|-----------|
| `currentLat` | `double?` | `null` | Latitude posisi bucket (excavator center) |
| `currentLng` | `double?` | `null` | Longitude posisi bucket |
| `heading` | `double?` | `null` | Heading GPS dalam derajat (0–360) |
| `satellites` | `int` | `0` | Jumlah satelit GPS 1 |
| `baseSatellites` | `int` | `0` | Jumlah satelit GPS 2 / Base |
| `radioStatus` | `String` | `"Waiting..."` | Status radio/GPS string dari hardware |
| `rtkStatus` | `String` | `"NO RTK"` | Status RTK yang sudah dihitung: `"RTK"`, `"FLOAT"`, `"NO RTK"` |
| `batteryVoltage` | `double` | `0.0` | Tegangan baterai dari base station |
| `boomTilt` | `double` | `0` | Tilt boom dari GPSLoc |
| `stickTilt` | `double` | `0` | Tilt stick dari GPSLoc |
| `attachTilt` | `double` | `0` | Tilt attachment dari GPSLoc |
| `armLength` | `double` | `0.0` | Panjang arm dihitung 3D dari boom ke attachment |
| `armBearing` | `double` | `0.0` | Bearing dari excavator center ke attachment |
| `fullGps` | `GPSLoc?` | `null` | Objek GPS lengkap untuk dialog detail |
| `fullBase` | `Basestatus?` | `null` | Objek base station untuk dialog detail |

### 2.2 Connection Fields

| Field | Type | Default | Deskripsi |
|-------|------|---------|-----------|
| `usbConnected` | `bool` | `false` | Status koneksi USB (true jika connected & data diterima < 3 detik lalu) |
| `lastDataTime` | `DateTime?` | `null` | Timestamp terakhir data diterima dari hardware |
| `lastError` | `ErrorAlert?` | `null` | Error terakhir dari hardware |

### 2.3 Track Heading Fields

| Field | Type | Default | Deskripsi |
|-------|------|---------|-----------|
| `trackHeading` | `double` | `0.0` | Heading pergerakan (diupdate setiap gerakan > 2m) |
| `lastTrackLat` | `double?` | `null` | Latitude posisi terakhir saat trackHeading diupdate |
| `lastTrackLng` | `double?` | `null` | Longitude posisi terakhir saat trackHeading diupdate |

### 2.4 Work Mode & Spot Fields

| Field | Type | Default | Deskripsi |
|-------|------|---------|-----------|
| `isWorkMode` | `bool` | `false` | Toggle Work Mode (aktif = kamera terkunci + guidance muncul) |
| `totalSpot` | `int` | `0` | Total spot dalam workfile yang aktif |
| `spotDone` | `int` | `0` | Jumlah spot yang sudah selesai (status == 1) |
| `targetSpot` | `WorkingSpot?` | `null` | Spot terdekat yang sedang dijadikan target (Spot mode) |
| `devX` | `double?` | `null` | Deviasi kiri-kanan dari bucket ke target (meter, + = kanan) |
| `devY` | `double?` | `null` | Deviasi maju-mundur dari bucket ke target (meter, + = maju) |
| `targetBearing` | `double?` | `null` | Bearing dari excavator center ke target spot (untuk camera) |

### 2.5 Crumbling Mode Fields

| Field | Type | Default | Deskripsi |
|-------|------|---------|-----------|
| `targetSegment` | `List<WorkingSpot>?` | `null` | 2 spots yang membentuk target segment saat ini |
| `crumblingDeviation` | `double?` | `null` | Deviasi bucket ke target segment dalam cm (+ = kanan) |
| `crumblingDevSum` | `double` | `0.0` | Akumulasi deviasi untuk perhitungan rata-rata per segment |
| `crumblingDevCount` | `int` | `0` | Counter update deviasi untuk rata-rata per segment |

### 2.6 Query Optimization & Misc Fields

| Field | Type | Default | Deskripsi |
|-------|------|---------|-----------|
| `lastQueriedExcaLat` | `double?` | `null` | Latitude posisi terakhir saat nearby spots di-query |
| `lastQueriedExcaLng` | `double?` | `null` | Longitude posisi terakhir saat nearby spots di-query |
| `diggingStatus` | `bool` | `false` | Status gali dari USB (dari `comServiceProvider`) |
| `spotCompletionDelay` | `double` | `2.0` | Delay (detik) sebelum spot dianggap selesai setelah bucket dalam jarak < 10cm |
| `activeTimesheet` | `TimesheetRecord?` | `null` | Record timesheet yang sedang berjalan |

---

## 3. Internal Presenter Fields

```dart
class MapPresenter extends Notifier<MapState> {
  StreamSubscription<GPSLoc>? _gpsSub;     // Subscription GPS stream
  Timer? _paramTimer;                       // Timer 1 detik untuk cek koneksi
  Timer? _mockSpotTimer;                    // Mock timer (disabled)
  Timer? _timesheetTimer;                   // Timer 5 menit untuk auto-save timesheet
  List<WorkingSpot> _loadedSpots = [];      // In-memory cache semua spot workfile
  List<WorkingSpot> _cachedNearbySpots = []; // Cache spot dalam radius proximity
  DateTime? _spotInRangeSince;              // Timestamp kapan bucket pertama kali dalam range spot
  final _calc = CoordinateService();        // Instance helper koordinat
}
```

---

## 4. Lifecycle — `build()`

```dart
@override
MapState build() {
  _subscribe();   // Mulai GPS stream + provider listeners

  // Timer 1 detik: cek apakah data masih fresh (< 3 detik)
  _paramTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkConnection());

  ref.onDispose(() {
    _gpsSub?.cancel();
    _paramTimer?.cancel();
    _mockSpotTimer?.cancel();
    _timesheetTimer?.cancel();
  });

  return MapState();  // State awal dengan semua default values
}
```

---

## 5. Connection Check — `_checkConnection`

```
_checkConnection()
├── Baca comServiceProvider → comState
├── Hitung isReceivingData: lastDataTime != null && diff < 3 detik
├── isConnected = comState.isConnected && isReceivingData
└── Jika state.usbConnected != isConnected → update state
```

---

## 6. GPS Stream Processing — `_subscribe()`

### 6.1 Arm Calculation

```dart
// Hitung 3D arm length dari boom ke attachment
final dist = _calculate3DDistance(
  gps.boomLat, gps.boomLng, gps.boomAlt,
  gps.attachLat, gps.attachLng, gps.attachAlt,
);
final bearing = _calc.getBearing(
  Position(gps.bucketLong, gps.bucketLat),    // Exca center
  Position(gps.attachLng, gps.attachLat),       // Attachment
);
```

### 6.2 RTK Status Calculation

| Kondisi | rtkStatus |
|---------|-----------|
| `gps.status == 'NO RTK'` OR `gps.status2 == 'NO RTK'` | `"NO RTK"` |
| `gps.hAcc1 < 25` AND `gps.hAcc2 < 25` | `"RTK"` |
| Else | `"FLOAT"` |

**Notifikasi perubahan RTK**:
- `NO RTK` → `NotificationService.showError('RTK Signal Lost!')`
- `RTK` → `NotificationService.showSuccess('RTK Fixed')`
- `FLOAT` → `NotificationService.showWarning('RTK Float Mode')`

### 6.3 Track Heading Logic

```
Jika lastTrackLat/Lng == null:
  → trackHeading = gps.heading
  → lastTrackLat/Lng = gps.bucketLat/Long (initialize)
Else:
  → dist = _calc.getDistance(lastPos, currentPos)
  → Jika dist > 2.0 meter:
      trackHeading = _calc.getBearing(lastPos, currentPos)
      lastTrackLat/Lng = gps.bucketLat/Long
```

### 6.4 Work Mode Branching

Jika `state.isWorkMode == true`, logika berbeda berdasarkan `systemMode`:

```dart
final auth = ref.read(authProvider);
final systemMode = auth.mode.name.toUpperCase();
if (systemMode == 'CRUMBLING') {
  // → Crumbling Logic (section 7)
} else {
  // → Spot Logic (section 8)
}
```

### 6.5 State Update Akhir GPS

```dart
state = state.copyWith(
  currentLat: gps.bucketLat,
  currentLng: gps.bucketLong,
  heading: gps.heading,
  satellites: gps.satelit,
  radioStatus: gps.status,
  rtkStatus: newRtkStatus,
  boomTilt: gps.boomTilt,
  stickTilt: gps.stickTilt,
  attachTilt: gps.attachTilt,
  baseSatellites: gps.satelit2,
  armLength: dist,
  armBearing: bearing,
  fullGps: gps,
  lastDataTime: DateTime.now(),
  trackHeading: newTrackHeading,
  lastTrackLat: newLastTrackLat,
  lastTrackLng: newLastTrackLng,
  targetSpot: newTargetSpot,
  devX: newDevX,
  devY: newDevY,
  targetBearing: newTargetBearing,
);
```

### 6.6 Provider Listeners dalam `_subscribe()`

```dart
// USB Digging Status
ref.listen<UsbState>(comServiceProvider, (previous, next) {
  if (next.diggingStatus != state.diggingStatus) {
    state = state.copyWith(diggingStatus: next.diggingStatus);
  }
});

// Base Station Data
ref.listen<Basestatus?>(bsProvider, (previous, next) {
  if (next != null) {
    state = state.copyWith(
      batteryVoltage: next.batteryVoltage,
      fullBase: next,
      lastDataTime: DateTime.now(),
    );
  }
});

// Error Alerts
ref.listen<List<ErrorAlert>>(errorProvider, (previous, next) {
  if (next.isNotEmpty) {
    final latest = next.first;
    if (state.lastError != latest) {
      NotificationService.showError('Error: ${latest.message}');
      state = state.copyWith(lastError: latest);
    }
  }
});
```

---

## 7. Crumbling Mode Logic

### 7.1 Proximity Query (Update radius: 10m)

```
Jika lastQueriedExcaLat/Lng == null ATAU jarak dari lastQueried > 10m:
  → shouldQueryNearby = true
  → _cachedNearbySpots = _loadedSpots.where(spot =>
        spot.status == 0 &&
        _calc.getDistance(excaPos, spotPos) <= 20.0
    )
  → update lastQueriedExcaLat/Lng = gps.bucketLat/Long
```

### 7.2 Line Grouping & Target Line

```
1. Group _cachedNearbySpots by spot.spotID → Map<int, List<WorkingSpot>>
2. Untuk setiap line:
   - Hitung min distance dari excaPos ke semua segment line
   - Jika line hanya 1 titik: gunakan direct distance
3. Pilih line dengan minDistToLine terkecil → targetLine
```

### 7.3 Target Segment

```
Dari targetLine, iterasi semua segment (pair consecutive spots):
  dist = _calc.distanceToSegment(excaPos, startPos, endPos)
  Pilih segment dengan dist terkecil → newTargetSegment

Batasan: jika closestSegmentDist > 3.0 → newTargetSegment = null
```

### 7.4 Crumbling Deviation Calculation

```dart
// Jika targetSegment ditemukan:
final midX = (seg[0].lng! + seg[1].lng!) / 2;
final midY = (seg[0].lat! + seg[1].lat!) / 2;
final bearingToSegment = _calc.getBearing(bucketPos, Position(midX, midY));
final distToSegment = _calc.distanceToSegment(bucketPos, segStart, segEnd);
final thetaRad = (bearingToSegment - gps.heading) * (math.pi / 180.0);
newCrumblingDev = (distToSegment * math.sin(thetaRad)) * 100;  // → cm
```

### 7.5 Segment Transition & Auto-Complete

```
Jika targetSegment berubah (id berbeda dari sebelumnya):
  1. avgDev = crumblingDevSum / crumblingDevCount
  2. Untuk kedua node dari prevSegment:
     - Jika status != 1: update status=1, lastUpdate=now, akurasi=avgDev
     - Simpan ke Isar
     - Hapus dari _loadedSpots
     - exactlyNewlyDoneCount++
  3. state.spotDone += exactlyNewlyDoneCount
  4. Reset: nextSum = newCrumblingDev?.abs() ?? 0.0, nextCount = 1 (atau 0)
```

---

## 8. Spot Mode Logic

### 8.1 Proximity Query (Update radius: 3m)

```
Jika lastQueriedExcaLat/Lng == null ATAU jarak dari lastQueried > 3m:
  → _cachedNearbySpots = _loadedSpots.where(spot =>
        spot.status == 0 &&
        _calc.getDistance(excaPos, spotPos) <= 7.5m
    )
  → update lastQueriedExcaLat/Lng
```

### 8.2 Closest Spot to Bucket (radius: 0.5m)

```
Dari _cachedNearbySpots, cari spot terdekat ke bucketPos:
  Jika distToBucket <= 0.5m → newTargetSpot
```

### 8.3 DevX / DevY Calculation

```dart
// Jika targetSpot ditemukan:
final bearing = _calc.getBearing(bucketPos, targetPos);
final dist = _calc.getDistance(bucketPos, targetPos);
final thetaRad = (bearing - gps.heading) * (math.pi / 180.0);
newDevY = dist * math.cos(thetaRad);  // Forward/Backward
newDevX = dist * math.sin(thetaRad);  // Left/Right
newTargetBearing = _calc.getBearing(excaPos, targetPos);
```

### 8.4 Auto-Complete Spot Logic

```
Jika dist > 0.1m → _spotInRangeSince = null (reset)
Jika dist <= 0.1m:
  Jika _spotInRangeSince == null → set _spotInRangeSince = DateTime.now()
  Else:
    elapsed = DateTime.now().difference(_spotInRangeSince).inMs / 1000.0
    Jika elapsed >= state.spotCompletionDelay:
      shouldComplete = true

Jika shouldComplete:
  → spotToSave.lastUpdate = now (epoch detik)
  → spotToSave.lat = gps.attachLat   ← posisi actual bucket
  → spotToSave.lng = gps.attachLng
  → spotToSave.status = 1
  → spotToSave.akurasi = dist * 100  ← dalam cm
  → spotToSave.deep = random(60–80)
  → spotToSave.alt  = random(60–80)
  → Isar.writeTxn: save spotToSave
  → _loadedSpots.removeWhere(s => s.id == spotToSave.id)
  → _cachedNearbySpots.removeWhere(s => s.id == spotToSave.id)
  → state.spotDone += 1
  → Reset: newTargetSpot=null, newDevX/Y=null, newTargetBearing=null
  → state.diggingStatus = false
  → comServiceProvider.notifier.resetDiggingStatus()
  → _spotInRangeSince = null
  → NotificationService.showSuccess('Spot Completed!')
```

---

## 9. Timesheet Logic

### 9.1 `startTimesheet(TimesheetRecord newRecord)`

```dart
Future<void> startTimesheet(TimesheetRecord newRecord) async {
  // 1. Simpan record ke Isar
  await isar.writeTxn(() async { await isar.timesheetRecords.put(newRecord); });

  // 2. Update state
  state = state.copyWith(activeTimesheet: newRecord);

  // 3. Mulai auto-save timer (setiap 5 menit)
  _timesheetTimer?.cancel();
  _timesheetTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
    final currentTs = state.activeTimesheet;
    final currentWf = ref.read(authProvider).activeWorkfile;
    if (currentTs != null && currentWf != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      currentTs.endTime = now;
      currentTs.totalTime = now - currentTs.startTime;
      currentTs.totalSpots = state.spotDone.toDouble();

      // Workspeed: Ha/jam
      if (currentTs.totalTime > 0) {
        final hours = currentTs.totalTime / 3600.0;
        final spotsPerHour = currentTs.totalSpots / hours;
        currentTs.workspeed = (spotsPerHour * (wf.panjang ?? 0.0) * (wf.lebar ?? 0.0)) / 10000.0;
      }

      await isar.writeTxn(() async { await isar.timesheetRecords.put(currentTs); });
      state = state.copyWith(activeTimesheet: currentTs);
    }
  });
}
```

### 9.2 `stopTimesheet({required int hmEnd})`

```dart
Future<void> stopTimesheet({required int hmEnd}) async {
  _timesheetTimer?.cancel(); _timesheetTimer = null;

  final currentTs = state.activeTimesheet;
  final currentWf = ref.read(authProvider).activeWorkfile;

  if (currentTs != null && currentWf != null) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    currentTs.endTime = now;
    currentTs.hmEnd = hmEnd;
    currentTs.totalTime = now - currentTs.startTime;
    currentTs.totalSpots = state.spotDone.toDouble();

    // Hitung workspeed jika ada waktu kerja
    if (currentTs.totalTime > 0) {
      final hours = currentTs.totalTime / 3600.0;
      currentTs.workspeed = ((currentTs.totalSpots / hours)
          * (currentWf.panjang ?? 0.0) * (currentWf.lebar ?? 0.0)) / 10000.0;
    }

    // Update workfile progress
    currentWf.spotDone = state.spotDone;
    currentWf.lastUpdate = now;
    currentWf.status = 'on progress';

    // Transaction: simpan timesheet + workfile
    await isar.writeTxn(() async {
      await isar.timesheetRecords.put(currentTs);
      await isar.workFiles.put(currentWf);
    });

    state = state.copyWith(activeTimesheet: null);
  }
}
```

---

## 10. Work Mode Toggle

```dart
void toggleWorkMode(maplibre.MapController? controller) {
  final newMode = !state.isWorkMode;
  state = state.copyWith(isWorkMode: newMode);
  if (!newMode) _stopMocking();  // Bersihkan mock timer jika kembali ke standby
}

void setSpotCompletionDelay(double seconds) {
  state = state.copyWith(spotCompletionDelay: seconds);
}
```

---

## 11. Map Visualization — `addExcavatorLayers`

Dipanggil SEKALI saat `onStyleLoaded`. Membuat semua GeoJSON sources dan layers:

### GeoJSON Sources & Layers yang Dibuat

| Source ID | Layer ID | Layer Type | Filter | Deskripsi |
|-----------|----------|------------|--------|-----------|
| `spots_source` | `spots_layer` | CircleStyleLayer | `$type == Point` | Spot points (merah/hijau) |
| `spots_source` | `crumbling_line_layer` | LineStyleLayer | `$type == LineString` | Segment lines (Crumbling mode) |
| `exca_body_source` | `exca_body_layer` | FillStyleLayer | `type == body` | Body/chassis excavator (`#FBAF00`) |
| `exca_body_source` | `exca_tracks_layer` | FillStyleLayer | `type == track` | Track excavator (`#000000`) |
| `excavator_source` | `base_layer` | FillStyleLayer | `part == base` | Base cockpit (`#E78A00`) |
| `excavator_source` | `cockpit_layer` | FillStyleLayer | `part == cockpit` | Cockpit (`#808080`) |
| `excavator_source` | `arm_layer` | FillStyleLayer | `part == arm` | Arm (`#808080`) |
| `attach_source` | `attach_layer` | FillStyleLayer | — | Attachment/bucket (`#E78A00`) |
| `guidance_line_source` | `guidance_line_layer` | LineStyleLayer | — | Garis biru putus-putus ke target (`#0000FF`, width: 4, dasharray: [2,2]) |

### Spot Color Logic (MapLibre Expression)

```json
'circle-color': ['match', ['get', 'status'],
  1, '#00FF00',  // Done → Green
  0, '#FF0000',  // Todo → Red
  '#808080'      // Default → Grey
]
```

> Setelah sources & layers dibuat, langsung panggil `loadSpots(controller)` untuk load data awal.

---

## 12. Excavator Position Update — `updateExcavatorPosition`

```dart
Future<void> updateExcavatorPosition(MapController controller, GPSLoc gps) async {
  await _updateBody(controller, gps);       // Tracks + chassis
  await _updateCockpit(controller, gps);    // Base + cockpit + arm
  await _updateAttachment(controller, gps); // Bucket circle
  await _updateGuidanceLine(controller, gps); // Line to target
}
```

### 12.1 `_updateBody` — Dimensi Excavator

| Konstanta | Nilai | Deskripsi |
|-----------|-------|-----------|
| `BODY_WIDTH` | `1.7` m | Lebar badan |
| `BODY_LENGTH` | `3.0` m | Panjang badan |
| `TRACK_WIDTH` | `0.8` m | Lebar satu track |
| `TRACK_LENGTH` | `4.0` m | Panjang satu track |

**Center**: `Position(gps.bucketLong, gps.bucketLat)`
**Heading**: `state.trackHeading` (bukan `gps.heading` langsung)

Menghasilkan 3 Polygon features dalam `exca_body_source`:
1. Body (`type: "body"`) — `frontLeft, frontRight, backRight, backLeft`
2. Left Track (`type: "track"`) — outer edge = `BODY_WIDTH/2 + TRACK_WIDTH`
3. Right Track (`type: "track"`) — inner edge = `BODY_WIDTH/2`

### 12.2 `_updateCockpit` — Upper Structure

| Konstanta | Nilai | Deskripsi |
|-----------|-------|-----------|
| `BASE_SIZE` | `2.6` m | Ukuran base cockpit |
| `COCKPIT_LENGTH` | `2.0` m | Panjang cockpit |
| `ARM_WIDTH` | `0.3` m | Lebar arm connector |

**Center**: `Position(gps.bucketLong, gps.bucketLat)`
**Heading arm**: Dihitung dari `_calc.getBearing(center, armPos)` (bukan trackHeading)

Menghasilkan 3 Polygon features dalam `excavator_source`:
1. `part: "base"` — Kotak BASE_SIZE × BASE_SIZE
2. `part: "cockpit"` — Setengah kiri dari base (kiri chassis)
3. `part: "arm"` — Connector dari base edge ke attachPos (persegi panjang tipis)

### 12.3 `_updateAttachment` — Bucket Circle

```
attachPos = Position(gps.attachLng, gps.attachLat)
ATTACH_RADIUS = 0.25m (50cm diameter)
polygonCoords = _calc.generateCirclePolygon(attachPos, ATTACH_RADIUS)
→ Update attach_source dengan polygon circle
```

### 12.4 `_updateGuidanceLine`

| Mode | Dari | Ke |
|------|------|----|
| SPOT | `gps.attachLng/Lat` (bucket) | `targetSpot.lng/lat` |
| CRUMBLING | `gps.bucketLong/Lat` (exca center) | Point terdekat di targetSegment |

Jika tidak ada target → clear `guidance_line_source` (empty FeatureCollection).

---

## 13. Load Spots — `loadSpots`

```
1. Baca authProvider → activeWorkfile, currentUser, systemMode
2. Jika null → return
3. Query Isar: workingSpots.filter()
   .driverIDEqualTo(driverID)
   .fileIDEqualTo(fileID)
   .modeEqualTo(systemMode)
   .findAll()
4. _loadedSpots = spots (update in-memory cache)
5. total = spots.length
6. done = spots.where(s => s.status == 1).length
7. state = state.copyWith(totalSpot: total, spotDone: done)
8. Build GeoJSON features:
   - SPOT mode → Point features per spot
   - CRUMBLING mode → LineString per segment (group by spotID, sort by id)
     Fallback: jika group hanya 1 spot → Point feature
9. Update spots_source dengan GeoJSON
```

**Error handling**: `NotificationService.showError('Failed to load spots')` jika exception.

---

## 14. Notification — `showDiggingNotification`

```dart
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

---

## 15. Helper: `_calculate3DDistance`

```dart
double _calculate3DDistance(lat1, lon1, alt1, lat2, lon2, alt2) {
  const p = 0.017453292519943295; // pi / 180
  final a = 0.5 - cos((lat2-lat1)*p)/2 + cos(lat1*p)*cos(lat2*p)*(1-cos((lon2-lon1)*p))/2;
  final dist2d = 12742000 * asin(sqrt(a));  // 2R * asin(sqrt(a))
  final heightDiff = (alt1 - alt2).abs();
  return sqrt(dist2d * dist2d + heightDiff * heightDiff);
}
```

---

## 16. Dependencies

| Import | Kegunaan |
|--------|---------|
| `dart:async` | `StreamSubscription`, `Timer` |
| `dart:convert` | `jsonEncode` untuk GeoJSON |
| `dart:math` as math | `sin`, `cos`, `sqrt`, `pi`, `Random` |
| `flutter_riverpod` | `Notifier`, `ref.watch`, `ref.read`, `ref.listen` |
| `maplibre/maplibre.dart` | `MapController`, `GeoJsonSource`, layer types, `Geographic` |
| `com_service.dart` | `comServiceProvider`, `GPSLoc` stream, `UsbState` |
| `base_status.dart` | `Basestatus`, `bsProvider` |
| `error_alert.dart` | `ErrorAlert`, `errorProvider` |
| `gps_loc.dart` | Model `GPSLoc` |
| `coordinate_service.dart` | `CoordinateService` (getBearing, getDistance, offsets) |
| `notification_service.dart` | `NotificationService` (showError/Success/Warning/Command) |
| `working_spot.dart` | Model `WorkingSpot` |
| `workfile.dart` | Model `WorkFile` |
| `timesheet_record.dart` | Model `TimesheetRecord` |
| `database_service.dart` | `DatabaseService().isar` |
| `auth_state.dart` | `authProvider` |

---

> [!IMPORTANT]
> `MapController` tidak disimpan di dalam state Riverpod. Controller selalu dipass sebagai parameter ke setiap method yang membutuhkannya (`loadSpots`, `updateExcavatorPosition`, `toggleWorkMode`). Controller bersifat nullable untuk menghindari crash sebelum map siap.

> [!IMPORTANT]
> `_loadedSpots` adalah in-memory cache dari Isar. Ketika spot selesai (auto-complete), spot dihapus dari `_loadedSpots` DAN dari `_cachedNearbySpots` untuk mencegah deteksi ganda pada GPS tick berikutnya.

> [!NOTE]
> Track Heading (`trackHeading`) digunakan untuk `_updateBody` — ini adalah heading pergerakan aktual (diperbarui setiap gerakan > 2m), bukan heading GPS instan. Ini menghasilkan visualisasi body track yang lebih stabil (tidak "gemetar") saat excavator diam.
