---
name: response-preparation
description: >
  Constructs, formats, and validates system responses, telemetry DTOs,
  audit log files, and local configuration I/O. Use when formatting API
  responses, serializing database records for export, generating shift
  reports, or managing config file persistence. Triggers on "format response",
  "export logs", "save config", "generate report", "sync payload".
---

# Response Preparation Specification Skill

This skill governs data transfer object (DTO) formatting, REST/WebSocket serialization, JSON sync payload assembly, structured audit logging, and resilient local configuration file I/O.

---

## 1. When to Use (Trigger Table & Scope Boundaries)

| User Request Example | In Scope? | Action / Destination |
|---|---|---|
| *"Format the timesheet export payload for POST /api/v1/sync/timesheets"* | **YES** | Consult `references/response-types.md` |
| *"Format shift error and warning events into the structured audit log"* | **YES** | Follow schema in `references/log-format.md` |
| *"Save application calibration configuration safely to local JSON file"* | **YES** | Use atomic write protocol in `references/config-io.md` |
| *"Parse RS232 0xAA 0x55 binary packets"* | **NO** | Hand off to `command-protocol` |
| *"Manage USB serial port connection or reconnection loops"* | **NO** | Hand off to `transport-operations` |
| *"Design UI cards to display productivity stats"* | **NO** | Hand off to `app-ui-specification` |

---

## 2. Skill Architecture

```
.agents/skills/response-preparation/
├── SKILL.md
└── references/
    ├── response-types.md  # JSON DTOs, sync payloads, ACK response schemas
    ├── log-format.md      # Structured audit trail formats, ISO8601 timestamps
    └── config-io.md       # Atomic JSON configuration serialization and file locks
```

---

## 3. Offline-First Cloud Synchronization Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                        OFFLINE-FIRST SYNC FLOW                         │
├──────────────────────────────────┬─────────────────────────────────────┤
│ 1. LOCAL PERSISTENCE FIRST       │ 2. SYNC QUEUE DISPATCH              │
│ - Operator completes spot/shift  │ - Connectivity detector triggers    │
│ - Instant write to local DB      │ - Batches records (JSON payload)    │
├──────────────────────────────────┼─────────────────────────────────────┤
│ 3. IDEMPOTENT REST ENDPOINTS     │ 4. WEBSOCKET REAL-TIME DISPATCH     │
│ - Unique record UUIDs            │ - Bi-directional fleet updates      │
│ - Server merges without duplicate│ - Real-time excavator cab location  │
└──────────────────────────────────┴─────────────────────────────────────┘
```

---

## 4. Tooling & MCP Integration

| MCP Resource | Usage in Response Preparation |
|---|---|
| Filesystem MCP | Safely read and write scoped configuration files, cached shift logs, and mock sync responses without arbitrary disk traversal. |
| `db://schema` | Validate entity fields against database schemas before assembling DTO representations. |

---

## 5. Related Skills & Hand-Off Rules

| Task Domain | Peer Skill | Hand-Off Trigger / Rule |
|---|---|---|
| **Hardware Framing** | `command-protocol` | Hand off when converting raw telemetry bytes into domain records. |
| **Network State** | `transport-operations` | Hand off to check if cellular or WiFi link is active before triggering sync. |
| **UI Notification** | `app-ui-specification` | Hand off sync progress and completion events to update UI badges and snackbars. |
