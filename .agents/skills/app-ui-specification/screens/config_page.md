# Screen Specification: Pengaturan & Manajemen Data (ConfigPage)

> **File Target**: `lib/features/config/config_page.dart`  
> **Widget Type**: `ConsumerStatefulWidget`  
> **Presenter/State**: `configProvider`, `datasetProvider`, `globalSummaryProvider`  
> **Primary Mode**: SHARED (Dual Mode: SPOT & CRUMBLING)  

---

## 1. Purpose

Laman konfigurasi parameter target galian, toleransi QC 4-Kuadran crumbling, manajemen database lokal (Hive / IndexedDB), serta inspeksi tabel rincian hasil galian / segmen crumbling dengan fitur multi-kriteria filter canggih.

- **Primary User Goal**: Operator, QC Inspector, dan Site Supervisor dapat menyesuaikan parameter target dan toleransi, mengunggah GeoJSON baru, serta memfilter dan meninjau data titik/segmen galian berdasarkan tanggal (single & range), rentang lebar parit, rentang kedalaman, dan kata kunci pencarian.
- **Workflow Context**: Diakses dari SideMenu nav item "Konfigurasi (Config)".
- **Operational Mode**: SHARED (Mendukung parameter mode SPOT dan mode CRUMBLING).

---

## 2. Layout & Regions Table

### Visual Architecture (Widget Tree)
```
SingleChildScrollView (padding: 24)
└── Column
    ├── Header Row (Icon + Title 'PENGATURAN & MANAJEMEN DATA' + Subtitle)
    ├── LayoutBuilder (Two-column grid if width > 850, else Column)
    │   ├── Parameter Crumbling & Kedalaman (QC) Card
    │   └── Manajemen Database Lokal Card
    └── Data Table Preview Card (_buildDataTableCard)
        ├── Card Header (Icon + Title + Filtered Count Badge)
        ├── SCADA Filter Toolbar (_buildFilterToolbar)
        │   ├── Filter Buttons Wrap:
        │   │   ├── Search TextField
        │   │   ├── Date Filter OutlinedButton (Single Date & Range)
        │   │   ├── Lebar Filter OutlinedButton (Range Slider & Presets)
        │   │   ├── Kedalaman Filter OutlinedButton (Range Slider & Presets)
        │   │   └── Reset Filter OutlinedButton (conditional)
        │   └── Active Filter Badges Wrap (Dismissible chips + Clear All button)
        ├── Horizontal DataTable ScrollView
        └── Pagination Controls (Menampilkan X - Y dari Z, Prev/Next)
```

### Regions Breakdown
| Region ID | Area / Flex | Primary Contents | Responsive Behavior |
|-----------|-------------|------------------|---------------------|
| `header` | Fixed | Icon + Title + Subtitle | Auto width |
| `params_grid` | 50% / 50% or 100% | QC Crumbling parameters & Local DB management | Stacked on mobile/tablet (< 850px) |
| `filter_toolbar` | Full Card Width | Search input, Date/Lebar/Depth buttons, active filter chips | Wrap responsive flex with 10px spacing |
| `data_table` | Horizontal Scroll | Data columns based on mode (Crumbling vs Spot) | Scrollable horizontally |
| `pagination` | Full Card Width | Total records summary, page indicator, prev/next arrows | Space between row |

---

## 3. Menu Structure & Navigation

- **Route Name**: Embedded inside `HomeShell` tab index 2 (`Konfigurasi (Config)`).
- **Navigation Type**: Bottom / Side Navigation.
- **Side Menu Association**: `SideMenu` item `Konfigurasi (Config)` active.
- **Back Navigation**: In-shell persistent state.

---

## 4. Components Used

- `StatusBadge` (`lib/core/widgets/status_badge.dart`)
- `AppColors` (Cyan, Blue, Orange, Green, Amber, Surface elevated, Surface card)
- `_RangeFilterDialog` (Interactive visual RangeSlider + numeric Min/Max inputs + quick presets)
- Native Flutter `showDatePicker` & `showDateRangePicker` with dark Industrial SCADA theme.

---

## 5. Buttons & Clickable Elements

| Element Label | Component Type | Hitbox | Handler | Action Dispatched | Disabled Condition |
|---|---|---|---|---|---|
| `Simpan Pengaturan` | `ElevatedButton.icon` | $\ge 44$ px | `_saveSettings()` | Updates `configProvider` & persists | Form validation fails |
| `Unggah GeoJSON Baru` | `ElevatedButton.icon` | $\ge 44$ px | `_pickAndUploadGeoJson()` | File picker + parse GeoJSON | None |
| `Muat Contoh Crumbling` | `OutlinedButton.icon` | $\ge 44$ px | `loadSampleCrumblingGeoJson()` | Loads sample asset | In progress |
| `Muat Contoh Spot` | `OutlinedButton.icon` | $\ge 44$ px | `loadSampleGeoJson()` | Loads sample asset | In progress |
| `Kosongkan DB` | `OutlinedButton.icon` | $\ge 44$ px | `_confirmClearDatabase()` | Displays confirmation modal | In progress |
| `Filter Tanggal` | `OutlinedButton.icon` | $\ge 40$ px | `_showDateFilterDialog()` | Opens date choice modal (single/range/quick) | None |
| `Filter Lebar` | `OutlinedButton.icon` | $\ge 40$ px | `_showWidthFilterDialog()` | Opens RangeSlider modal with presets | None |
| `Filter Kedalaman` | `OutlinedButton.icon` | $\ge 40$ px | `_showDepthFilterDialog()` | Opens RangeSlider modal with presets | None |
| `Reset Filter` / `Hapus Semua` | `OutlinedButton` / `TextButton` | $\ge 36$ px | `_resetAllFilters()` | Clears all filters and resets page to 0 | No active filters |
| Dismiss Filter Chip `(x)` | `InkWell` | $\ge 24\times24$ px | `setState(...)` | Removes individual filter criterion | Filter not active |

---

## 6. Data Display & Calculations

- **Date Filtering**:
  - Evaluates `s.completedAt ?? s.timestamp ?? s.createdAt`.
  - Supports calendar day equality for Single Date.
  - Supports calendar range inclusion for Date Range.
- **Lebar (Width) Filtering**:
  - Evaluates `s.trenchWidthCm ?? rawProperties['trench_width_cm'] ?? rawProperties['width']`.
  - Supports `w >= min && w <= max` with automatic units (`cm`).
- **Depth (Kedalaman) Filtering**:
  - Evaluates `s.avgDepthCm ?? s.depth` (in `cm` for Crumbling, `m` for Spot).
  - Supports `d >= min && d <= max`.
- **Active Filter Badges**:
  - Cyan badge for Date.
  - Blue badge for Lebar (`Color(0xFF3B82F6)`).
  - Amber badge for Kedalaman (`Color(0xFFF59E0B)`).

---

## 7. Screen States

- `normal`: Displays parameter cards and filtered records table.
- `filtered_empty`: Displays empty state card with `Reset Semua Filter` button when filter matches zero items.
- `database_empty`: Displays empty state card prompt to upload or load sample.

---

## 8. Events & Side Effects

- Filter updates reset table page: `_currentPage = 0`.
- Preset selection in range dialog updates slider and numeric textfields simultaneously.
- Configuration change dispatches SnackBar confirmation.

---

## 9. Accessibility & Ergonomics

- All filter buttons have explicit hitboxes $\ge 40$ px height.
- Dismiss `(x)` touch target has padding and `BorderRadius.circular(10)`.
- High contrast color palette: Cyan (`#00E5FF`), Blue (`#3B82F6`), Amber (`#F59E0B`) on dark background (`#162030`).
- Multi-modal redundancy: Icons paired with descriptive labels on all filter chips and buttons.

---

## 10. Test Cases

- `test/config_filter_test.dart`:
  - `ConfigPage displays filter buttons for Date, Lebar, and Depth`: Verifies buttons render in toolbar.
  - `ConfigPage opening Date Filter Dialog shows options and quick dates`: Verifies single date, date range, and quick date chips.
  - `ConfigPage Lebar filter dialog and preset works correctly`: Verifies width filtering and presets (`Overwidth > 110 cm`).
  - `ConfigPage Depth filter dialog and preset works correctly`: Verifies depth filtering and presets (`Ideal QC 63 - 77 cm`).
- Full test suite passes: `flutter test` (15 passing tests).

---

## 11. Open Questions & Assumptions

- Width in crumbling mode is stored in centimeters (`trenchWidthCm`), while legacy spot mode parameters can use meters if defined in rawProperties.
