# Person Tab — Blueprint

**File**: `lib/features/setup/widgets/management/person_tab.dart`  
**Widget Class**: `PersonTab` (extends `ConsumerStatefulWidget`)

_Displays all registered operators in a responsive grid. Supports filtering by system mode preset (ALL / SPOT / CRUMBLING), adding new operators, editing, and role-guarded deletion._

---

## Imports Required

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/app_repository.dart';
import '../../../../core/models/person.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../features/home/widgets/person_edit_dialog.dart';
import 'person_card_widget.dart';
```

---

## State

```dart
String _selectedFilter = 'ALL';  // Possible values: 'ALL', 'SPOT', 'CRUMBLING'
```

---

## Data Flow

```dart
// Watches a real-time stream from Isar DB
final personsStream = ref.watch(appRepositoryProvider).watchPersons();
final currentUser = ref.watch(authProvider).currentUser;  // for role-gating delete
```

> [!WARNING]
> Uses `StreamBuilder<List<Person>>` (classic pattern, NOT `StreamProvider`). This is an intentional legacy usage in the management tabs — do not convert to `StreamProvider`.

---

## Layout: Toolbar + Grid

```
Column:
├── Padding(all: 16)
│   └── Row(spaceBetween)
│       ├── Row [Filter Chips]  ← left side
│       │   ├── _buildFilterTab('ALL UNITS', 'ALL')
│       │   ├── SizedBox(width: 12)
│       │   ├── _buildFilterTab('SPOT', 'SPOT')
│       │   ├── SizedBox(width: 12)
│       │   └── _buildFilterTab('CRUMBLING', 'CRUMBLING')
│       └── ElevatedButton.icon [REGISTER OPERATOR]  ← right side
│
└── Expanded:
    ├── if persons.isEmpty → Center(Text('No persons found.'))
    └── else → GridView.builder (responsive, target height: 310)
                └── PersonCardWidget(person, showDelete, onEdit, onDelete)
```

---

## Filter Logic

```dart
if (_selectedFilter != 'ALL') {
  persons = persons.where((p) {
    final preset = p.preset?.toUpperCase() ?? '';
    return preset == _selectedFilter;
  }).toList();
}
```

Filter is applied client-side after fetching from the stream.

---

## `_buildFilterTab` — Capsule Filter Button

```dart
Widget _buildFilterTab(String label, String value) {
  final theme = AppTheme.of(context);
  bool isSelected = _selectedFilter == value;
  return InkWell(
    onTap: () => setState(() => _selectedFilter = value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryButtonBackground : theme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: theme.dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? theme.primaryButtonText : theme.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ),
  );
}
```

**Selected state:** `theme.primaryButtonBackground` background, `theme.primaryButtonText` text, no border.  
**Unselected state:** `theme.cardSurface` background, `theme.textSecondary` text, `theme.dividerColor` border.

---

## "REGISTER OPERATOR" Button

```dart
ElevatedButton.icon(
  onPressed: () => showDialog(
    context: context,
    builder: (context) => const PersonEditDialog(person: null),
  ),
  icon: const Icon(Icons.add),
  label: const Text('REGISTER OPERATOR'),
  style: ElevatedButton.styleFrom(
    backgroundColor: theme.primaryButtonBackground,  // ← uses theme (not hardcoded green!)
    foregroundColor: theme.primaryButtonText,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
)
```

---

## Responsive Grid

```dart
// LayoutBuilder breakpoints:
int crossAxisCount = 2;
if (width > 600)  crossAxisCount = 3;   // Note: uses 600, not 700!
if (width > 900)  crossAxisCount = 4;
if (width > 1400) crossAxisCount = 5;

// Dynamic aspect ratio — target card height: 310
double totalSpacing = (crossAxisCount - 1) * 16 + 32;
double itemWidth = (width - totalSpacing) / crossAxisCount;
double childAspectRatio = itemWidth / 310;

GridView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  crossAxisSpacing: 16,
  mainAxisSpacing: 16,
)
```

> [!NOTE]
> Person tab uses `600` and `900` as breakpoints instead of `700` and `1000` like other tabs. Do NOT align these to the other tabs.

---

## `PersonCardWidget` Props

```dart
PersonCardWidget(
  person: person,
  showDelete: _canDelete(currentUser, person),
  onEdit: () => showDialog(context: context, builder: (_) => PersonEditDialog(person: person)),
  onDelete: () => _confirmDelete(context, ref, person),
)
```

---

## Delete Permission Logic

```dart
bool _canDelete(Person? currentUser, Person targetPerson) {
  if (currentUser == null) return false;
  if (currentUser.role != 'admin') return false;      // Only admin can delete
  if (currentUser.uid == targetPerson.uid) return false;  // Cannot delete self
  return true;
}
```

---

## Delete Confirmation Dialog

```dart
AlertDialog(
  backgroundColor: theme.dialogBackground,
  title: Text('Delete Operator', style: TextStyle(color: theme.textOnSurface)),
  content: Text(
    'Are you sure you want to delete ${person.firstName}?',
    style: TextStyle(color: theme.textSecondary),
  ),
  actions: [
    TextButton('Cancel', color: theme.textSecondary),
    ElevatedButton('Delete',
      backgroundColor: const Color(0xFFEF4444),  // Semantic red
      foregroundColor: Colors.white,
    ),
  ],
)
```

**On confirm:** `ref.read(appRepositoryProvider).deletePerson(person.id)`

---

## Theme Token Usage Summary

| Element                    | Token                          |
|----------------------------|--------------------------------|
| Filter chip (selected) bg  | `theme.primaryButtonBackground` |
| Filter chip (selected) text| `theme.primaryButtonText`      |
| Filter chip (unselected) bg| `theme.cardSurface`            |
| Filter chip (unselected) txt| `theme.textSecondary`         |
| Filter chip (unselected) border | `theme.dividerColor`      |
| "Register" button bg       | `theme.primaryButtonBackground` |
| "Register" button text     | `theme.primaryButtonText`      |
| Empty state text           | `theme.textSecondary`          |
| Dialog background          | `theme.dialogBackground`       |
| Dialog title               | `theme.textOnSurface`          |
| Dialog content             | `theme.textSecondary`          |
| Cancel button text         | `theme.textSecondary`          |
| Delete button              | `Color(0xFFEF4444)` _(hardcoded)_ |

---

## Related Specifications
- Person Edit Dialog (`person_edit_dialog.md`)
- Management Detail (`management_detail.md`)
