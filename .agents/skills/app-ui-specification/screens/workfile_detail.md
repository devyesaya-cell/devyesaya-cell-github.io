# Workfile Page Blueprint
Path: `lib/features/workfile/workfile_page.dart`

This page displays a filtered grid of available workfiles based on the current `SystemMode`.

## 1. Page Architecture (Widget Tree)
```
Scaffold
├── AppBar (Standard Pattern)
└── Body: StreamBuilder<List<WorkFile>>
    └── GridView.builder (3 columns)
        └── WorkfileCard
└── FloatingActionButton (Add New)
```

## 2. Layout & Styling Detailing

### AppBar
Use the **Standard AppBar Pattern** defined in `theme_system.md`:
- **Icon Box**: `Icons.folder`, Background: `theme.iconBoxBackground`, Icon: `theme.iconBoxIcon`.
- **Title**: 'WORKFILES' (UPPERCASE).
- **Subtitle**: 'EGS WORKFILE V4.0.0', Color: `theme.appBarAccent`.
- **Actions**: `GlobalAppBarActions()`.

### Grid Layout
- **Container**: `Padding(padding: EdgeInsets.all(16.0))`
- **GridView**: `SliverGridDelegateWithFixedCrossAxisCount`
  - `crossAxisCount`: 3
  - `crossAxisSpacing`: 16.0
  - `mainAxisSpacing`: 16.0
  - `childAspectRatio`: 1.1 (slightly wider than tall)

### Floating Action Button
- **Placement**: Bottom Right.
- **Icon**: `Icons.add`.
- **Background**: `theme.primaryButtonBackground`.
- **Foreground**: `theme.primaryButtonText`.
- **Action**: Navigates to `CreateWorkfilePage`.

## 3. Theme Token Mapping

| Component | Token | Property |
|-----------|-------|----------|
| Scaffold | `theme.pageBackground` | `backgroundColor` |
| AppBar | `theme.appBarBackground` | `backgroundColor` |
| Loading | `theme.loadingIndicatorColor` | `valueColor` |
| Empty Text | `theme.textSecondary` | `color` (16px) |

## 4. Logical Flow & State
- **Data Source**: `repo.watchWorkFiles()` (Riverpod `appRepositoryProvider`).
- **Filtering**:
  ```dart
  final workfiles = allWorkfiles
      .where((w) => w.equipment?.toUpperCase() == currentSystemMode)
      .toList();
  ```
- **Interaction**: Tapping a `WorkfileCard`:
  1. Call `ref.read(authProvider.notifier).setActiveWorkfile(workfile)`.
  2. Navigate to `MapPage()`.

---
> [!IMPORTANT]
> The page uses `StreamBuilder` for real-time updates from Isar. Ensure the `currentSystemMode` is derived from `authProvider` to maintain filtering consistency when the user switches equipment modes.
