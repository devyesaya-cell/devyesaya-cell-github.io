# Create Workfile Page Blueprint
Path: `lib/features/workfile/create_workfile_page.dart`

This page is a specialized form for creating new workfiles by linking Areas and Contractors with imported GeoJSON spatial data.

## 1. Page Architecture (Widget Tree)
```
Scaffold
├── AppBar (Themed)
└── Body: SingleChildScrollView
    └── Center
        └── Container (maxWidth: 600)
            └── Column (Main Layout)
                ├── _buildDropdown (Area)
                ├── _buildDropdown (Contractor)
                ├── _buildDropdown (SystemMode)
                ├── _buildDropdown (Spacing)
                ├── GeoJSON File Picker (Button + Selected Path)
                ├── Summary Card (Spots + Calculated Area)
                └── Create Workfile Button (Primary CTA)
```

## 2. Layout & Styling Detailing

### AppBar
- **Background**: `theme.appBarBackground`.
- **Title**: 'Create Workfile', `theme.appBarForeground`.
- **Icon Theme**: `theme.appBarForeground` or `theme.iconBoxIcon` (Teal accent).

### Custom Dropdown (`_buildDropdown`)
- **Label**: UPPERCASE, `fontSize: 12`, `fontWeight: bold`, `letterSpacing: 0.5`, Color: `theme.labelColor` (Teal accent).
- **Container**: `BoxDecoration`
  - `backgroundColor`: `theme.inputFill` (Opacity 0.05).
  - `borderRadius`: `BorderRadius.circular(12)`.
  - `border`: `Border.all(color: theme.inputBorder)` (Opacity 0.24).
- **Icon**: `Icons.expand_more`, Color: `theme.dropdownIcon`.
- **Text Style**: `fontSize: 16`, Color: `theme.inputTextColor`.

### GeoJSON File Picker
- **Type**: `ElevatedButton.icon`.
- **Icon**: `Icons.upload_file`.
- **Background**: `theme.inputFill` (Opacity 0.05).
- **Foreground**: `theme.inputTextColor`.
- **Shape**: `RoundedRectangleBorder(borderRadius: 12, side: BorderSide(theme.inputBorder))`.

### Summary Card
- **Background**: `theme.cardSurface`.
- **Border**: `Border.all(color: theme.cardBorderColor)`.
- **Shadow**: `BoxShadow(color: theme.primaryButtonShadow, blurRadius: 10)`.

### Primary Button (Create)
- **Background**: `theme.primaryButtonBackground`.
- **Foreground**: `theme.primaryButtonText`.
- **Disabled**: `Colors.white10` background, `Colors.white30` text.
- **Elevation**: 0.

## 3. Theme Token Mapping

| Component | Token | Property |
|-----------|-------|----------|
| Scaffold | `theme.pageBackground` | `backgroundColor` |
| Labels | `theme.labelColor` | `color` |
| Input Fields | `theme.inputFill` | `color` |
| Input Border | `theme.inputBorder` | `color` |
| Hint Text | `theme.inputHintText` | `color` |
| Primary Action | `theme.primaryButtonBackground` | `backgroundColor` |

## 4. UI Generation Rules
- **Initialization**: Always call `notifier.loadData()` in `initState` via `WidgetsBinding.instance.addPostFrameCallback`.
- **Validation**: The 'CREATE WORKFILE' button MUST be disabled unless:
  - `selectedArea != null`
  - `selectedContractor != null`
  - `parsedSpots.isNotEmpty`
- **Confirmation**: On success, use a `SnackBar` with `Colors.greenAccent[700]` and `black` text for maximum contrast.
- **Constraints**: Force `maxWidth: 600` on the main form container to ensure desktop/tablet readability.
- **Dynamic Updates**: The summary card values (Spots/Area) MUST update in real-time as the user selects a GeoJSON file or changes the Spacing.

---
> [!NOTE]
> All dropdowns and inputs should follow the **Login Card Tokens** pattern for visual consistency with the initial app entry point.
