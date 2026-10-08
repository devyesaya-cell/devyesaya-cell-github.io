# Contractor Tab — Blueprint

**File**: `lib/features/setup/widgets/management/contractor_tab.dart`  
**Widget Classes**: `ContractorTab` (ConsumerWidget) + `_ContractorEditDialog` (StatefulWidget, private)

_Displays all contractors in a responsive grid. Full CRUD with inline edit dialog._

---

## Imports Required

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/app_repository.dart';
import '../../../../core/models/contractor.dart';
import '../../../../core/utils/app_theme.dart';
import 'contractor_card_widget.dart';
```

---

## Data Flow

```dart
final contractorsStream = ref.watch(appRepositoryProvider).watchContractors();
```

---

## Layout

```
StreamBuilder:
├── loading → CircularProgressIndicator
└── data    → LayoutBuilder → Column
    ├── Padding(all: 16)
    │   └── Row(mainAxisAlignment: end)
    │       └── ElevatedButton.icon [ADD CONTRACTOR] (green, black text)
    ├── if empty → Expanded(Center(Text('No contractors found.', Colors.white54)))
    └── else → Expanded(GridView.builder, target height: 270)
                └── ContractorCardWidget(contractor, onEdit, onDelete)
```

---

## Responsive Grid

```dart
int crossAxisCount = 2;
if (width > 700)  crossAxisCount = 3;
if (width > 1000) crossAxisCount = 4;
if (width > 1400) crossAxisCount = 5;

// Target card height: 270
double childAspectRatio = itemWidth / 270;

GridView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
)
```

---

## `_ContractorEditDialog` — Add/Edit Dialog

```dart
class _ContractorEditDialog extends StatefulWidget {
  final Contractor? contractor;  // null = Add, non-null = Edit
  final WidgetRef ref;
}
```

### State Controllers

```dart
late TextEditingController _nameController;
late TextEditingController _sectorController;
late TextEditingController _areaController;
late TextEditingController _numEquipmentController;
late TextEditingController _numOperatorController;
```

### initState — Populate on Edit

```dart
final c = widget.contractor;
_nameController = TextEditingController(text: c?.name ?? '');
_sectorController = TextEditingController(text: c?.sector ?? '');
_areaController = TextEditingController(text: c?.area ?? '');
_numEquipmentController = TextEditingController(text: c?.numberEquipment?.toStringAsFixed(0) ?? '');
_numOperatorController = TextEditingController(text: c?.numberOperator?.toStringAsFixed(0) ?? '');
```

### `_save()` Logic

```dart
Future<void> _save() async {
  final name = _nameController.text.trim();
  if (name.isEmpty) return;

  final now = DateTime.now();
  final contractorToSave = widget.contractor ?? Contractor();

  contractorToSave
    ..uid = now.millisecondsSinceEpoch.toString()
    ..name = name
    ..sector = _sectorController.text.trim()
    ..area = _areaController.text.trim()
    ..numberEquipment = double.tryParse(_numEquipmentController.text) ?? 0
    ..numberOperator = double.tryParse(_numOperatorController.text) ?? 0
    ..lastUpdate = now.millisecondsSinceEpoch;  // int timestamp in ms

  await widget.ref.read(appRepositoryProvider).saveContractor(contractorToSave);
  if (mounted) Navigator.of(context).pop();
}
```

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
    width: 520,                   // Note: 520px wide (vs Area's 480)
    child: Column(mainAxisSize: MainAxisSize.min, ...),
  ),
)
```

### Dialog Form Layout

```
Header Row [Icon(Icons.business) + Title + Close button]
SizedBox(height: 8)     ← note the extra 8px before divider
Divider(color: theme.dividerColor)
SizedBox(height: 16)

_buildField('NAME', _nameController)
SizedBox(height: 16)
_buildField('SECTOR', _sectorController)
SizedBox(height: 16)
_buildField('AREA', _areaController)
SizedBox(height: 16)
Row:
  _buildField('NUMBER OF EQUIPMENT', _numEquipmentController, isNumber: true)
  SizedBox(width: 16)
  _buildField('NUMBER OF OPERATORS', _numOperatorController, isNumber: true)
SizedBox(height: 24)

Row [CANCEL OutlinedButton | SAVE ElevatedButton.icon]
```

### `_buildField` Widget (Contractor version — `isNumber` flag)

```dart
Widget _buildField(AppThemeData theme, String label, TextEditingController controller, {
  String? hint,
  bool isNumber = false,   // Note: uses isNumber, not isDecimal/isInteger like Area
}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(
      color: theme.appBarAccent, fontSize: 10,
      fontWeight: FontWeight.bold, letterSpacing: 1.1,
    )),
    SizedBox(height: 8),
    TextField(
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      // ... same InputDecoration style as Area tab
    ),
  ]);
}
```

> [!NOTE]
> Contractor's `_buildField` has a single `isNumber` flag (digits only). It has **no `isDecimal` option** unlike the Area tab.

---

## Theme Token Usage Summary

| Element                | Token                             |
|------------------------|-----------------------------------|
| Empty state text       | `Colors.white54` _(hardcoded)_    |
| ADD button background  | `Color(0xFF2ECC71)` _(hardcoded)_ |
| ADD button text        | `Colors.black` _(hardcoded)_      |
| Dialog background      | `theme.dialogBackground`          |
| Dialog border          | `theme.cardBorderColor`           |
| Dialog header icon     | `theme.appBarAccent`              |
| Field label text       | `theme.appBarAccent`              |
| Input fill             | `theme.inputFill`                 |
| Input border (default) | `theme.inputBorder`               |
| Input border (focused) | `theme.appBarAccent`              |
| Dropdown bg            | `theme.dropdownBackground`        |
| Dropdown item text     | `theme.dropdownItemText`          |
| Cancel button          | `theme.textOnSurface` + `theme.dividerColor` border |
| Save button            | `theme.primaryButtonBackground` + `theme.primaryButtonText` |
| Delete button          | `Color(0xFFEF4444)` _(hardcoded)_ |
