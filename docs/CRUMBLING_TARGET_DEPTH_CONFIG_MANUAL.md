# Manual & Blueprint: Dynamic Target Depth Config pada Mode Crumbling

Dokumentasi ini menjelaskan arsitektur, parameter, logika kalkulasi, panduan operasional, dan integritas kode untuk fitur **Dynamic Target Depth** pada **Mode Crumbling** di sistem Toho EGS.

---

## 1. Latar Belakang & Analisa Urgensi

### 1.1 Masalah Operasional Sebelumnya
Pada versi terdahulu, Mode Crumbling memiliki batasan parameter kedalaman (*dig depth*) yang bersifat kaku (*hardcoded*):
1. **Target Indikator Vertikal Guidance**: Nilai kedalaman target pada bar vertikal selalu terkunci di `1.0m` (100 cm). Jika proyek lapangan membutuhkan galian dengan kedalaman berbeda (misal 60 cm, 80 cm, atau 120 cm), visualisasi skala bar tidak representatif.
2. **Validasi Data Collection / Active Digging**: Sistem sebelumnya menetapkan syarat kedalaman minimum `60 cm` secara statis untuk mencatat galian aktif. Hal ini menyebabkan proyek dengan target dangkal (misal 60 cm atau 70 cm) sering kali gagal mencatat data jika operator menggali di kedalaman 50 cm.
3. **Pewarnaan Segmen (QC Line Coloring)**: Toleransi warna hijau (Ideal Pass) terkunci di `90 - 110 cm` ($\pm 10\%$ dari 100 cm). Akibatnya, pada target galian yang bukan 100 cm, segmen galian selalu berwarna kuning atau merah meskipun operator telah menggali tepat di kedalaman target proyek.

### 1.2 Dampak Solusi
Dengan implementasi fitur ini:
- Target kedalaman galian dapat dipilih secara fleksibel (60cm, 70cm, 80cm, 90cm, 100cm, 110cm, 120cm, maupun nilai Custom) melalui dialog **Map Config**.
- Seluruh subsistem (skala visual bar termometer, batas perekaman data galian $50\%$, dan batas toleransi warna hijau $\pm 10\%$) beradaptasi secara dinamis terhadap nilai target yang dipilih.

---

## 2. Solusi Teknis & Cakupan Data

### 2.1 Model Data & Persistensi Isar (`MapConfig`)
Field baru ditambahkan ke dalam skema `@collection` Isar [`MapConfig`](file:///c:/apps/toho_EGS/lib/core/models/map_config.dart):
```dart
double targetDepth = 100.0; // Dalam satuan cm (default 100.0 cm / 1.0 m)
```

| Field | Tipe | Default | Deskripsi |
|---|---|---|---|
| `targetDepth` | `double` | `100.0` | Target kedalaman galian proyek pada mode crumbling dalam centimeter (cm). |

Serialisasi dan deserialisasi database backup pada [`DatabaseBackupPresenter`](file:///c:/apps/toho_EGS/lib/features/setup/presenter/database_backup_presenter.dart) turut diselaraskan.

---

### 2.2 Aturan Ambang Batas Koleksi Data ($50\%$)
Dalam [`MapPresenter`](file:///c:/apps/toho_EGS/lib/features/map/presenter/map_presenter.dart):
$$\text{minDepthCm} = (\text{targetDepth} \times 0.50).\text{round}()$$

- **Status Penggalian Aktif (`isCurrentlyDigging`)**:
  ```dart
  final minDepthCm = (state.targetDepth * 0.50).round();
  final bool isDepthValid = actualDeep >= minDepthCm && actualDeep <= 300;
  isCurrentlyDigging = isBucketInSeg && isDepthValid;
  ```
- **Kualifikasi Progres Segmen (`hasMeaningfulProgress`)**:
  Segmen memenuhi syarat untuk difinalisasi jika kedalaman terdalam yang terekam memenuhi:
  $$\text{\_activeSegmentMaxDeep} \ge \text{minDepthCm}$$

---

### 2.3 Aturan Pewarnaan Segmen Galian ($\pm 10\%$)
Dalam [`WorkingSpotCalculationService.getCompletedSegmentColor`](file:///c:/apps/toho_EGS/lib/features/map/services/working_spot_calculation_service.dart):
$$\text{minAllowedDeep} = \text{targetDepthCm} \times 0.90$$
$$\text{maxAllowedDeep} = \text{targetDepthCm} \times 1.10$$

$$\text{isDeepPass} = \text{actualDeep} \ge \text{minAllowedDeep} \land \text{actualDeep} \le \text{maxAllowedDeep}$$
$$\text{isWidthPass} = \text{actualWidth} \le 110.0\text{ cm}$$

#### Matriks Evaluasi Warna 4-Kuadran:
| Status Kedalaman ($\pm 10\%$) | Status Lebar Parit ($\le 110\text{ cm}$) | Warna Segmen | Kode HEX | Makna |
|:---:|:---:|:---:|:---:|---|
| ✅ **Lolos** | ✅ **Lolos** | 🟢 **Hijau** | `#2ECC71` | Ideal (Kedalaman dan lebar sesuai standar) |
| ✅ **Lolos** | ❌ **Gagal** | 🔵 **Biru** | `#3B82F6` | Kedalaman lolos, namun parit terlalu lebar |
| ❌ **Gagal** | ✅ **Lolos** | 🟡 **Kuning** | `#F59E0B` | Lebar parit lolos, namun kedalaman di luar $\pm 10\%$ target |
| ❌ **Gagal** | ❌ **Gagal** | 🔴 **Merah** | `#EF4444` | Kedalaman dan lebar keduanya di luar standar toleransi |

---

### 2.4 Dinamika UI Progress Bar Kedalaman (`CrumblingDeviationBar`)
Pada [`CrumblingDeviationBar`](file:///c:/apps/toho_EGS/lib/features/map/widgets/crumbling_deviation_bar.dart):
- **Span Atas (Di Atas Tanah)**: $+0.5\text{ m}$
- **Span Bawah (Target Galian)**: $T = \text{targetDepth} / 100.0\text{ m}$
- **Total Span**: $0.5 + T$
- **Rasio Garis Tanah $0.0\text{m}$**: $\frac{0.5}{0.5 + T}$
- **Posisi Level Terkini**: $\text{fraction} = \frac{\text{clampedDepth} + 0.5}{0.5 + T}$
- **Indikator Warna Indikator Level**: Hijau (`#2ECC71`) jika $0.90 \times T \le \text{digDepth} \le 1.10 \times T$, selain itu merah (`Colors.redAccent`).
- **Label Bawah**: Menampilkan format nilai target terkini (contoh: `'0.8m'`, `'1.0m'`, `'1.2m'`).

---

## 3. Panduan Operasional & SOP Penggunaan

### 3.1 Mengubah Target Kedalaman Galian
1. Masuk ke halaman **Map** pada Mode Crumbling.
2. Ketuk ikon roda gigi ⚙️ (**Map Config**) di panel samping kanan.
3. Gulir ke bawah menuju parameter **Target Kedalaman Galian**.
4. Buka dropdown dan pilih opsi yang sesuai:
   - `60 cm (0.6 m)`
   - `70 cm (0.7 m)`
   - `80 cm (0.8 m)`
   - `90 cm (0.9 m)`
   - `100 cm (1.0 m) (Default)`
   - `110 cm (1.1 m)`
   - `120 cm (1.2 m)`
   - `Custom...` (Ketikkan angka dalam cm pada textfield yang muncul, misal `85`).
5. Ketuk tombol **Save**.
6. Konfigurasi langsung tersimpan ke database lokal Isar dan bar visual langsung ter-render ulang secara instan.

---

## 4. Arsitektur & Integritas Kode

### 4.1 File yang Dimodifikasi & Ditambahkan
1. [`lib/core/models/map_config.dart`](file:///c:/apps/toho_EGS/lib/core/models/map_config.dart) - Model entitas Isar untuk `targetDepth`.
2. [`lib/core/models/map_config.g.dart`](file:///c:/apps/toho_EGS/lib/core/models/map_config.g.dart) - Generated schema Isar.
3. [`lib/features/setup/presenter/database_backup_presenter.dart`](file:///c:/apps/toho_EGS/lib/features/setup/presenter/database_backup_presenter.dart) - Backup/restore serializer.
4. [`lib/features/map/presenter/map_presenter.dart`](file:///c:/apps/toho_EGS/lib/features/map/presenter/map_presenter.dart) - State management, validasi data collection 50%, dan setter target depth.
5. [`lib/features/map/services/working_spot_calculation_service.dart`](file:///c:/apps/toho_EGS/lib/features/map/services/working_spot_calculation_service.dart) - Algoritma kalkulasi toleransi warna segmen $\pm 10\%$.
6. [`lib/features/map/widgets/crumbling_deviation_bar.dart`](file:///c:/apps/toho_EGS/lib/features/map/widgets/crumbling_deviation_bar.dart) - Widget visualisasi bar kedalaman adaptif.
7. [`lib/core/utils/dialog_utils.dart`](file:///c:/apps/toho_EGS/lib/core/utils/dialog_utils.dart) - Dialog UI pilihan target galian.
8. [`lib/features/map/pages/map_page.dart`](file:///c:/apps/toho_EGS/lib/features/map/pages/map_page.dart) - UI handler integrasi Map Config.
9. [`test/map_config_persistence_test.dart`](file:///c:/apps/toho_EGS/test/map_config_persistence_test.dart) - Unit test persistensi config.
10. [`test/dig_depth_and_test_panel_test.dart`](file:///c:/apps/toho_EGS/test/dig_depth_and_test_panel_test.dart) - Widget & QC unit tests.

### 4.2 Isolasi Mode (Spot Mode vs Crumbling Mode)
Sesuai **Rule 5 (Mode Isolation Rule)**:
- Logika Mode SPOT (`GuidanceWidget`, hitungan auto done spot, radius spot) tetap terisolasi $100\%$ dan tidak terpengaruh oleh perubahan pada Mode Crumbling ini.

### 4.3 Peningkatan Stabilitas Transaksi Isar & Atomisitas State (v4.2.20)
- **Atomic Config Update**: Seluruh parameter Map Config kini diupdate sekaligus melalui `MapPresenter.updateFullMapConfig()`, mencegah *concurrent write transaction errors* pada Isar DB.
- **Isar ID Preservation**: `_persistMapConfig()` mempertahankan ID rekaman eksisting untuk mencegah konflik *unique index constraint*.
- **Dropdown & Value Safety**: Proteksi nilai `targetDepth <= 0` dengan *fallback default* $100.0\text{ cm}$ serta penanganan aman dropdown assertion pada `DialogUtils`.
