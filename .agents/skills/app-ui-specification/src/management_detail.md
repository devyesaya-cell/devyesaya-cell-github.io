# Management Page — Blueprint

**File**: `lib/features/setup/pages/management_page.dart`  
**Widget Class**: `ManagementPage` (extends `ConsumerWidget`)

_A tabbed CRUD management hub for all master data: Persons, Workfiles, Contractors, Equipment, Areas, and Timesheet activity templates._

---

## Imports Required

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/management/person_tab.dart';
import '../widgets/management/workfile_tab.dart';
import '../widgets/management/contractor_tab.dart';
import '../widgets/management/equipment_tab.dart';
import '../widgets/management/area_tab.dart';
import '../widgets/management/timesheet_data_tab.dart';
import '../../../core/utils/app_theme.dart';
```

---

## AppBar Variant: Simple Title (No Icon Box)

> [!IMPORTANT]
> The Management page uses a **simplified AppBar** — only a plain `Text` title. It does **NOT** use the full Icon Box + Column pattern (that belongs to pages like Calibration). There are also **no right-side actions** (`GlobalAppBarActions` is absent).

```dart
appBar: AppBar(
  title: Text(
    'MANAGEMENT',
    style: TextStyle(
      color: theme.appBarForeground,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  ),
  backgroundColor: theme.appBarBackground,
  foregroundColor: theme.appBarForeground,
  elevation: 0,
  bottom: TabBar( ... ), // see below
)
```

---

## TabBar Configuration

```dart
bottom: TabBar(
  isScrollable: true,
  indicatorColor: theme.appBarAccent,
  labelColor: theme.appBarAccent,
  unselectedLabelColor: theme.textSecondary,
  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
  tabs: const [
    Tab(text: 'PERSON',     icon: Icon(Icons.person)),
    Tab(text: 'WORKFILE',   icon: Icon(Icons.folder)),
    Tab(text: 'CONTRACTOR', icon: Icon(Icons.business)),
    Tab(text: 'EQUIPMENT',  icon: Icon(Icons.handyman)),
    Tab(text: 'AREA',       icon: Icon(Icons.map)),
    Tab(text: 'TIMESHEET',  icon: Icon(Icons.timer)),
  ],
)
```

> [!NOTE]
> Management tabs use the `icon:` parameter inside `Tab()` to display an icon above the label. This is different from the Calibration page where tabs are text-only.

---

## Tab Order & Widget Mapping

| Index | Tab Label    | Icon                        | Widget Class        |
|-------|--------------|-----------------------------|---------------------|
| 0     | PERSON       | `Icons.person`              | `PersonTab()`       |
| 1     | WORKFILE     | `Icons.folder`              | `WorkfileTab()`     |
| 2     | CONTRACTOR   | `Icons.business`            | `ContractorTab()`   |
| 3     | EQUIPMENT    | `Icons.handyman`            | `EquipmentTab()`    |
| 4     | AREA         | `Icons.map`                 | `AreaTab()`         |
| 5     | TIMESHEET    | `Icons.timer`               | `TimesheetDataTab()`|

---

## Full Page Structure

```dart
class ManagementPage extends ConsumerWidget {
  const ManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: theme.pageBackground,
        appBar: AppBar(
          title: Text('MANAGEMENT', style: TextStyle(...)),
          backgroundColor: theme.appBarBackground,
          foregroundColor: theme.appBarForeground,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: theme.appBarAccent,
            labelColor: theme.appBarAccent,
            unselectedLabelColor: theme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [ ... ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.cardBorderColor)),
          ),
          child: const TabBarView(
            children: [
              PersonTab(),
              WorkfileTab(),
              ContractorTab(),
              EquipmentTab(),
              AreaTab(),
              TimesheetDataTab(),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Shared UI Patterns Across All Tabs

### 1. Responsive Grid Layout Pattern

All tabs use `StreamBuilder` + `LayoutBuilder` + `GridView.builder`. Breakpoints are consistent:

```dart
int crossAxisCount = 2;           // < 700px (mobile/small)
if (width > 700)  crossAxisCount = 3;   // tablet
if (width > 1000) crossAxisCount = 4;   // desktop
if (width > 1400) crossAxisCount = 5;   // large desktop
```

### 2. Dynamic Aspect Ratio

Each tab calculates its own `childAspectRatio` based on target card height:

```dart
double totalSpacing = (crossAxisCount - 1) * 16 + 32; // gaps + padding
double itemWidth = (width - totalSpacing) / crossAxisCount;
double childAspectRatio = itemWidth / TARGET_HEIGHT;
```

| Tab          | Target Height | Notes                      |
|--------------|---------------|----------------------------|
| Person       | `310`         | Tall card (avatar + info)  |
| Workfile     | fixed `0.85`  | Uses fixed ratio directly  |
| Area         | `230`         | Medium card                |
| Contractor   | `270`         | Medium card                |
| Equipment    | `260`         | Medium card                |
| TimesheetData| `170`         | Short card (icon + name)   |

### 3. Standard Delete Confirmation Dialog

All tabs use an `AlertDialog` for confirming deletions:
- `backgroundColor: theme.dialogBackground`
- `shape: RoundedRectangleBorder(borderRadius: 16, side: theme.cardBorderColor)`
- Title: `theme.textOnSurface`
- Content: `theme.textSecondary`
- Cancel: `TextButton` with `theme.textSecondary`
- Delete: `ElevatedButton` with `backgroundColor: Color(0xFFEF4444)` _(semantic red — hardcoded)_

### 4. Standard "ADD" Button

Area, Contractor, Equipment, and TimesheetData tabs use the same hardcoded green add button:
```dart
ElevatedButton.icon(
  backgroundColor: const Color(0xFF2ECC71),  // Semantic green — hardcoded
  foregroundColor: Colors.black,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  textStyle: TextStyle(fontWeight: FontWeight.bold),
)
```

> [!NOTE]
> Person tab uses `theme.primaryButtonBackground` for its "REGISTER OPERATOR" button instead of hardcoded green. This is the one exception.

---

## Related Tab Specifications
- Person Tab (`person_tab.md`)
- Workfile Tab (`workfile_tab.md`)
- Contractor Tab (`contractor_tab.md`)
- Equipment Tab (`equipment_tab.md`)
- Area Tab (`area_tab.md`)
- Timesheet Data Tab (`timesheet_data_tab.md`)
