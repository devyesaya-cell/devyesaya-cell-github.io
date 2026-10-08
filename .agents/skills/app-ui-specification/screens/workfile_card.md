# Workfile Card Blueprint
Path: `lib/features/workfile/widgets/workfile_card.dart`

The `WorkfileCard` is the main entry point for selecting a job. It provides a visual summary of progress and configuration metadata.

## 1. Widget Structure
```
Card
└── InkWell
    └── Padding (16.0)
        └── Column
            ├── Row (Area Name + Status Badge)
            ├── Detail Row (Contractor)
            ├── Detail Row (Spacing)
            ├── Detail Row (Area Ha)
            ├── Spacer
            └── Progress Section
```

## 2. Layout & Styling Detailing

### Card Styling
- **Background**: `theme.cardSurface`.
- **Elevation**: 0.
- **Shape**: `RoundedRectangleBorder`.
  - `borderRadius`: `BorderRadius.circular(16)`.
  - `side`: `BorderSide(color: theme.cardBorderColor, width: 1.5)`.

### Header Section
- **Area Name**: `fontSize: 16`, `fontWeight: bold`, `color: theme.textOnSurface`.
- **Status Badge**:
  - `padding`: `EdgeInsets.symmetric(horizontal: 8, vertical: 4)`.
  - `decoration`: `BoxDecoration` with 15% opacity background and 30% opacity border of `statusColor`.
  - **Status Colors**:
    - `Done`: `0xFF2ECC71` (Green)
    - `Open`: `0xFF3B82F6` (Blue)

### Detail Row Configuration
- **Padding**: `SizedBox(height: 8)` between rows.
- **Icon**: Size 14, Color: `theme.textSecondary`.
- **Label**: `fontSize: 12`, Color: `theme.textSecondary`.
- **Value**: `fontSize: 12`, `fontWeight: w500`, Color: `theme.textOnSurface`.

### Progress Section
- **Label**: 'PROGRESS' (UPPERCASE), `fontSize: 10`, `fontWeight: bold`, `color: theme.textSecondary`.
- **Progress Ring/Bar**:
  - `LinearProgressIndicator`
  - `minHeight`: 6.
  - `backgroundColor`: `theme.pageBackground` (for contrast).
  - `valueColor`: Semantic Green (`0xFF2ECC71`).

## 3. Theme Token Mapping

| Component | Token | Property |
|-----------|-------|----------|
| Card Surface | `theme.cardSurface` | `color` |
| Card Border | `theme.cardBorderColor` | `borderColor` |
| Primary Text | `theme.textOnSurface` | `color` |
| Secondary Text | `theme.textSecondary` | `color` |
| Progress Track | `theme.pageBackground` | `backgroundColor` |

## 4. Logical Interaction
- **Input**: Requires a `WorkFile` object.
- **Calculation**: Computes `done / total` progress on build.
- **Interaction**: Trigger `onTap` callback passed from parent page.

---
> [!IMPORTANT]
> The card MUST maintain a fixed `childAspectRatio: 1.1` within the parent `GridView` to prevent horizontal text overflow on the Area Name or Progress labels.
