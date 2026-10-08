# Setup: Configuration Gateway
Path: `lib/features/setup/setup_page.dart`

The `SetupPage` acts as the primary navigation hub for all technical and administrative configurations within the Excavator Guidance System. It allows the operator or technician to access specialized sub-pages for calibration, hardware status, and system settings.

## UI Layout
The page follows a clean, tile-based grid design to ensure ease of interaction using a touchscreen in a moving vehicle.

- **Scaffold**: Uses `theme.pageBackground` for consistent branding with the rest of the app.
- **AppBar**:
  - **Title**: `"SETUP"` (uppercase, `fontSize: 24`, `fontWeight: bold`).
  - **Colors**: Uses `theme.appBarBackground` and `theme.appBarForeground`.
  - **Elevation**: 0 (Flat design).
- **Body Padding**: Consistent `EdgeInsets.all(24.0)` to provide breathing room between the grid and the screen edges.

## Menu Grid Configuration
The `GridView.builder` is configured with the following parameters:
- **Cross Axis Count**: 3 (3 tiles per row).
- **Cross Axis Spacing**: 24.
- **Main Axis Spacing**: 24.
- **Child Aspect Ratio**: 1.3 (Ensures buttons are rectangular and large enough for touch targets).

## Menu Card Design (`_buildMenuCard`)
Each navigation tile is constructed using a `Material` widget with a physical elevation effect:
- **Background Color**: `theme.cardSurface`.
- **Border Radius**: `BorderRadius.circular(12)`.
- **Elevation**: `2` (Provides subtle depth).
- **Interactive Feedback**: Wrapped in an `InkWell` for visual ripple effects upon tapping.
- **Internal Content**:
    - A centered `Column` containing:
        - **Icon**: `size: 64`.
        - **Label**: `fontSize: 20`, `fontWeight: FontWeight.w500`, `theme.textOnSurface`.
        - **Vertical Gap**: `16` between icon and label.

## Menu Categories & Routing
Each tile maps to a specific feature page located in `lib/features/setup/pages/`.

| Title | Icon | Base Color | Destination Page |
| :--- | :--- | :--- | :--- |
| **Management** | `Icons.folder` | `Colors.amber` | `ManagementPage` |
| **Calibration** | `Icons.settings` | `Colors.orange` | `CalibrationPage` |
| **Synchronize** | `Icons.sync_alt_rounded` | `Colors.lightGreen` | `SyncPage` |
| **Radio** | `Icons.signal_cellular_alt`| `Colors.blueGrey`| `RadioPage` |
| **Debug** | `Icons.device_hub` | `Colors.blue` | `DebugPage` |
| **Work Config** | `Icons.settings` | `Colors.blueGrey`| `WorkConfigPage` |
| **Wireless** | `Icons.wifi` | `Colors.blue` | `WirelessPage` |
| **Testing** | `Icons.gps_fixed` | `Colors.blue` | `TestingPage` |
| **About** | `Icons.info` | `Colors.grey` | `AboutUsPage` |

## Navigation Logic
Navigation is handled via a standard `Navigator.push` with `MaterialPageRoute`, allowing the user to return to the main Setup menu using the system back button or the AppBar's back arrow in the sub-pages.
