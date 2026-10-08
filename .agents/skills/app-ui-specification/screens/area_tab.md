# Area Tab — Blueprint

**File**: `lib/features/setup/widgets/management/area_tab.dart`  
**Widget Classes**: `AreaTab` (ConsumerWidget) + `_AreaEditDialog` (StatefulWidget, private)

_Displays all work areas in a responsive grid. Supports creating, editing, and deleting areas. The inline edit dialog (`_AreaEditDialog`) is defined in the same file._

---

## Imports Required

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/app_repository.dart';
import '../../../../core/models/area.dart';
import '../../../../core/utils/app_theme.dart';
import 'area_card_widget.dart';
```

---

## Static Data

```dart
static const List<String> _spacingOptions = [
  '4x1.87', '4x1.5', '3x2.5', '3x2',
  '2.5x2.5', '5x2', '6x2', 'Custom',
];
```

---

## Layout

```
StreamBuilder:
├── loading → CircularProgressIndicator (centered)
└── data    → LayoutBuilder → Column
    ├── Padding(all: 16)
    │   └── Row(mainAxisAlignment: end)
    │       └── ElevatedButton.icon [ADD AREA] (green, black text)
    ├── if areas.isEmpty → Expanded(Center(Text('No areas found.', Colors.white54)))
    └── else → Expanded(GridView.builder)
                └── AreaCardWidget(area, onEdit, onDelete)
```

> [!NOTE]
> Empty state uses `Colors.white54` (hardcoded), not `theme.textSecondary`. This is intentional.

---

## Responsive Grid

```dart
int crossAxisCount = 2;
if (width > 700)  crossAxisCount = 3;
if (width > 1000) crossAxisCount = 4;
if (width > 1400) crossAxisCount = 5;

// Target card height: 230
double totalSpacing = (crossAxisCount - 1) * 16 + 32;
double itemWidth = (width - totalSpacing) / crossAxisCount;
double childAspectRatio = itemWidth / 230;

GridView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  crossAxisSpacing: 16,
  mainAxisSpacing: 16,
)
```

---

## ADD AREA Button

```dart
ElevatedButton.icon(
  onPressed: () => _showEditDialog(context, ref, null),  // null = new
  icon: const Icon(Icons.add),
  label: const Text('ADD AREA'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF2ECC71),  // Semantic green — hardcoded
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  ),
)
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
  title: Text('Delete Area', style: TextStyle(color: theme.textOnSurface)),
  content: Text(
    'Are you sure you want to delete "${area.areaName}"?',
    style: TextStyle(color: theme.textSecondary),
  ),
  actions: [
    TextButton('Cancel', color: theme.textSecondary),
    ElevatedButton('Delete', backgroundColor: Color(0xFFEF4444)),
  ],
)
```

**On confirm:** `ref.read(appRepositoryProvider).deleteArea(area.id)` — no `Navigator.pop()` after confirm (the button calls it directly in `onPressed`).

---

## `_AreaEditDialog` — Add/Edit Dialog

A separate `StatefulWidget` defined in the **same file** (not imported from elsewhere).

### Widget Props

```dart
class _AreaEditDialog extends StatefulWidget {
  final Area? area;           // null = Add mode, non-null = Edit mode
  final WidgetRef ref;        // passed in from ConsumerWidget
  final List<String> spacingOptions;
}
```

### State Controllers

```dart
late TextEditingController _areaNameController;
late TextEditingController _luasAreaController;
late TextEditingController _targetDoneController;
String? _selectedSpacing;
```

### initState — Populate on Edit

```dart
final a = widget.area;
_areaNameController = TextEditingController(text: a?.areaName ?? '');
_luasAreaController = TextEditingController(text: a?.luasArea?.toString() ?? '');
_targetDoneController = TextEditingController(text: a?.targetDone?.toString() ?? '');
_selectedSpacing = a?.spacing;
```

### `_save()` Logic

```dart
Future<void> _save() async {
  final name = _areaNameController.text.trim();
  if (name.isEmpty) return;  // Guard: name must not be empty

  final now = DateTime.now();
  final areaToSave = widget.area ?? Area();  // create or reuse

  areaToSave
    ..uid = now.millisecondsSinceEpoch.toString()  // always refresh uid on save
    ..areaName = name
    ..luasArea = double.tryParse(_luasAreaController.text)
    ..targetDone = int.tryParse(_targetDoneController.text)
    ..spacing = _selectedSpacing;

  await widget.ref.read(appRepositoryProvider).saveArea(areaToSave);
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
    width: 480,
    // ...
  ),
)
```

### Dialog Header

```dart
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
  Row(children: [
    Icon(Icons.terrain, color: theme.appBarAccent),
    SizedBox(width: 12),
    Text(isEdit ? 'EDIT AREA' : 'ADD AREA',
        style: TextStyle(
          color: theme.textOnSurface, fontSize: 16,
          fontWeight: FontWeight.bold, letterSpacing: 1.2,
        )),
  ]),
  IconButton(Icons.close, color: theme.textSecondary, onPressed: pop),
])
Divider(color: theme.dividerColor)
```

### Dialog Form Fields

```
_buildField('AREA NAME', _areaNameController)           [text]
SizedBox(height: 16)
Row:
  _buildField('LUAS AREA (Ha)', _luasAreaController)    [decimal]
  SizedBox(width: 16)
  _buildField('TARGET SELESAI (Days)', _targetDoneController) [integer]
SizedBox(height: 16)
_buildDropdown('SPACING', _spacingOptions, _selectedSpacing)
```

### `_buildField` Widget

```dart
Widget _buildField(AppThemeData theme, String label, TextEditingController controller, {
  String? hint,
  bool isDecimal = false,
  bool isInteger = false,
}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(
      color: theme.appBarAccent, fontSize: 10,
      fontWeight: FontWeight.bold, letterSpacing: 1.1,
    )),
    SizedBox(height: 8),
    TextField(
      controller: controller,
      style: TextStyle(color: theme.textOnSurface),
      keyboardType: isDecimal
          ? TextInputType.numberWithOptions(decimal: true)
          : isInteger ? TextInputType.number : TextInputType.text,
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : isInteger ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        filled: true, fillColor: theme.inputFill,
        hintText: hint, hintStyle: TextStyle(color: theme.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.appBarAccent)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  ]);
}
```

### `_buildDropdown` Widget

```dart
Widget _buildDropdown(AppThemeData theme, String label, List<String> items, String? value, void Function(String?) onChanged) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: theme.appBarAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
    SizedBox(height: 8),
    DropdownButtonFormField<String>(
      value: value,
      dropdownColor: theme.dropdownBackground,
      style: TextStyle(color: theme.dropdownItemText),
      hint: Text('Select spacing...', style: TextStyle(color: theme.textSecondary)),
      decoration: InputDecoration(
        filled: true, fillColor: theme.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.appBarAccent)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    ),
  ]);
}
```

### Dialog Action Buttons

```dart
Row(children: [
  Expanded(child: OutlinedButton(
    'CANCEL',
    foregroundColor: theme.textOnSurface,
    side: BorderSide(color: theme.dividerColor),
    padding: EdgeInsets.symmetric(vertical: 16),
    borderRadius: BorderRadius.circular(8),
  )),
  SizedBox(width: 16),
  Expanded(child: ElevatedButton.icon(
    icon: Icons.save_outlined (size: 16),
    label: 'SAVE',
    backgroundColor: theme.primaryButtonBackground,
    foregroundColor: theme.primaryButtonText,
    fontWeight: bold, padding: vertical 16, borderRadius: 8,
  )),
])
```
