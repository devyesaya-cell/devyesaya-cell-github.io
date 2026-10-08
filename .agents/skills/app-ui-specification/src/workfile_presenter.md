# Workfile Presenter Blueprint
Path: `lib/features/workfile/workfile_presenter.dart`

The `WorkfilePresenter` (MVVM Pattern) handles all cross-repository coordination, spatial data parsing, and coordinate-to-area calculations.

## 1. Provider Definition
- **Type**: `NotifierProvider.autoDispose<WorkfilePresenter, WorkfileState>`.
- **Reasoning**: Automatically clears memory when navigating away from the creation form.

## 2. State Model Detail (`WorkfileState`)
| Property | Type | Purpose |
|----------|------|---------|
| `areas` | `List<Area>` | Available job sites |
| `contractors` | `List<Contractor>` | Available legal entities |
| `selectedArea` | `Area?` | User's job site choice |
| `selectedMode` | `SystemMode` | SPOT, CRUMBLING, or MAINT |
| `parsedSpots` | `List<WorkingSpot>` | Points ingested from GeoJSON |
| `computedArea` | `double?` | Calculated Hectares (Ha) |

## 3. Business Logic (Core Functions)

### A. Data Initialization (`loadData`)
- Fetches all `Area` and `Contractor` records via `appRepositoryProvider`.
- Updates the state once async loading completes.

### B. GeoJSON Processing (`pickFile`)
1. Calls `GeoJsonService.pickGeoJsonFile()`.
2. Passes path to `GeoJsonService.parseGeoJson()`.
3. Stores parsed points in `parsedSpots`.
4. Triggers `_calculateArea()`.

### C. Area Calculation (`_calculateArea`)
This is the core mathematical engine. Area is computed based on the `selectedMode` and `selectedSpacing` (e.g., "4x1.87").

#### Formula for SPOT Mode:
`Area (Ha) = (Total Spots * (Panjang * Lebar)) / 10000`
- **Example**: `(100 spots * (4m * 1.87m)) / 10000 = 0.0748 Ha`.

#### Formula for CRUMBLING Mode:
1. Group `parsedSpots` by `spotID` (Lines).
2. Calculate cumulative **Haversine Distance** for each line.
3. `Area (Ha) = (Total Distance * Lebar) / 10000`.
- **Haversine Implementation**:
  ```dart
  const p = 0.017453292519943295;
  final a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742000 * asin(sqrt(a)); // returns meters
  ```

### D. Persistence Workflow (`saveWorkfile`)
1. **Prepare UID**: `DateTime.now().millisecondsSinceEpoch`.
2. **Step 1**: Save all `WorkingSpot` objects (linkage via `fileID`).
3. **Step 2**: Save `WorkFile` metadata (Area ID, Contractor Name, Equipment Mode, Spacing, Computed Area).
4. **Step 3**: Mark status as 'Open'.

## 4. State Management Rules
- **Immutability**: Always use `.copyWith()` to update state.
- **Side Effects**: Never perform database transactions in UI. All Isar calls must originate here.
- **Cleanup**: The `autoDispose` provider ensures state reset.

---
> [!TIP]  
> Use `ref.read(appRepositoryProvider)` to interact with the database. Ensure the `GeoJsonService` is also provided via a Riverpod provider for testability.
