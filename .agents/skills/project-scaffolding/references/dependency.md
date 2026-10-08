# Flutter Package & Dependency Specification (dependency.md)

> **Toho EGS & Industrial SCADA Ecosystem**  
> **Source Baseline**: Production Verified Package Manifest  
> **Skill Knowledge Path**: `references/dependency.md`  
> **Target Framework**: Flutter (Dart SDK `^3.10.0` or higher)

---

## 1. Overview & Architectural Philosophy

When **Flutter** is selected as the application framework, AI agents and software engineers **MUST NOT** guess or use arbitrary third-party packages. Industrial field systems, excavator guidance tablets, and heavy-duty SCADA interfaces require battle-tested, high-performance, and offline-resilient libraries.

This specification serves as the **official package standard** for scaffolding Flutter applications. It defines mandatory packages, verified versions, architectural rationale, and implementation guidelines grouped by functional domain.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   FLUTTER CORE DEPENDENCY ARCHITECTURE                 │
├──────────────────┬──────────────────┬─────────────────┬────────────────┤
│ 1. GIS & MAPS    │ 2. LOCAL DB      │ 3. STATE & MVVM │ 4. HARDWARE    │
│    maplibre      │  isar_community  │ flutter_riverpod│   usb_serial   │
├──────────────────┼──────────────────┼─────────────────┼────────────────┤
│ 5. VISUALIZATION │ 6. VOICE & AUDIO │ 7. NETWORKING   │ 8. SYSTEM & OS │
│  fl_chart,       │ porcupine, stt,  │ web_socket,     │ permission_    │
│  percent_indic.  │ tts, voice_proc  │ network_info    │ handler, path  │
└──────────────────┴──────────────────┴─────────────────┴────────────────┘
```

---

## 2. Domain-by-Domain Package Directory

### 2.1 Geospatial, GIS & Mapping
*For field boundary display, real-time machine positioning, bucket trajectory, and digital elevation models.*

| Package | Version | Purpose & Description |
|---|---|---|
| **`maplibre`** | `^0.3.3` | Hardware-accelerated (OpenGL/Vulkan) vector tile map rendering, offline tile styles, GeoJSON data overlays, dynamic camera manipulation. |

- **Selection Rationale**:
  - **100% Open-Source & Self-Contained**: Does not require proprietary Google Maps or Mapbox API keys or telemetry phone-home.
  - **Offline Vector Capability**: Essential for remote mining sites and construction quarries without cellular connectivity. Supports local style JSON (`assets/map_styles/style.json`) and local vector MBTiles.
  - **High-Performance Overlays**: Renders GeoJSON line layers (guidance paths), polygon fill layers (work areas), and symbol layers (working spots) smoothly at 60 FPS.
- **Architectural Rules**:
  - The map controller must be encapsulated inside `MapPresenter`.
  - UI widgets must only listen to coordinates and guidance bar offsets produced by the presenter; never calculate geospatial coordinates inline in widget state.

---

### 2.2 Local Database & Offline-First Persistence
*For zero-latency local caching, shift timesheets, operator records, and dense spot telemetry.*

| Package | Type | Version | Purpose & Description |
|---|---|---|---|
| **`isar_community`** | Dependency | `3.3.0-dev.3` | Ultra-fast NoSQL local database engine built in C++ with native Dart bindings. |
| **`isar_community_flutter_libs`** | Dependency | `3.3.0-dev.3` | Precompiled native binaries for Android, iOS, Windows, macOS, and Linux. |
| **`isar_community_generator`** | Dev Dependency | `3.3.0-dev.3` | Code generator for strongly-typed Isar schemas (`*.g.dart`). |
| **`build_runner`** | Dev Dependency | `^2.4.9` | Automated Dart code generation compiler. |

- **Selection Rationale**:
  - **Synchronous & Asynchronous Reads**: Provides lightning-fast reads without JSON decoding overhead.
  - **Rich Indexing**: Supports composite indices across `workfileId`, `status`, and `startTime`.
  - **Offline-First Guarantee**: All operator actions (spot completion, shift logging) are committed locally to Isar first before dispatching to the cloud sync queue.
- **Architectural Rules**:
  - Store all entity timestamps as **Unix Epoch Seconds** (`int`), not milliseconds.
  - When updating records, always retain the entity's existing `id` to avoid creating duplicate records.
  - Never run raw Isar queries directly in UI widgets. Wrap queries in Riverpod `StreamProvider` or Presenter repositories.

---

### 2.3 State Management & MVVM Presenter Pattern
*For testable business logic, reactive view binding, and strict separation of concerns.*

| Package | Version | Purpose & Description |
|---|---|---|
| **`flutter_riverpod`** | `^3.2.1` | Compile-time safe, declarative dependency injection and reactive state management framework. |

- **Selection Rationale**:
  - Eliminates `BuildContext` dependency for presenters and business services.
  - Immune to widget lifecycle memory leaks; provides explicit provider destruction lifecycle (`ref.onDispose`).
  - Supports immutable state representations with `Notifier<T>` / `AsyncNotifier<T>` and `state.copyWith()`.
- **Architectural Rules**:
  - Every page or major feature must have a dedicated Presenter extending `Notifier<T>` or `AsyncNotifier<T>`.
  - UI widgets must remain thin (`ConsumerWidget` or `ConsumerStatefulWidget`).
  - **Safety Rule**: Never invoke synchronous mutations of another provider inside `onDispose()`. Wrap teardowns in `Future.microtask(() => ...);`.

---

### 2.4 Hardware Interfaces & Serial / USB Communication
*For reading GNSS rovers, IMU inclination sensors, and excavator telemetry via RS232 / USB-OTG.*

| Package | Version | Purpose & Description |
|---|---|---|
| **`usb_serial`** | `^0.5.2` | Native Android USB-OTG CDC-ACM / FTDI / CH340 / CP210x serial communication driver. |

- **Selection Rationale**:
  - Direct communication with serial hardware without requiring OS root access.
  - Supports standard baud rates (e.g. 115200 bps) and binary streaming.
- **Architectural Rules**:
  - **Abstraction Wrapper**: Hardware-bound serial logic must be isolated behind an abstract interface (`ComService`).
  - **Web / Simulation Portability**: When compiling for Web (`kIsWeb`) or simulator, fallback automatically to a mock telemetry stream generator so the UI can be previewed without physical hardware.
  - **Packet Framing**: Packets must be validated against header bytes (`0xAA 0x55`), OpCodes (`0xD0`, `0xD1`, `0x53`), and CRC-16 checksums before updating state.

---

### 2.5 Real-Time Communication & Cloud Synchronization
*For bi-directional fleet dispatch, connection awareness, and cloud backup.*

| Package | Version | Purpose & Description |
|---|---|---|
| **`web_socket_channel`** | `^3.0.3` | Cross-platform bi-directional WebSocket client for live telemetry streaming. |
| **`network_info_plus`** | `^7.0.0` | Wi-Fi network detection, SSID, BSSID, and local IP address lookup. |

- **Selection Rationale**:
  - Low-latency bi-directional push notifications from central dispatch control.
  - Automatic detection of local Wi-Fi connection state to trigger offline queue flushing.
- **Sync Protocol**:
  - Cloud synchronization uses idempotent REST endpoints (`POST /api/v1/sync/...`) with unique client record UUIDs to prevent duplicates.

---

### 2.6 Charts, Metrics & KPI Visualization
*For shift productivity analytics, hour meter tracking, depth deviation bars, and gauges.*

| Package | Version | Purpose & Description |
|---|---|---|
| **`fl_chart`** | `^1.1.1` | Highly customizable, hardware-accelerated Flutter charts (Line, Bar, Pie, Scatter). |
| **`percent_indicator`** | `^4.2.5` | Circular progress rings and linear progress bars for target depth and shift quotas. |

- **Usage Standard**:
  - Use `fl_chart` for historical productivity curves (Spots per Hour, excavation elevation profile).
  - Use `percent_indicator` for circular status gauges (e.g. `CircularPercentIndicator` for Depth % and Shift Time remaining).

---

### 2.7 Voice Interaction & Auditory Feedback
*For hands-free excavator cab operation and critical auditory safety alerts.*

| Package | Version | Purpose & Description |
|---|---|---|
| **`porcupine_flutter`** | `^4.0.0` | Edge on-device wake-word detection engine (low latency, zero internet required). |
| **`speech_to_text`** | `^7.3.0` | Speech recognition library converting operator verbal commands into text strings. |
| **`flutter_tts`** | `^4.2.5` | Text-to-Speech synthesis for spoken alarms ("Depth Reached", "RTK Float Warning"). |
| **`flutter_voice_processor`**| `^1.1.2` | High-performance audio recording and buffer management for edge voice recognition. |

- **Usage Standard**:
  - Allows the operator to trigger recalibration or change targets verbally without removing hands from machine joysticks.
  - Spoken safety alerts supplement visual SCADA badges (multi-modal accessibility standard).

---

### 2.8 Media, Documents & Vector Graphics
*For crisp SCADA iconography, equipment manuals, tutorial playback, and markdown SOPs.*

| Package | Version | Purpose & Description |
|---|---|---|
| **`flutter_svg`** | `^2.2.4` | Vector SVG rendering for resolution-independent icons and machine schematics. |
| **`video_player`** | `^2.8.2` | Video player plugin for embedded operator tutorial clips and training SOPs. |
| **`video_thumbnail`** | `^0.5.3` | Instant video frame thumbnail generation for training video catalogues. |
| **`flutter_pdfview`** | `^1.3.2` | Native PDF viewer for in-cab equipment operation manuals and electrical diagrams. |
| **`flutter_markdown`** | `^0.6.18+4` | Renders rich text release notes, SOP documents, and shift handoff reports. |

---

### 2.9 System Permissions, Device Metadata & Filesystem
*For Android OS integration, runtime permissions, storage access, and USB flash drive import/export.*

| Package | Version | Purpose & Description |
|---|---|---|
| **`permission_handler`** | `^11.3.0` | Unified runtime permission manager for Android/iOS (USB, Storage, Location, Mic). |
| **`device_info_plus`** | `^10.1.0` | Device hardware details (Android tablet serial number, brand, model, OS SDK). |
| **`package_info_plus`** | `^8.0.0` | Application metadata retrieval (version number, build number, package identifier). |
| **`path_provider`** | `^2.1.5` | Resolves standard OS directories (Documents, Cache, Downloads, External Storage). |
| **`path`** | `^1.8.3` | Cross-platform filesystem path manipulation (joining, normalization, basenames). |
| **`file_picker`** | `^10.3.10` | Native file browser dialog to import/export LandXML, DXF, GeoJSON, and CSV files. |

---

### 2.10 Localization, Formatting & Icons
*For internationalization, number formatting, and standard icon fonts.*

| Package | Version | Purpose & Description |
|---|---|---|
| **`intl`** | `^0.20.2` | Internationalization and localization (date, time, number, currency formatting). |
| **`cupertino_icons`** | `^1.0.8` | Cupertino iOS style icons complementary to standard Material Icons. |

---

### 2.11 Development, Linting & Build Tools
*For code quality, automated testing, and release artifact generation.*

| Package | Type | Version | Purpose & Description |
|---|---|---|---|
| **`flutter_lints`** | Dev | `^3.0.0` | Official Flutter recommended linting rules to enforce clean code standards. |
| **`analyzer`** | Dev | `8.0.0` | Static analysis engine for Dart code. |
| **`flutter_launcher_icons`**| Dev | `^0.14.4` | Automated generation of adaptive app icons for Android launcher and iOS springboard. |

---

## 3. Master `pubspec.yaml` Template

When scaffolding a new Flutter project or standardizing an existing one, use this validated `pubspec.yaml` manifest:

```yaml
name: toho_egs
description: "High-Performance Industrial SCADA & Excavator Guidance System"
publish_to: 'none'

version: 4.2.20+90

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter

  # UI & Visual Styling
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.2.4

  # State Management & MVVM Architecture
  flutter_riverpod: ^3.2.1

  # Local Persistence & Offline-First DB
  isar_community: 3.3.0-dev.3
  isar_community_flutter_libs: 3.3.0-dev.3

  # Mapping & Geospatial Engine
  maplibre: ^0.3.3

  # Data Visualization & Charts
  fl_chart: ^1.1.1
  percent_indicator: ^4.2.5

  # Formatting & Localization
  intl: ^0.20.2

  # Hardware Communication (RS232 / USB OTG)
  usb_serial: ^0.5.2

  # Device Hardware, Permissions & Filesystem
  permission_handler: ^11.3.0
  device_info_plus: ^10.1.0
  package_info_plus: ^8.0.0
  path_provider: ^2.1.5
  path: ^1.8.3
  file_picker: ^10.3.10

  # Networking & Real-time Communications
  web_socket_channel: ^3.0.3
  network_info_plus: ^7.0.0

  # Voice Interaction & Audio Processing
  speech_to_text: ^7.3.0
  porcupine_flutter: ^4.0.0
  flutter_tts: ^4.2.5
  flutter_voice_processor: ^1.1.2

  # Media Playback & Document Viewers
  video_player: ^2.8.2
  video_thumbnail: ^0.5.3
  flutter_pdfview: ^1.3.2
  flutter_markdown: ^0.6.18+4

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^3.0.0
  build_runner: ^2.4.9
  isar_community_generator: 3.3.0-dev.3
  analyzer: 8.0.0
  flutter_launcher_icons: ^0.14.4

flutter:
  uses-material-design: true

  assets:
    - assets/
    - assets/map_styles/
    - images/
    - images/sensor/
```

---

## 4. Package Selection Decision Matrix & Anti-Patterns

When designing modules, adhere strictly to these architectural selection rules:

```
┌────────────────────────┬───────────────────────────┬──────────────────────────────────┐
│ DOMAIN REQUIREMENT     │ RECOMMENDED STANDARD      │ PROHIBITED / ANTI-PATTERN        │
├────────────────────────┼───────────────────────────┼──────────────────────────────────┤
│ GIS / Vector Map       │ maplibre                  │ google_maps_flutter, mapbox_gl   │
│                        │ (No API token, offline)   │ (Paid API keys, strict telemetry)│
├────────────────────────┼───────────────────────────┼──────────────────────────────────┤
│ Local Persistence      │ isar_community            │ sqflite (slow SQL boilerplate),  │
│                        │ (Zero-copy, C++ engine)   │ shared_preferences (no query/idx)│
├────────────────────────┼───────────────────────────┼──────────────────────────────────┤
│ State Management       │ flutter_riverpod          │ get_x (bypasses Flutter tree),   │
│                        │ (Compile-safe, testable)  │ provider (context-coupled)       │
├────────────────────────┼───────────────────────────┼──────────────────────────────────┤
│ USB / RS232 Hardware   │ usb_serial + ComService   │ Direct raw platform channels     │
│                        │ (Mockable on Web/Desktop) │ with zero abstraction layer      │
├────────────────────────┼───────────────────────────┼──────────────────────────────────┤
│ Telemetry Charts       │ fl_chart                  │ syncfusion_flutter_charts        │
│                        │ (Lightweight, open)       │ (Commercial licensing lock-in)   │
└────────────────────────┴───────────────────────────┴──────────────────────────────────┘
```

---

## 5. Universal Cross-Framework Mapping Matrix

Because the specification supports multiple frontend frameworks, this cross-reference matrix guides developers migrating or porting features across platforms:

| Architectural Domain | **Flutter Standard** | **React / Next.js** | **Vue / Nuxt** | **React Native** |
|---|---|---|---|---|
| **State Management** | `flutter_riverpod` | `zustand` / `tanstack-query` | `pinia` | `zustand` / `recoil` |
| **GIS & Vector Map** | `maplibre` | `maplibre-gl` | `maplibre-gl` | `@maplibre/maplibre-react-native` |
| **Local Database** | `isar_community` | `dexie` (IndexedDB) / `rxdb`| `dexie` / `pinia-orm` | `watermelondb` / `@op-engineering/op-sqlite` |
| **Data Visualization**| `fl_chart` | `recharts` / `chart.js` | `chart.js` / `echarts` | `react-native-gifted-charts` |
| **Real-Time Stream** | `web_socket_channel` | Native `WebSocket` / `socket.io` | `socket.io-client` | Native `WebSocket` |
| **Vector Icons** | `flutter_svg` | `lucide-react` / `@svgr` | `lucide-vue-next` | `react-native-svg` |
| **Hardware Serial** | `usb_serial` | Web Serial API (`navigator.serial`)| Web Serial API | `react-native-serialport` |
