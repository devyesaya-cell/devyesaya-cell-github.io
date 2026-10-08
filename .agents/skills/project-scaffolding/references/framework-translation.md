# Cross-Framework Translation Guide (framework-translation.md)

> **Scope**: Translation of tokens, grid rules, angle capping, and state stores across Flutter, React/Next.js, Vue/Nuxt, React Native, and SwiftUI.

---

## 1. Design Tokens Translation

| Token Name | Dark SCADA Hex | Flutter (`AppTheme`) | Tailwind / Next.js | CSS Custom Property |
|---|---|---|---|---|
| `pageBackground` | `0xFF0D1118` | `theme.pageBackground` | `bg-[#0D1118]` | `--page-bg: #0D1118;` |
| `cardSurface` | `0xFF1A2235` | `theme.cardSurface` | `bg-[#1A2235]` | `--card-surface: #1A2235;` |
| `cardBorder` | `0xFF2A3750` | `theme.cardBorder` | `border-[#2A3750]` | `--card-border: #2A3750;` |
| `appBarAccent` | `0xFF00BCD4` | `theme.appBarAccent` | `text-[#00BCD4]` | `--accent: #00BCD4;` |
| `textOnSurface` | `0xFFFFFFFF` | `theme.textOnSurface` | `text-white` | `--text-primary: #FFFFFF;` |
| `textSecondary` | `0xFF8A94A6` | `theme.textSecondary` | `text-[#8A94A6]` | `--text-secondary: #8A94A6;` |

---

## 2. 3:1 Calibration Grid Translation

- **Flutter**:
  ```dart
  Row(
    children: [
      Expanded(flex: 3, child: VisualizerWidget()),
      Expanded(flex: 1, child: ParameterStackWidget()),
    ],
  )
  ```
- **React / Web CSS**:
  ```tsx
  <div className="grid grid-cols-4 gap-4 h-full">
    <div className="col-span-3">{/* Visualizer */}</div>
    <div className="col-span-1">{/* Parameter Stack */}</div>
  </div>
  ```
- **React Native**:
  ```tsx
  <View style={{ flexDirection: 'row', flex: 1 }}>
    <View style={{ flex: 3 }}>{/* Visualizer */}</View>
    <View style={{ flex: 1 }}>{/* Parameter Stack */}</View>
  </View>
  ```

---

## 3. Angle Capping Translation

Angular machine telemetry must always visually cap at $360.00^\circ$:
- **Dart (Flutter)**: `(val > 360 ? 360.0 : val).toStringAsFixed(2) + '°'`
- **TypeScript (React/Vue/RN)**: `${(val > 360 ? 360 : val).toFixed(2)}°`
- **Swift (SwiftUI)**: `String(format: "%.2f°", min(val, 360.0))`

---

## 4. State Management Library Translation

| Framework | State Library | Idiomatic Pattern |
|---|---|---|
| **Flutter** | Riverpod 3 | `Notifier<State>` + immutable state + `copyWith` |
| **React / Next.js** | Zustand / TanStack | `create<State>()((set, get) => ({ ... }))` |
| **Vue 3 / Nuxt** | Pinia | `defineStore('feature', { state: () => ({ ... }), actions: { ... } })` |
| **Svelte 5** | Runes | `$state({ ... })` |
| **SwiftUI** | Observation | `@Observable class FeatureViewModel { ... }` |
