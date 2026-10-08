# Timesheet Data Tab — Blueprint

**File**: `lib/features/setup/widgets/management/timesheet_data_tab.dart`  
**Widget Class**: `TimesheetDataTab` (extends `ConsumerWidget`)

_Displays all timesheet activity templates in a responsive grid. Cards are rendered inline (not via a separate card widget file). Uses an external `TimesheetDataEditDialog` for add/edit._

---

## Imports Required

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/app_repository.dart';
import '../../../../core/models/timesheet_data.dart';
import '../../../../core/utils/app_theme.dart';
import 'timesheet_data_edit_dialog.dart';          // External dialog widget
```

---

## Key Differences from Other Tabs

> [!IMPORTANT]
> This tab has three unique characteristics:
> 1. **No separate card widget file** — cards are built inline via `_buildCard()` method.
> 2. **Edit dialog is external** (`TimesheetDataEditDialog` in `timesheet_data_edit_dialog.dart`), not inline.
> 3. **Loading indicator is green** (`CircularProgressIndicator(color: Color(0xFF2ECC71))`) — other tabs use the default theme color.

---

## Data Flow

```dart
final stream = ref.watch(appRepositoryProvider).watchTimesheetDatas();
```

---

## Layout

```
StreamBuilder:
├── loading → Center(CircularProgressIndicator(color: Color(0xFF2ECC71)))
└── data    → LayoutBuilder → Column
    ├── Padding(all: 16) → Row(end) → ElevatedButton.icon [ADD TIMESHEET DATA]
    ├── if empty → Expanded(Center( Builder → Text('No Timesheet Data found.', theme.textSecondary)))
    └── else → Expanded(GridView.builder, target height: 170)
                └── _buildCard(context, ref, item)
```

---

## Responsive Grid

```dart
int crossAxisCount = 2;
if (width > 700)  crossAxisCount = 3;
if (width > 1000) crossAxisCount = 4;
if (width > 1400) crossAxisCount = 5;

// Target card height: 170 (shortest of all tabs)
double childAspectRatio = itemWidth / 170;

GridView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
)
```

---

## `_buildCard` — Inline Card Widget

Cards are built directly inside the tab, not in a separate file.

```dart
Widget _buildCard(BuildContext context, WidgetRef ref, TimesheetData data) {
  final theme = AppTheme.of(context);

  // Icon resolution from string field
  IconData displayIcon = Icons.build;               // default
  if (data.icon == 'local_gas_station') displayIcon = Icons.local_gas_station;
  if (data.icon == 'precision_manufacturing') displayIcon = Icons.precision_manufacturing;
  ...
```

### Card Structure

```dart
Card(
  color: theme.cardSurface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: theme.cardBorderColor),
  ),
  elevation: 4,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── HEADER: Icon Box + Name/Type ──
      Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.pageBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.cardBorderColor),
          ),
          child: Icon(displayIcon, color: theme.iconBoxIcon, size: 32),
        ),
        SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.activityName ?? 'Unknown',
              style: TextStyle(color: theme.textOnSurface, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 4),
          Text(data.activityType ?? 'Unknown Type',
              style: TextStyle(color: theme.appBarAccent, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
        ])),
      ]),

      const Spacer(),        // ← Spacer pushes divider+actions to bottom

      Divider(color: theme.dividerColor),

      // ── ACTIONS: Edit + Delete ──
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        IconButton(
          Icons.edit_outlined,
          color: Colors.blueAccent,  // Semantic blue — hardcoded
          tooltip: 'Edit',
          onPressed: () => _showEditDialog(context, data),
        ),
        IconButton(
          Icons.delete_outline,
          color: Color(0xFFEF4444),  // Semantic red — hardcoded
          tooltip: 'Delete',
          onPressed: () => _confirmDelete(context, ref, data),
        ),
      ]),
    ]),
  ),
)
```

### Icon Name → `IconData` Mapping

| `data.icon` string          | Resolved `IconData`              |
|-----------------------------|----------------------------------|
| _(anything else / default)_ | `Icons.build`                    |
| `'local_gas_station'`       | `Icons.local_gas_station`        |
| `'precision_manufacturing'` | `Icons.precision_manufacturing`  |

---

## Add/Edit Dialog

Uses an external dialog imported from `timesheet_data_edit_dialog.dart`:

```dart
void _showEditDialog(BuildContext context, TimesheetData? data) {
  showDialog(
    context: context,
    builder: (context) => TimesheetDataEditDialog(timesheetData: data),
  );
}
```

| `timesheetData` value | Dialog Mode |
|-----------------------|-------------|
| `null`                | Add mode    |
| `TimesheetData` object| Edit mode   |

---

## Delete Confirmation Dialog

```dart
AlertDialog(
  backgroundColor: theme.dialogBackground,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: theme.cardBorderColor),
  ),
  title: Text('Delete Timesheet Data', style: TextStyle(color: theme.textOnSurface)),
  content: Text(
    'Are you sure you want to delete "${data.activityName}"?',
    style: TextStyle(color: theme.textSecondary),
  ),
  actions: [
    TextButton('Cancel', style: TextStyle(color: theme.textSecondary)),
    ElevatedButton('(delete)',
      backgroundColor: Color(0xFFEF4444),
    ),
  ],
)
```

**On confirm:** `ref.read(appRepositoryProvider).deleteTimesheetData(data.id)`

> [!NOTE]
> The `showDialog` in `_confirmDelete` uses `ctx` (the dialog's own context from `builder: (ctx)`) for `Navigator.pop(ctx)`, not the outer `context`. This is the standard safe pattern.

---

## Theme Token Usage Summary

| Element                    | Token                             |
|----------------------------|-----------------------------------|
| Card background            | `theme.cardSurface`               |
| Card border                | `theme.cardBorderColor`           |
| Icon box background        | `theme.pageBackground`            |
| Icon box border            | `theme.cardBorderColor`           |
| Icon color                 | `theme.iconBoxIcon`               |
| Activity name text         | `theme.textOnSurface`             |
| Activity type text         | `theme.appBarAccent`              |
| Divider                    | `theme.dividerColor`              |
| Edit icon                  | `Colors.blueAccent` _(hardcoded)_ |
| Delete icon                | `Color(0xFFEF4444)` _(hardcoded)_ |
| Loading indicator          | `Color(0xFF2ECC71)` _(hardcoded)_ |
| ADD button background      | `Color(0xFF2ECC71)` _(hardcoded)_ |
| ADD button text            | `Colors.black` _(hardcoded)_      |
| Empty state text           | `theme.textSecondary`             |
| Dialog background          | `theme.dialogBackground`          |
| Dialog title               | `theme.textOnSurface`             |
| Dialog content             | `theme.textSecondary`             |
| Cancel text                | `theme.textSecondary`             |
| Delete button              | `Color(0xFFEF4444)` _(hardcoded)_ |
