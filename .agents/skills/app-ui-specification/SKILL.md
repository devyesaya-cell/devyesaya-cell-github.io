---
name: app-ui-specification
description: >
  Documents, audits, and modifies UI screens for the mobile and web app.
  Use when creating a screen, changing layout, labels, buttons, menus,
  data display, or screen states, or when debugging a UI interaction.
  Triggers on "add a button", "change the label", "document this screen",
  "why doesn't this screen", "what happens when I click", or any request
  involving a specific screen, widget, or user-facing interaction.
---

# App UI Specification & Screen Design Skill

This skill guides AI agents and engineers in documenting, designing, auditing, and implementing production-grade user interfaces across **Mobile**, **Tablet**, **Web**, and **Desktop** environments.

It enforces a strict per-screen editing contract based on design tokens, structured component props, thin UI architecture, and domain-specific accessibility standards.

---

## 1. When to Use (Trigger Table & Scope Boundaries)

Use this table to determine whether a user request belongs in this skill or must be handed off to a peer skill:

| User Request Example | In Scope? | Action / Destination |
|---|---|---|
| *"Add a confirmation dialog to the delete button on Person tab"* | **YES** | Read `screens/person_tab.md`, `references/components.md`; update UI spec & widget |
| *"Change the label and color of the precision card on the dashboard"* | **YES** | Read `screens/dashboard_detail.md`, `references/theme.md`; update spec & card |
| *"Document the new boom sensor calibration screen"* | **YES** | Copy `screens/_TEMPLATE.md`; fill out all 11 sections |
| *"Why doesn't the save button disable when loading?"* | **YES** | Consult `references/interactions.md` thin UI contract; audit presenter state binding |
| *"What happens when I click the mode toggle button?"* | **YES** | Consult `references/interactions.md` and `screens/[screen].md` event flow |
| *"Audit the screen for gloved touch target and color contrast compliance"* | **YES** | Verify against `references/accessibility.md` checklist |
| *"Add a new RS232 command opcode (e.g. 0x54) to the protocol"* | **NO** | Hand off to `command-protocol` |
| *"Fix USB serial disconnection drops and auto-reconnect logic"* | **NO** | Hand off to `transport-operations` |
| *"Format shift productivity JSON payload for cloud synchronization"* | **NO** | Hand off to `response-preparation` |
| *"Scaffold a completely new application from scratch with Riverpod & Isar"* | **NO** | Hand off to `project-scaffolding` |

---

## 2. Skill Architecture & Harness Portability

### 2.1 Harness Path Portability
- **Google Antigravity IDE**: Discovers `.agents/skills/` as the native workspace customization root.
- **Claude Code & DeepSeek Harness**: Discovers `.claude/skills/`.
- A directory junction (`.claude <<===>> .agents`) is maintained in the workspace root, guaranteeing 100% path resolution and zero configuration drift across both environments.

### 2.2 Directory Layout
```
.agents/skills/app-ui-specification/ (or .claude/skills/app-ui-specification/)
├── references/          # Core Design System, Component Tokens, Interactions & Guidelines
│   ├── theme.md         # Dual-theme color tokens (Dark/Light SCADA), surfaces, borders
│   ├── components.md    # Structured component props tables, web compatibility SOP
│   ├── interactions.md  # State contracts, event naming, error classification, debouncing
│   ├── data_models.md   # Domain entities (Person, WorkFile, Spots), schemas
│   ├── dependency.md    # Verified package ecosystem standard (Riverpod, Isar, MapLibre)
│   ├── accessibility.md # Gloved touch targets, contrast ratios, multi-modal redundancy
│   ├── migration-guide.md # 5-phase reverse-documentation & modernization workflow
│   └── screen-template.md # Single Source of Truth for the 11-section specification standard
│
├── screens/             # Concrete Screen Layouts & Feature Blueprints
│   ├── _TEMPLATE.md     # Ready-to-copy 11-section blueprint (derived from screen-template.md)
│   ├── login_page.md    # Authentication, operator identity, mode selector
│   ├── home_page.md     # Main application shell & navigation wrapper
│   ├── side_menu.md     # Responsive navigation drawer & live cab clock
│   ├── dashboard_detail.md # KPI metrics, progress rings, historical trend charts
│   ├── map_detail.md    # Real-time GIS map, bucket kinematics, guidance bars
│   ├── map_dialogs.md   # Configuration modals, target depth, crumbling settings
│   ├── area_tab.md      # Geographic site boundary management
│   ├── equipment_tab.md # Fleet and excavator equipment inventory
│   └── ...              # Additional feature screen specifications
│
└── src/                 # Business Logic, State Stores & Presentation Layer (Presenters)
    ├── dashboard_presenter.md # KPI computation, trend aggregation, session productivity
    ├── map_presenter.md       # Real-time coordinate translation, kinematics, LoD rendering
    ├── workfile_presenter.md  # Job file parsing, spot status mutations, Isar persistence
    └── management_detail.md   # CRUD transactions, contractor & equipment domain logic
```

### 2.3 Template Relationship & Source of Truth
- **`references/screen-template.md`**: The **Single Source of Truth** for the 11-section specification contract, section definitions, and production implementation skeletons.
- **`screens/_TEMPLATE.md`**: The **clean, copy-paste ready blueprint** used when instantiating a new screen spec (`screens/[new_screen].md`). Any updates to the specification contract must be applied to `references/screen-template.md` first.

---

## 3. The 11-Section Screen Specification Contract

Every screen specification file inside `screens/` **MUST** adhere to the standard 11-section structure outlined in `screens/_TEMPLATE.md` and `references/screen-template.md`:

1. **Purpose**: Operational purpose, target user persona, workflow context, and operational mode (`SPOT`, `CRUMBLING`, or `SHARED`).
2. **Layout & Regions Table**: Visual widget tree, grid system selection (Single-view, 3:1 Grid, Tabbed, Responsive), and dimension/flex breakdown table.
3. **Menu Structure & Navigation**: Route path, entry points, AppBar actions, breadcrumbs, Back navigation rules, and `SideMenu` active item mapping.
4. **Components Used**: Catalog of design system widgets, design tokens consumed (`theme.pageBackground`, `theme.cardSurface`, etc.), and required props.
5. **Buttons & Clickable Elements**: Matrix of all interactive elements: Hitbox size ($\ge 48\times48\text{ px}$), trigger handlers (`on<Action>Pressed`), dispatched actions, target states, and disabled conditions.
6. **Data Display & Calculations**: All telemetry and data fields: Raw source, formatting, units, update frequency, and angle capping normalization ($\le 360.00^\circ$).
7. **Screen States**: Complete UI state matrix: `loading`, `normal` (active), `offline_stale` (watchdog alert), `error`, and `empty` states.
8. **Events & Side Effects**: Internal and external events using `domain:pastTense` naming, payload schemas, and imperative side effects handled via `ref.listen` (dialogs, snacks, audio alerts).
9. **Accessibility & Ergonomics**: Gloved touch target audit ($\ge 48\times48\text{ px}$), contrast verification ($\ge 4.5:1$ text, $\ge 7:1$ critical telemetry), multi-modal redundancy (icon + label), and `cursor: pointer`.
10. **Test Cases**: Verification scenarios covering theme switches, user action dispatches, hardware telemetry watchdog transitions, and window resize flex safety.
11. **Open Questions & Assumptions**: Open UX decisions, pending hardware calibrations, backend assumptions, and edge cases under review.

---

## 4. Interaction & State Conventions

To guarantee architectural consistency across all views:
1. **Thin UI Mandate**:
   - `ref.watch(provider)`: Used inside `build()` to trigger widget re-renders when state changes.
   - `ref.read(provider.notifier).action()`: Used inside event handlers (`onPressed`, `onTap`, callbacks) to dispatch user intent. **NEVER** use `ref.watch` inside callbacks.
   - `ref.listen(provider, (prev, next) { ... })`: Used inside `build()` to trigger imperative side-effects (e.g. showing a SnackBar, opening a dialog, playing audio alerts).
2. **Handler Naming Standards**:
   - Buttons: `on<Action>Pressed()` (e.g. `onSavePressed()`, `onDeleteConfirmed()`).
   - Inputs: `on<Field>Changed(val)` (e.g. `onSearchQueryChanged(String query)`).
   - Dialog Triggers: `on<Action>Requested()` before modal confirmation; `on<Action>Confirmed()` on approval.
3. **Event Naming & Payload Schemas**:
   - Emit notifications using lowercase colon notation: `auth:signedIn`, `workfile:selected`, `spot:completed`, `calibration:calibrated`.
   - Payload rules ($\le 5$ fields, epoch seconds timestamps, `Uint8List` for binary): see detailed schema rules in `references/interactions.md §3.2`.
4. **Error Classification & Response (`AppError`)**:
   - System errors are categorized into `NetworkError`, `HardwareError`, `ValidationError`, and `DatabaseError`.
   - For UI feedback mapping patterns (SnackBars vs dialogs vs field validation): see `references/interactions.md §3.3`.
5. **State Ownership & Debouncing**:
   - Single store ownership rules (Presenter owns view state, `ComService` owns link state): see `references/interactions.md §5.1`.
   - Debounce text inputs by **300ms**; throttle live telemetry widget refreshes to **10 Hz** (100ms).

---

## 5. Tooling & MCP Integration

When editing or validating screens, leverage available Model Context Protocol (MCP) resources for ground truth. Note that `db://` and `api://` resources represent direct MCP data sources, not peer skills:

| MCP Resource | Category | Usage in UI Specification |
|---|---|---|
| `serial://ports` | Hardware Link | Enumerate live USB/RS-232 serial ports, baud rates, and status for connection screens. |
| `ble://connections` | Hardware Link | Inspect active BLE GATT links and RSSI signal levels for peripheral pairing UI. |
| `wifi://status` | Network Link | Query WiFi link state, local IP address, and signal strength for connectivity badges. |
| `protocol://commands` | Command Registry | Verify command specifications when a screen triggers or references an OpCode. |
| `protocol://frames/recent` | Telemetry Buffer | Inspect recent parsed-frame buffer for real-time telemetry diagnostics and logs. |
| `db://schema` | Data Source | Inspect domain collections, entity fields, types, and primary keys before modifying UI fields. |
| `api://routes` | Data Source | Verify REST/WebSocket endpoints and sync payload structures for form submissions. |
| Scoped Filesystem MCP | Workspace I/O | Safely inspect local UI specification files, vector assets, and mock JSON fixtures. |

---

## 6. Progressive Disclosure Guide

To optimize context window usage and prevent loading unnecessary files, load only the specific reference files required for the task at hand:

| Task / Scenario | Required Reference Files to Load |
|---|---|
| **Create a new screen** | `screens/_TEMPLATE.md`, `references/components.md`, `references/theme.md`, one relevant example in `screens/` |
| **Modify a button or interactive element** | Target screen file in `screens/`, `references/components.md`, `references/interactions.md` |
| **Add a menu item or navigation tab** | Target screen file in `screens/`, `references/components.md`, `references/interactions.md` |
| **Audit accessibility or ergonomics** | Target screen file in `screens/`, `references/accessibility.md`, `references/theme.md` |
| **Debug UI state, stream, or event bug** | Target screen file in `screens/`, `references/interactions.md`, presenter file in `src/` |
| **Reverse-document legacy screen** | Target legacy screen code, `references/migration-guide.md`, `screens/_TEMPLATE.md` |

---

## 7. Legacy Migration Context

When the target screen exists in the legacy codebase (pre-v2 / monolithic Flutter code), follow the 5-phase workflow defined in `references/migration-guide.md`:

1. **Discovery**: Read legacy code via MCP or file view; catalog mutable state, database queries, and serial calls. Do NOT modify legacy code yet.
2. **Scaffold**: Create feature directory structure (`pages/`, `presenter/`, `widgets/`) and copy `screens/_TEMPLATE.md` to `screens/[name].md`.
3. **Reverse-Document**: Fill all 11 sections of `screens/[name].md` capturing the legacy screen's true behavior, state matrix, and data display.
4. **Validation**: Tokenize colors (`AppTheme`), decouple logic into Riverpod 3 Presenter, and verify static analysis (`flutter analyze`) with zero errors.
5. **Adoption**: Swap routing in `SideMenu` / navigation to point to the new thin `ConsumerWidget` and deprecate the old monolithic widget.

> [!IMPORTANT]
> **Golden Rule**: Never rewrite a legacy screen from scratch without reverse-documenting first. Always build the 11-section specification contract before implementing code.

---

## 8. Anti-Patterns & Prohibited Practices

Avoid these common implementation pitfalls:

| Prohibited Practice (Anti-Pattern) | Why It Fails | Mandatory Correct Pattern |
|---|---|---|
| ❌ **Inline database writes or HTTP calls in widgets** | Breaks thin UI separation; causes frame drops during build | Move writes to Presenter / Repository layer; UI only dispatches user intent. |
| ❌ **`ref.watch` inside callbacks (`onPressed`)** | Re-subscribes widget unnecessarily; leads to memory leaks | Use `ref.read(provider.notifier).action()` inside event callbacks. |
| ❌ **`ref.read` in `build()` for reactive state** | Widget will not re-render when state changes | Use `ref.watch(provider)` or `ref.watch(provider.select(...))` in `build()`. |
| ❌ **Hardcoded hex colors (`Color(0xFF1A2235)`)** | Breaks theme switching between Dark and Light SCADA | Consume tokens: `theme.pageBackground`, `theme.cardSurface`, etc. |
| ❌ **Button or link described only in narrative prose** | Ambiguous for automated testing; incomplete contract | Every interactive element must be an explicit row in the §5 table. |
| ❌ **Skipping screen states because "it's simple"** | Leaves edge cases unhandled when offline or loading | Always document all states in §7 (`loading`, `normal`, `offline_stale`, `error`, `empty`). |
| ❌ **Parsing RS-232 bytes or CRC-16 inside UI** | Pollutes UI layer with low-level protocol logic | Hand off to `command-protocol` and `transport-operations`. |

---

## 9. Output Format Standard

When delivering changes to a screen specification or UI code, structure the summary report as follows:

```markdown
### Summary
[One sentence summarizing what was added, modified, or audited]

### Files Changed / Created
- **Specification**: `screens/[screen_name].md`
- **Implementation**: `lib/features/[feature]/pages/[screen_name]_page.dart` (or `src/[screen_name]_presenter.md`)

### Spec Sections Updated
- **§2 Layout**: [Summary of layout changes]
- **§5 Buttons**: [New/modified interactive elements]
- **§8 Events & Side Effects**: [Dispatched events or ref.listen additions]
- **§9 Accessibility**: [Hitbox, contrast, or cursor updates]
- **§10 Test Cases**: [New test verification scenarios]

### Verification Checklist
- [x] Spec matches implementation code 1:1
- [x] All components listed in `references/components.md`
- [x] All colors resolved via `AppTheme` tokens (zero hardcoded hex)
- [x] Static analysis passes with zero warnings (`flutter analyze`)

### Open Questions / Next Steps
- [Any open questions or unresolved hardware constraints]
```

---

## 10. Mandatory Safety & Domain Guardrails

1. **Thin UI Mandate**: No SQL/database queries, inline timers, or hardware serial commands inside UI component render functions.
2. **Mode Isolation Guardrail (SPOT vs CRUMBLING)**: Logic belonging to specific modes (e.g. SPOT vs CRUMBLING) must remain strictly isolated. Shared service modifications require explicit developer confirmation.
3. **Platform Channel Isolation**: Hardware-specific libraries (`usb_serial`, `dart:io`) must be wrapped behind abstractions so the application compiles and runs seamlessly on Flutter Web and browser simulators.
4. **Zero-Warning Code Quality**: Generated code must pass static analysis (`flutter analyze`, ESLint, TypeScript compiler) with zero errors.

---

## 11. Related Skills & Hand-Off Rules

The UI specification skill focuses strictly on user-facing presentation and interaction contracts. Tasks crossing into lower architectural layers must be handed off to the 4 peer skills:

| Task Domain | Peer Skill | Hand-Off Trigger / Rule |
|---|---|---|
| **Binary RS232 Framing & OpCodes** | `command-protocol` | Hand off when defining byte layout, CRC-16 checks, OpCodes `0xD0`/`0xD1`/`0x53`. |
| **Physical Transport & Watchdog** | `transport-operations` | Hand off when managing USB OTG, baud rates, reconnection loops, or link dropout diagnostics. |
| **Response Building & Cloud Sync** | `response-preparation` | Hand off when crafting server sync payloads, shift logs, or config file serialization. |
| **Project Creation & Scaffolding** | `project-scaffolding` | Hand off when bootstrapping a new app from scratch or translating frameworks. |
