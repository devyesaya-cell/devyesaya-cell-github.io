# Home: Dashboard & Navigation Page
Path: `lib/features/home/home_page.dart`

The `HomePage` serves as the primary master-detail layout for the application, hosting the dynamic content switching and universal sidebar.

## UI Layout
- **Scaffold**: Uses a global `theme.surfaceColor` for its background.
- **SideMenu (Master)**: A persistent vertical navigation sidebar on the left.
- **Content Area (Detail)**: A centered card with a **24px** corner radius (`ClipRRect`), holding the active feature sub-pages.

## Navigation System
The `HomePage` is built as a reactive `ConsumerWidget` that watches the `selectedMenuProvider`. 

### Page Indexing (Indices 0-4)
1.  **WorkfilePage (0)**: Job site selection and GeoJSON management.
2.  **DashboardPage (1)**: Telemetry gauges, GNSS health, and bucket position visualization.
3.  **TimesheetPage (2)**: Activity logging, duration tracking, and productivity analysis.
4.  **AlarmPage (3)**: Voice-to-Text logs, system warnings, and error history.
5.  **SetupPage (4)**: Configuration gateway for Calibration, Radio, Wireless, and Management.

## Post-Login Initialization
Upon successful authentication and redirection to the `HomePage`, the system performs a final connectivity check:
- **Redundant Auto-Connect**: Attempts to ensure a stable handshake with **CP2102N**.
- **Connectivity Notification**: Displays a green `SnackBar` ("Device connected: USB Device") if the RS232 handshake is confirmed.
- **Theme Propagation**: The `HomePage` acts as the root provider of the `AppTheme` for all navigated sub-pages.
