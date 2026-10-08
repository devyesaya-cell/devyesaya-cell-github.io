# Equipment Tab — Blueprint

**File**: `lib/features/setup/widgets/management/equipment_tab.dart`  
**Widget Classes**: `EquipmentTab` (ConsumerWidget) + `_EquipmentEditDialog` (StatefulWidget, private)

_Displays all registered equipment in a responsive grid. Full CRUD with the most complex inline edit dialog (6 fields: 4 text + 2 dropdowns in a 2-column layout)._

---

## Imports Required

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/app_repository.dart';
import '../../../../core/models/equipment.dart';
import '../../../../core/utils/app_theme.dart';
import 'equipment_card_widget.dart';
```

---

## Static Data Lists

```dart
static const List<String> _models = [
  'Hitachi', 'Komatsu', 'Sunny', 'Caterpillar',
  'Volvo', 'Doosan', 'Sany', 'Other',
];

static const List<String> _types = [
  'Excavator', 'Dozer', 'Grader', 'Truck',
  'Compactor', 'Wheel Loader', 'Crane', 'Other',
];
```

---

## Data Flow

```dart
final equipmentsStream = ref.watch(appRepositoryProvider).watchEquipments();
```

---

## Layout

```
StreamBuilder:
├── loading → CircularProgressIndicator
└── data    → LayoutBuilder → Column
    ├── Padding(all: 16) → Row(end) → ElevatedButton.icon [ADD EQUIPMENT]
    ├── if empty → Expanded(Center(Text('No equipment found.', theme.textSecondary)))
    └── else → Expanded(GridView.builder, target height: 260)
                └── EquipmentCardWidget(equipment, onEdit, onDelete)
```

> [!NOTE]
> Empty state uses `theme.textSecondary` via `Builder` context (unlike Area/Contractor which use `Colors.white54`).

---

## Responsive Grid

```dart
int crossAxisCount = 2;
if (width > 700)  crossAxisCount = 3;
if (width > 1000) crossAxisCount = 4;
if (width > 1400) crossAxisCount = 5;

// Target card height: 260
double childAspectRatio = itemWidth / 260;

GridView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
)
```

---

## `_EquipmentEditDialog` — Add/Edit Dialog

```dart
class _EquipmentEditDialog extends StatefulWidget {
  final Equipment? equipment;      // null = Add, non-null = Edit
  final WidgetRef ref;
  final List<String> models;       // passed from parent static list
  final List<String> types;        // passed from parent static list
}
```

### State Controllers

```dart
late TextEditingController _equipNameController;
late TextEditingController _partNameController;
late TextEditingController _unitNumberController;
late TextEditingController _armLengthController;
String? _selectedModel;
String? _selectedType;
```

### initState — Populate on Edit

```dart
final e = widget.equipment;
_equipNameController = TextEditingController(text: e?.equipName ?? '');
_partNameController = TextEditingController(text: e?.partName ?? '');
_unitNumberController = TextEditingController(text: e?.unitNumber ?? '');
_armLengthController = TextEditingController(text: e?.armLength?.toString() ?? '');
_selectedModel = e?.model;
_selectedType = e?.type;
```

### `_save()` Logic

```dart
Future<void> _save() async {
  final now = DateTime.now();
  final equipToSave = widget.equipment ?? Equipment();

  equipToSave
    ..uid = now.millisecondsSinceEpoch.toString()
    ..equipName = _equipNameController.text.trim()
    ..partName = _partNameController.text.trim()
    ..unitNumber = _unitNumberController.text.trim()
    ..armLength = double.tryParse(_armLengthController.text)  // nullable double
    ..model = _selectedModel
    ..type = _selectedType
    ..lastUpdate = now.millisecondsSinceEpoch;
    // Note: lastDriver and ipAddress are intentionally left empty

  await widget.ref.read(appRepositoryProvider).saveEquipment(equipToSave);
  if (mounted) Navigator.of(context).pop();
}
```

> [!NOTE]
> Equipment save has **no name validation guard** (unlike Area/Contractor). It saves even if all fields are empty.

### Dialog Container

```dart
Dialog(
  backgroundColor: theme.dialogBackground,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: theme.cardBorderColor),
  ),
  child: Container(
    padding: const EdgeInsets.all(24),
    width: 580,                          // Widest dialog (580px)
    child: SingleChildScrollView(        // ← Wrapped in SingleChildScrollView
      child: Column(mainAxisSize: MainAxisSize.min, ...),
    ),
  ),
)
```

> [!IMPORTANT]
> Equipment dialog wraps its content in `SingleChildScrollView` to handle overflow on small screens. Area and Contractor dialogs do NOT use this wrapper.

### Dialog Form Layout (All 2-column)

```
Header Row [Icon(Icons.handyman) + Title + Close button]
Divider(color: theme.dividerColor)   ← No SizedBox(8) before divider (unlike Contractor)
SizedBox(height: 16)

Row:
  _buildField('EQUIP NAME', _equipNameController, hint: 'e.g. PC200')
  SizedBox(width: 16)
  _buildField('PART NAME', _partNameController, hint: 'e.g. Bucket')
SizedBox(height: 16)

Row:
  _buildField('UNIT NUMBER', _unitNumberController, hint: 'e.g. EX-001')
  SizedBox(width: 16)
  _buildField('ARM LENGTH (m)', _armLengthController, hint: 'e.g. 5.5', isDecimal: true)
SizedBox(height: 16)

Row:
  _buildDropdown('MODEL', widget.models, _selectedModel, onChanged)
  SizedBox(width: 16)
  _buildDropdown('TYPE', widget.types, _selectedType, onChanged)
SizedBox(height: 24)

Row [CANCEL OutlinedButton | SAVE ElevatedButton.icon]
```

### Dropdown Hint Text

```dart
hint: Text('Select...', style: TextStyle(color: theme.textSecondary))
// Note: "Select..." (not "Select spacing..." like Area tab)
```

---

## Delete Confirmation Dialog

```dart
AlertDialog(
  backgroundColor: theme.dialogBackground,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: theme.cardBorderColor),
  ),
  title: Text('Delete Equipment', style: TextStyle(color: theme.textOnSurface)),
  content: Text(
    'Are you sure you want to delete "${equipment.equipName ?? equipment.unitNumber}"?',
    style: TextStyle(color: theme.textSecondary),
  ),
)
```

> [!NOTE]
> Delete content uses a null-coalescing fallback: `equipName ?? unitNumber`. If both are null, it shows `null`.

**On confirm:** `ref.read(appRepositoryProvider).deleteEquipment(equipment.id)`

---

## Theme Token Usage Summary

| Element                  | Token                             |
|--------------------------|-----------------------------------|
| ADD button background    | `Color(0xFF2ECC71)` _(hardcoded)_ |
| ADD button text          | `Colors.black` _(hardcoded)_      |
| Empty state text         | `theme.textSecondary`             |
| Dialog bg                | `theme.dialogBackground`          |
| Dialog border            | `theme.cardBorderColor`           |
| Header icon              | `theme.appBarAccent`              |
| Close icon               | `theme.textSecondary`             |
| Field label              | `theme.appBarAccent`              |
| Input fill               | `theme.inputFill`                 |
| Input border             | `theme.inputBorder`               |
| Input focused border     | `theme.appBarAccent`              |
| Dropdown bg              | `theme.dropdownBackground`        |
| Dropdown item text       | `theme.dropdownItemText`          |
| Cancel button            | `theme.textOnSurface` + `theme.dividerColor` |
| Save button              | `theme.primaryButtonBackground` + `theme.primaryButtonText` |
| Delete button            | `Color(0xFFEF4444)` _(hardcoded)_ |
