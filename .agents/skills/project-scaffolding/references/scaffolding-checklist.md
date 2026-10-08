# Project Scaffolding Verification Checklist (scaffolding-checklist.md)

> **Scope**: Readiness checklist for new repository initialization, directory structure validation, and dependency resolution.

---

## 1. Pre-Implementation Checklist

- [ ] **Directory Structure Initialized**:
  - `lib/core/utils/app_theme.dart` (Tokens and accessor)
  - `lib/core/widgets/global_app_bar_actions.dart` (Status badge & actions)
  - `lib/core/coms/com_service.dart` (Abstract serial/telemetry service)
  - `lib/core/repositories/app_repository.dart` (Isar DB transactions)
  - `lib/features/[name]/pages/`
  - `lib/features/[name]/presenter/`
  - `lib/features/[name]/widgets/`
- [ ] **Dependencies Pinned**: `pubspec.yaml` (or `package.json`) uses verified versions from `dependency.md`.
- [ ] **Code Generation Executed**: Ran `dart run build_runner build --delete-conflicting-outputs` for Isar schemas.
- [ ] **Platform Channel Isolation Verified**: No `dart:io` or native serial imports in UI widgets.
- [ ] **Mode Isolation Guardrail Applied**: SPOT and CRUMBLING modes separated in presenters and config.
- [ ] **Static Analysis Zero-Warning Pass**: `flutter analyze` passes with zero errors and zero warnings.
- [ ] **Dark & Light Mode Switch Checked**: Both SCADA themes legible with contrast $\ge 4.5:1$.
