# Workfile Tab — Blueprint

**File**: `lib/features/setup/widgets/management/workfile_tab.dart`  
**Widget Class**: `WorkfileTab` (extends `ConsumerWidget`)

_Displays all workfiles in a responsive grid. Supports role-gated deletion (admin/supervisor only). No add button — workfiles are created from a different flow (e.g., WorkfilePage)._

---

## Imports Required

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/person.dart';
import '../../../../core/repositories/app_repository.dart';
import '../../../../core/models/workfile.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/utils/app_theme.dart';
import 'workfile_card_widget.dart';
```

---

## Data Flow

```dart
final workfilesStream = ref.watch(appRepositoryProvider).watchWorkFiles();
final currentUser = ref.watch(authProvider).currentUser;  // for role-gating
```

> [!WARNING]
> Uses `StreamBuilder<List<WorkFile>>` (classic pattern). No Riverpod `StreamProvider`.

---

## Layout

```
StreamBuilder:
├── loading → CircularProgressIndicator (centered)
├── error   → Text('Error: $err')
├── empty   → Center(Text('No workfiles found.', color: theme.textSecondary))
└── data    → LayoutBuilder → GridView.builder
                └── WorkfileCardWidget(workfile, showDelete, onDelete)
```

> [!IMPORTANT]
> **There is NO toolbar / add button row** in this tab. The `GridView` fills the entire body directly (with `padding: EdgeInsets.all(16)`). This is unlike all other management tabs which have a Padding + Row toolbar on top.

---

## Responsive Grid

```dart
int crossAxisCount = 2;
if (width > 700)  crossAxisCount = 3;
if (width > 1000) crossAxisCount = 4;
if (width > 1400) crossAxisCount = 5;

GridView.builder(
  padding: const EdgeInsets.all(16),   // Note: all-sides padding (not symmetric)
  crossAxisSpacing: 16,
  mainAxisSpacing: 16,
  childAspectRatio: 0.85,              // Fixed ratio — NOT dynamic
)
```

> [!NOTE]
> Workfile tab is the **only tab** that uses a **fixed `childAspectRatio: 0.85`** instead of a dynamically calculated one.

---

## `WorkfileCardWidget` Props

```dart
WorkfileCardWidget(
  workfile: workfile,
  showDelete: _canDelete(currentUser),
  onDelete: () => _confirmDelete(context, ref, workfile),
)
```

---

## Delete Permission Logic

```dart
bool _canDelete(Person? currentUser) {
  if (currentUser == null) return false;
  // Both admin AND supervisor can delete (more permissive than Person tab)
  return currentUser.role == 'admin' || currentUser.role == 'supervisor';
}
```

> [!NOTE]
> Unlike Person tab (admin-only delete), Workfile allows **admin or supervisor** to delete.

---

## Delete Confirmation Dialog

```dart
AlertDialog(
  backgroundColor: theme.dialogBackground,
  title: Text('Delete Workfile', style: TextStyle(color: theme.textOnSurface)),
  content: Text(
    'Are you sure you want to delete this workfile? This will also delete all associated working spots.',
    style: TextStyle(color: theme.textSecondary),
  ),
  actions: [
    TextButton('Cancel', color: theme.textSecondary),
    ElevatedButton('Delete',
      backgroundColor: const Color(0xFFEF4444),
      foregroundColor: Colors.white,
    ),
  ],
)
```

> [!IMPORTANT]
> The content message must explicitly warn: **"This will also delete all associated working spots."**

**On confirm:**
```dart
final String fileID = workfile.uid.toString();  // uid cast to String
await ref.read(appRepositoryProvider).deleteWorkFile(workfile.id, fileID);
```

> [!NOTE]
> `deleteWorkFile` takes **two parameters**: `workfile.id` (Isar internal ID) and `workfile.uid.toString()` (string file ID). Do not pass only one.

---

## Theme Token Usage Summary

| Element              | Token                             |
|----------------------|-----------------------------------|
| Empty state text     | `theme.textSecondary`             |
| Dialog background    | `theme.dialogBackground`          |
| Dialog title         | `theme.textOnSurface`             |
| Dialog content       | `theme.textSecondary`             |
| Cancel button text   | `theme.textSecondary`             |
| Delete button        | `Color(0xFFEF4444)` _(hardcoded)_ |
