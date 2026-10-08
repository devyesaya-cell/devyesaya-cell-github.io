# Person Edit Dialog — Blueprint

**File**: `lib/features/home/widgets/person_edit_dialog.dart`  
**Widget Class**: `PersonEditDialog` (extends `ConsumerStatefulWidget`)

_A comprehensive dialog for registering new operators or editing existing profiles. It features a dual-column layout with an integrated image picker and multi-field form._

---

## Dependencies
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/person.dart';
import '../../../../core/models/contractor.dart';
import '../../../../core/models/equipment.dart';
import '../../../../core/repositories/app_repository.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/utils/app_theme.dart';
```

---

## State Management

### Controllers & Selected Values
- `TextEditingController`: `_firstNameController`, `_lastNameController`, `_driverIdController`, `_passwordController`, `_picUrlController`.
- `String?`: `_selectedContractor`, `_selectedEquipment`, `_selectedPicUrl`, `_selectedRole`.

### Assets Selection
Static list of available profile icons:
```dart
final List<String> _availableImages = [
  'images/driver_exca.png',
  'images/ic_supir.png',
  'images/setup_driver.png',
  'images/mng_1.png',
  'images/ic_setProfile.png',
];
```

---

## UI Structure

### Root Container
```dart
Dialog(
  backgroundColor: theme.pageBackground,
  width: 900,
  height: 600,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: theme.cardBorderColor),
  ),
  child: Padding(padding: const EdgeInsets.all(24), child: Column(...)),
)
```

### 1. Header (Title & Close)
- Icon: `Icons.person_add` (color: `theme.appBarAccent`)
- Text: `'ADD NEW OPERATOR'` or `'EDIT OPERATOR'` (based on `widget.person == null`)
- Style: `FontWeight.bold`, `letterSpacing: 1.2`, `fontSize: 18`.

### 2. Main Content (`Expanded` Row)
Split `1:2` between Image Picker and Form Fields.

#### **Left Column (flex: 1) — Portrait Picker**
- Label: `'OPERATOR PORTRAIT'` (style: `fontSize: 10`, `bold`, `letterSpacing: 1.1`).
- Main Box: `Container` with `theme.inputFill`, `Border.all(color: theme.inputFocusedBorder)`.
- Stack contents:
    - If `_selectedPicUrl != null`: `Image.asset` (fit: `BoxFit.cover`).
    - If `null`: `Icons.camera_alt_outlined` + `'SELECT IMAGE'`.
    - **Ready Badge**: Positioned at bottom-right (`bottom: -15, right: 20`).
      - Decoration: `theme.primaryButtonBackground`, `circular(20)`.
      - Text: `'READY'` (`Color: theme.primaryButtonText`, `fontSize: 10`, `bold`).
- Footer Text: `'SUPPORTED: PNG, JPG\nMAX SIZE: 5MB'`.

#### **Right Column (flex: 2) — Form Fields**
Wrapped in `SingleChildScrollView`. Fields use `_buildTextField`, `_buildContractorDropdown`, `_buildEquipmentDropdown`, and `_buildRoleDropdown`.

- **Field Layout**:
    - Row 1: `FIRST NAME` (hint: `'e.g. Jonas'`) | `LAST NAME` (hint: `'e.g. Lindholm'`).
    - Field 2: `EMPLOYEE IDENTIFICATION NUMBER` (Icon: `Icons.badge_outlined`, hint: `'000-000-000'`).
    - Row 3: `CONTRACTOR` | `EQUIPMENT` | `ROLE`.
    - Field 4: `PASSWORD` (`obscureText: true`, Icon: `Icons.lock_outline`).

### 3. Footer (Actions)
- **Cancel Button**: `OutlinedButton` (border: `theme.dividerColor`, text: `theme.textOnSurface`).
- **Save Profile**: `ElevatedButton.icon`
    - Icon: `Icons.save_outlined`.
    - Style: `backgroundColor: theme.primaryButtonBackground`, `foregroundColor: theme.primaryButtonText`.
- **Status Text**: `'NODE CONNECTED'` positioned at the extreme bottom-right.

---

## Business Logic

### `_save()` Procedure
1. Initialize `Person` model (new or existing).
2. Generate `uid` using `DateTime.now().millisecondsSinceEpoch.toString()`.
3. Map all controller texts and selected values to the model.
4. Set `preset` from `ref.read(authProvider).mode.name`.
5. Set `loginState = 'ON'`.
6. Set `user` to `firstName.toLowerCase()`.
7. Call `ref.read(appRepositoryProvider).savePerson(personToSave)`.
8. If the edited person is the current user, refresh `authProvider.login()`.
9. Close dialog and show `SnackBar`.

### Image Picker (`_showImagePickerModal`)
Uses `showModalBottomSheet`:
- Height: `200`.
- Background: `theme.dialogBackground`.
- Content: `ListView.separated` (horizontal) displaying `_availableImages`.

---

## Theme Token Mapping

| UI Element | Theme Token |
|------------|-------------|
| Dialog Background | `theme.pageBackground` |
| Dialog Border | `theme.cardBorderColor` |
| Header Icon | `theme.appBarAccent` |
| Labels (Fields) | `theme.labelColor` |
| Input Fields Fill | `theme.inputFill` |
| Input Border | `theme.inputBorder` |
| Input Focused Border | `theme.inputFocusedBorder` |
| Input Text | `theme.inputTextColor` |
| Input Hint | `theme.inputHintText` |
| Dropdown Background | `theme.dropdownBackground` |
| Dropdown Text | `theme.dropdownItemText` |
| Ready Badge Background | `theme.primaryButtonBackground` |
| Ready Badge Text | `theme.primaryButtonText` |
| Cancel Button Border | `theme.dividerColor` |
| Save Button Background | `theme.primaryButtonBackground` |

---

## Detailed Component Specifications

### `_buildTextField`
- **Label**: `fontSize: 10`, `bold`, `letterSpacing: 1.1`, `bottom: 24` (padding).
- **Decoration**: `filled: true`, `borderRadius: 8`, `contentPadding: horizontal 16, vertical 16`.

### Dropdowns
- **Contractor**: Loads data via `ref.read(appRepositoryProvider).getAllContractors()`.
- **Equipment**: Loads data via `ref.read(appRepositoryProvider).getAllEquipment()`.
- **Role**: Hardcoded list: `['Operator', 'Helper', 'Supervisor', 'Engineer', 'Admin']`.
