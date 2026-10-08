---
name: project-scaffolding
description: >
  Scaffolds new production-grade applications from scratch across Flutter,
  React/Next.js, Vue/Nuxt, React Native, and SwiftUI. Use when starting a
  new project, selecting architecture/libraries, initializing theme tokens,
  or verifying project setup checklist. Triggers on "create new project",
  "scaffold app", "setup Flutter project", "bootstrap", "init project".
---

# Universal Project Scaffolding Skill

This skill guides AI agents and engineers in scaffolding, bootstrapping, and constructing complete, production-grade applications from scratch across **Mobile**, **Tablet**, **Web**, and **Desktop** environments.

It provides a universal architectural blueprint adaptable to **Flutter**, **React / Next.js**, **Vue / Nuxt**, **React Native**, **SvelteKit**, or **SwiftUI**.

---

## 1. When to Use (Trigger Table & Scope Boundaries)

| User Request Example | In Scope? | Action / Destination |
|---|---|---|
| *"Scaffold a new Flutter application for industrial excavator guidance"* | **YES** | Follow 6-step pipeline; consult `references/dependency.md` |
| *"Setup a new Next.js dashboard project with Tailwind and Zustand"* | **YES** | Use framework translation tables in `references/framework-translation.md` |
| *"Verify project architecture against the scaffolding checklist"* | **YES** | Audit using `references/scaffolding-checklist.md` |
| *"Add a new button or dialog to the existing Dashboard page"* | **NO** | Hand off to `app-ui-specification` |
| *"Debug RS232 binary protocol framing or OpCodes"* | **NO** | Hand off to `command-protocol` |
| *"Configure USB serial port connection watchdog"* | **NO** | Hand off to `transport-operations` |

---

## 2. Skill Architecture

```
.agents/skills/project-scaffolding/
├── SKILL.md
└── references/
    ├── framework-translation.md  # Token & component mapping across Flutter/React/Vue/RN/SwiftUI
    ├── dependency.md             # Pinned package ecosystem standard (MapLibre, Isar, Riverpod)
    └── scaffolding-checklist.md  # Step-by-step verification checklist for new repositories
```

---

## 3. The 6-Step Universal Execution Pipeline

When instructed to create or scaffold a new application, follow this systematic 6-step lifecycle:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   UNIVERSAL PROJECT CREATION PIPELINE                  │
├─────────────────┬──────────────────┬─────────────────┬─────────────────┤
│ STEP 1          │ STEP 2           │ STEP 3          │ STEP 4          │
│ Framework &     │ Design Token     │ Data Models &   │ Component       │
│ Platform Target │ Theme Binding    │ State Scaffolding│ Library Build  │
├─────────────────┴──────────────────┼─────────────────┴─────────────────┤
│ STEP 5                             │ STEP 6                            │
│ Screen Implementation & Wiring     │ Hardware & Accessibility QA       │
└────────────────────────────────────┴───────────────────────────────────┘
```

### Step 1: Framework & Platform Discovery
1. Identify target platforms (Mobile iOS/Android, Industrial Cab Tablet, Web Browser, Desktop).
2. Confirm chosen framework (Flutter, React, Vue, RN, Svelte, SwiftUI).
3. Establish directory structure:
   ```
   lib/ (or src/)
   ├── core/
   │   ├── utils/       # Theme, dialog utilities, formatters
   │   ├── widgets/     # Global AppBar, status badges, icons
   │   └── services/    # ComService, Repository, Storage
   └── features/
       └── [name]/
           ├── pages/
           ├── presenter/
           └── widgets/
   ```
4. Resolve package dependencies using `references/dependency.md`.

### Step 2: Design Token & Theme System Initialization
Translate design tokens into the target framework engine using `references/framework-translation.md`:
- **Flutter**: `lib/core/utils/app_theme.dart` (`AppThemeData` const class + `AppTheme.of(context)`).
- **React / Next.js**: `tailwind.config.ts` or CSS Custom Properties (`--page-bg: #0D1118`).
- **Vue / Nuxt**: Pinia store + CSS variables.

### Step 3: Data Models & Presentation Logic Scaffolding
- Define domain models (`Person`, `Equipment`, `WorkFile`, `WorkingSpot`, `TimesheetRecord`).
- Timestamps stored in **seconds** (`int`).
- State stores follow Thin UI / Presenter patterns (`Notifier<T>` in Riverpod, `create<T>` in Zustand).

### Step 4: Component Library Construction
Scaffold atomic/molecule components matching target specifications:
- Header / AppBar (40×40 IconBox, 18px Title, 10px Subtitle).
- Multi-modal status badges.
- Metric cards (`SummaryCard` with circular percent rings).
- Form controls (`SCADATextField`, `SCADASwitchTile`, `SCADASlider`).

### Step 5: Screen Implementation & View Wiring
Implement feature screens using layout grids:
- Standard Single-View (Scaffold + AppBar + Scrollable Body).
- Multi-Tab Parent Page (`DefaultTabController`).
- Industrial Calibration (3:1 Grid Rule: 3/4 visualizer + 1/4 parameters).
- Responsive Collection Grid (`maxCrossAxisExtent: 380px`).

### Step 6: Hardware & Accessibility QA Checklist
- Touch targets $\ge 48\times48\text{ px}$.
- Angle capping at $360.00^\circ$.
- Multi-modal redundancy (never color alone).
- `cursor: pointer` on Web.
- Zero analysis errors (`flutter analyze`, ESLint).

---

## 4. Mandatory Safety & Domain Guardrails

1. **Thin UI Mandate**: No SQL queries, inline timers, or hardware serial commands inside UI component render functions.
2. **Mode Isolation Guardrail (SPOT vs CRUMBLING)**: SPOT mode logic and CRUMBLING mode logic must remain strictly partitioned.
3. **Platform Channel Isolation**: Hardware-specific libraries (`usb_serial`, `dart:io`) must be wrapped behind abstractions so the application compiles cleanly on Flutter Web and browser simulators.
4. **Zero-Warning Code Quality**: Generated code must pass static analysis with zero errors.

---

## 5. Related Skills & Hand-Off Rules

| Task Domain | Peer Skill | Hand-Off Trigger / Rule |
|---|---|---|
| **Per-Screen Editing & Spec** | `app-ui-specification` | Hand off once project skeleton is built for documenting and modifying individual screens. |
| **Hardware Framing & OpCodes** | `command-protocol` | Hand off when implementing binary serialization routines. |
| **Serial & Transport Drivers** | `transport-operations` | Hand off when configuring USB OTG serial connections and reconnection loops. |
| **Response Payloads & Sync** | `response-preparation` | Hand off when building REST sync endpoints or export log formatters. |
