# Dashboard Page Blueprint
Path: `lib/features/dashboard/dashboard_page.dart`

Halaman Dashboard adalah pusat visualisasi KPI (Key Performance Indicator) operasional. Halaman ini menampilkan progres area, produktivitas, presisi, produksi, jam kerja, dan tren historis berdasarkan filter shift/periode yang dipilih pengguna.

## 1. Page Architecture (Widget Tree)

```
Scaffold (backgroundColor: theme.pageBackground)
├── AppBar
│   ├── Title Row
│   │   ├── IconBox (Icons.dashboard, 40x40, theme.iconBoxBackground)
│   │   └── Column
│   │       ├── Text "EGS DASHBOARD" (bold, letterSpacing: 1.2, fontSize: 18)
│   │       └── Text "SYSTEM MODE: $systemMode" (fontSize: 10, theme.appBarAccent)
│   └── Actions: [GlobalAppBarActions(), SizedBox(width: 16)]
└── Body: Padding(all: 16)
    └── Column
        ├── DashboardHeader          ← Filter & workfile selector
        ├── SizedBox(height: 16)
        └── Expanded
            └── dashboardPresenterProvider.when(
                    data:    _buildDashboardContent(data, isCrumbling)
                    loading: CircularProgressIndicator(color: theme.loadingIndicatorColor)
                    error:   Text('Error: $err', color: Colors.red)
                )
```

### Widget Type
- `DashboardPage` → `ConsumerWidget`

### Key Derived State (from providers)
| Variable | Source | Purpose |
|----------|--------|---------|
| `dashboardDataAsync` | `ref.watch(dashboardPresenterProvider)` | Async state: loading/data/error |
| `auth` | `ref.watch(authProvider)` | Current user + system mode |
| `systemMode` | `auth.mode.name.toUpperCase()` | `'SPOT'` or `'CRUMBLING'` |
| `isCrumbling` | `systemMode == 'CRUMBLING'` | Controls unit labels & calculations |

---

## 2. Content Layout (`_buildDashboardContent`)

Fungsi private yang menerima `DashboardData data` dan `bool isCrumbling`. Dikembalikan dalam `.when(data: ...)`.

```
Column
├── Expanded(flex: 6)  ← Top Row (Cards)
│   └── Row(crossAxisAlignment: CrossAxisAlignment.stretch)
│       ├── Expanded(flex: 4)
│       │   └── ProgressCard         ← Primary KPI: Area Progress
│       ├── SizedBox(width: 16)
│       └── Expanded(flex: 7)
│           └── Column
│               ├── Expanded         ← Row 1 of Summary Cards
│               │   └── Row
│               │       ├── Expanded → SummaryCard (Productivity, Blue)
│               │       ├── SizedBox(width: 16)
│               │       └── Expanded → SummaryCard (Precision, Red)
│               ├── SizedBox(height: 16)
│               └── Expanded         ← Row 2 of Summary Cards
│                   └── Row
│                       ├── Expanded → SummaryCard (Production, Green)
│                       ├── SizedBox(width: 16)
│                       └── Expanded → SummaryCard (Work Hours, Purple)
├── SizedBox(height: 16)
└── Expanded(flex: 4)  ← Bottom Row (Charts)
    └── Row(crossAxisAlignment: CrossAxisAlignment.stretch)
        ├── Expanded → TrendChart (Productivity Trend, lineColor: Blue)
        ├── SizedBox(width: 16)
        └── Expanded → TrendChart (Production Trend, lineColor: Green)
```

---

## 3. Core Widgets

### A. DashboardHeader
**File**: `lib/features/dashboard/widgets/dashboard_header.dart`
**Type**: `ConsumerStatefulWidget`
**Role**: Mengelola kontrol filter dan pemilihan workfile aktif.

**Layout**:
```
Column
└── LayoutBuilder
    └── SingleChildScrollView (Axis.horizontal)
        └── ConstrainedBox (minWidth: constraints.maxWidth)
            └── Row (mainAxisAlignment: spaceBetween)
                ├── Row (Left: Filter tabs + date range)
                │   ├── Container (h:44, cardSurface, rounded: 12)
                │   │   └── Row → [_buildFilterChip x4]
                │   │       (Morning | Night | Weekly | Monthly)
                │   └── Container (h:44)
                │       └── IconButton (Icons.date_range) → showDateRangePicker
                └── Container (Right: Workfile Dropdown, h:44)
                    └── DropdownButton<String>
                        items: workfiles (dari DashboardData.workfiles)
                        icon: Icons.folder_open_outlined
```

**Filter Chip (`_buildFilterChip`)**:
```dart
GestureDetector(
  onTap: () => presenter.updateFilterType(type),
  child: AnimatedContainer(
    duration: Duration(milliseconds: 200),
    padding: EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: isSelected ? theme.appBarAccent : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label.toUpperCase(), ...)
  )
)
```
- Selected color: `theme.appBarAccent` (background), `theme.primaryButtonText` (text)
- Unselected color: `Colors.transparent` (background), `theme.textSecondary` (text)

**Workfile Dropdown**:
- Display name priority: `workfile.areaName` → fallback `workfile.uid.toString()` → `'Unknown'`
- `onChanged`: calls `presenter.updateSelectedFileID(newValue)`

---

### B. ProgressCard
**File**: `lib/features/dashboard/widgets/progress_card.dart`
**Type**: `StatelessWidget`
**Role**: Visualisasi progres area kerja (KPI utama).
**Package**: `percent_indicator` (`CircularPercentIndicator`)

**Props**:
| Prop | Type | Default | Deskripsi |
|------|------|---------|-----------|
| `areaHa` | `double` | `0` | Total area saat ini (Ha) |
| `maxAreaHa` | `double` | `5` | Target area workfile (Ha) |
| `percentage` | `double` | `0` | Progres 0.0–1.0 |
| `totalSpots` | `double` | `0.0` | Total produksi (spot/m²) |
| `spacing` | `String` | `'4.0 m x 1.87 m'` | Jarak tanam workfile |
| `productionUnit` | `String` | `'m²'` | Unit produksi (`'spot'` atau `'m²'`) |

**Layout**:
```
Container (padding: 20, cardBorderColor border, radius: 16)
└── Column (crossAxisAlignment: start)
    ├── Row
    │   ├── CircularPercentIndicator (radius: 45, lineWidth: 10)
    │   │   center: Column
    │   │       ├── Text "${(percentage*100).toStringAsFixed(1)}%"
    │   │       └── Text "/ ${maxAreaHa.toStringAsFixed(3)} ha" (textSecondary)
    │   │   progressColor: theme.appBarAccent
    │   │   backgroundColor: theme.cardSurface
    │   └── Column (crossAxisAlignment: start)
    │       ├── Text 'TOTAL AREA' (10, bold, letterSpacing 1.1, textSecondary)
    │       ├── Row
    │       │   ├── Text areaHa.toStringAsFixed(3) (36, w900, textOnSurface)
    │       │   └── Text 'Ha' (14, appBarAccent, bold)
    │       └── Row
    │           ├── Text totalSpots.toStringAsFixed(1) (14, bold, textOnSurface)
    │           └── Text productionUnit (10, textSecondary)
    ├── Spacer()
    ├── Divider (cardBorderColor)
    ├── SizedBox(height: 8)
    ├── Text 'WORKING PROGRESS' (14, bold, letterSpacing 1.1)
    ├── SizedBox(height: 8)
    ├── Row → [Text 'Spacing', Text spacing (bold)]
    ├── SizedBox(height: 4)
    └── Row → [Text 'Luas Area', Text '${maxAreaHa.toStringAsFixed(3)} Ha' (bold)]
```

---

### C. SummaryCard
**File**: `lib/features/dashboard/widgets/summary_card.dart`
**Type**: `StatelessWidget`
**Role**: Menampilkan satu metrik KPI dengan nilai, unit, dan indikator progres lingkaran.
**Package**: `percent_indicator` (`CircularPercentIndicator`)

**Props**:
| Prop | Type | Required | Deskripsi |
|------|------|----------|-----------|
| `title` | `String` | ✅ | Nama KPI (e.g. `'Productivity'`) |
| `value` | `String` | ✅ | Nilai utama yang ditampilkan |
| `subUnit` | `String` | ✅ | Satuan nilai (e.g. `'spots/hr'`, `'cm'`) |
| `subValue` | `String?` | ❌ | Nilai perbandingan/target opsional |
| `percent` | `double` | ✅ | Progres 0.0–1.0 |
| `progressColor` | `Color` | ✅ | Warna lingkaran — **semantik, tidak boleh diubah** |
| `isTrendUp` | `bool` | ❌ | Default `true` (belum digunakan aktif) |

**Instansiasi Semantik**:
| Instansi | `title` | `progressColor` | Nilai sumber |
|----------|---------|-----------------|--------------|
| Produktivitas | `'Productivity'` | `Color(0xFF3B82F6)` (Blue) | `data.productivity` |
| Presisi | `'Spots Precision'` / `'Line Precision'` | `Color(0xFFEF4444)` (Red) | `data.precision` |
| Produksi | `'Production'` | `Color(0xFF2ECC71)` (Green) | `data.productionSpots` |
| Jam Kerja | `'Work Hours'` | `Color(0xFFA855F7)` (Purple) | `data.workHours` |

**Layout**:
```
Container (padding: 16, cardBorderColor border, radius: 16)
└── Row (crossAxisAlignment: center)
    ├── Expanded
    │   └── Column (crossAxisAlignment: start, center)
    │       ├── [if subValue != null]
    │       │   Row → [Icon bar_chart (14, textSecondary), Text subValue (10, bold, textSecondary)]
    │       │   SizedBox(height: 8)
    │       ├── Text title.toUpperCase() (10, letterSpacing 1.1, textSecondary, bold)
    │       ├── SizedBox(height: 4)
    │       └── Row (crossAxisAlignment: baseline)
    │           ├── Text value (24, bold, textOnSurface)
    │           └── Text subUnit (12, appBarAccent, bold)
    └── CircularPercentIndicator (radius: 35, lineWidth: 8)
        center: Text "${(percent*100).toStringAsFixed(1)}%" (12, bold, textOnSurface)
        progressColor: progressColor
        backgroundColor: theme.cardSurface
```

---

### D. TrendChart
**File**: `lib/features/dashboard/widgets/trend_chart.dart`
**Type**: `StatelessWidget`
**Role**: Menampilkan grafik tren historis sebagai line chart.
**Package**: `fl_chart` (`LineChart`, `LineChartData`), `intl` (date formatting)

**Props**:
| Prop | Type | Default | Deskripsi |
|------|------|---------|-----------|
| `title` | `String` | required | Judul chart (e.g. `'Productivity Trend'`) |
| `unit` | `String` | required | Satuan Y-axis (`'Ha'` atau `'Spot'`/`'m²'`) |
| `spots` | `List<FlSpot>` | required | Data points — X = epoch ms, Y = nilai |
| `maxY` | `double` | required | Batas atas Y-axis (dinamis + 20% padding) |
| `lineColor` | `Color` | `0xFF2ECC71` | Warna garis — **semantik, tidak boleh diubah** |
| `interval` | `double` | `7200000` | Interval sumbu X dalam ms |

**Instansiasi Semantik**:
| Instansi | `title` | `lineColor` | Sumber data |
|----------|---------|-------------|-------------|
| Produktivitas | `'Productivity Trend'` | `Color(0xFF3B82F6)` (Blue) | `data.productivityTrend` |
| Produksi | `'Production Trend'` | `Color(0xFF2ECC71)` (Green) | `data.productionTrend` |

**Chart Configuration**:
```
Container (padding: 16, cardBorderColor border, radius: 16)
└── Column (crossAxisAlignment: start)
    ├── Row (spaceBetween)
    │   ├── Text '0.0 Ha' / '0 $unit' (10, bold, textSecondary)  ← min label
    │   └── Text title.toUpperCase() (12, bold, letterSpacing 1.1)
    ├── SizedBox(height: 16)
    ├── Expanded
    │   └── LineChart
    │       gridData:   Horizontal dashed lines (cardBorderColor)
    │       bottomTitles: getTitlesWidget
    │           if interval >= 86400000 → DateFormat('dd/MM').format(dt)
    │           else                    → DateFormat('HH:mm').format(dt)
    │       border:     Bottom only (cardBorderColor, width: 1)
    │       lineBarsData: LineChartBarData
    │           isCurved: true
    │           color: lineColor
    │           barWidth: 3
    │           belowBarData: lineColor.withValues(alpha: 0.1)
    └── Text '${maxY} Ha' / '${maxY} $unit' (10, bold, textSecondary)  ← max label
```

---

## 4. Theme Token Mapping

| Komponen | Token | Property |
|----------|-------|----------|
| Page Background | `theme.pageBackground` | `Scaffold.backgroundColor` |
| AppBar | `theme.appBarBackground` | `AppBar.backgroundColor` |
| AppBar Teks | `theme.appBarForeground` | `AppBar.foregroundColor` |
| Subtitle Mode | `theme.appBarAccent` | Text color |
| Loading Indicator | `theme.loadingIndicatorColor` | `CircularProgressIndicator.color` |
| Filter Chip (aktif) | `theme.appBarAccent` | Container background |
| Filter Chip (inaktif) | `Colors.transparent` | Container background |
| Filter Text (aktif) | `theme.primaryButtonText` | Text color |
| Filter Text (inaktif) | `theme.textSecondary` | Text color |
| Dropdown Container | `theme.cardSurface` | Container background |
| Dropdown Item Text | `theme.dropdownItemText` | DropdownMenuItem text |
| Card Border | `theme.cardBorderColor` | `Border.all` |
| Card Background | `theme.pageBackground` | Container background |
| Circular Indicator BG | `theme.cardSurface` | `backgroundColor` |
| Teks Utama | `theme.textOnSurface` | Text color |
| Teks Sekunder | `theme.textSecondary` | Text color |
| Unit Accent | `theme.appBarAccent` | Sub-unit text color |

### Semantic Color Overrides (Fixed — Tidak Boleh Diubah)
| Elemen | Warna | Kode |
|--------|-------|------|
| SummaryCard Productivity | Blue | `Color(0xFF3B82F6)` |
| SummaryCard Precision | Red | `Color(0xFFEF4444)` |
| SummaryCard Production | Green | `Color(0xFF2ECC71)` |
| SummaryCard Work Hours | Purple | `Color(0xFFA855F7)` |
| TrendChart Productivity | Blue | `Color(0xFF3B82F6)` |
| TrendChart Production | Green | `Color(0xFF2ECC71)` |

---

## 5. UI Generation Rules

- **Responsive Grid**: Gunakan rasio `flex: 4 (ProgressCard) : flex: 7 (SummaryCards)` untuk baris atas, dan `flex: 6 (Cards) : flex: 4 (Charts)` antar baris atas-bawah.
- **System Mode Guard**: Teks unit (`'spot'` vs `'m²'`) dan logika kalkulasi dikontrol oleh flag `isCrumbling`.
- **Scalability**: Nama widget dalam dokumen ini bersifat kanonik — gunakan persis nama yang sama jika mereplikasi fitur ini di proyek baru.
- **Semantic Colors**: `progressColor` pada `SummaryCard` dan `lineColor` pada `TrendChart` **tidak boleh** diganti dengan token tema. Warna ini bersifat visual semantik.

---
> [!TIP]
> Untuk membuat Dashboard baru, sediakan daftar KPI beserta sumber data-nya, lalu gunakan struktur widget dan tabel mapping tema di atas sebagai landasan implementasi.

> [!IMPORTANT]
> Detail unit KPI bersifat mode-conditional. Selalu periksa flag `isCrumbling` sebelum menentukan label unit dan logika kalkulasi produksi/produktivitas.
