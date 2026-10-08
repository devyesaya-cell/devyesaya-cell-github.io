---
name: command-protocol
description: >
  Parses and generates RS-232 framed commands (0xAA 0x55, CRC-16, OpCodes
  0xD0/0xD1/0x53). Use when adding a command, debugging a malformed frame,
  changing a payload, validating CRC, or tracing a parse failure. Triggers
  on "command not recognized", "bad checksum", "frame format", "OpCode",
  "add a command", or any protocol-level task.
---

# Command Protocol Specification Skill

This skill defines the binary framing format, OpCode command registry, payload parsing rules, and CRC-16 validation standards for hardware communication between the application and machine controllers.

---

## 1. When to Use (Trigger Table & Scope Boundaries)

| User Request Example | In Scope? | Action / Destination |
|---|---|---|
| *"Add a new calibration trigger OpCode (0x54) to the registry"* | **YES** | Update `references/command-registry.md` and parser routines |
| *"Debug why the IMU frame is failing CRC-16 checksum validation"* | **YES** | Trace `references/frame-format.md` byte layout & CRC algorithm |
| *"Write unit tests for malformed packet handling"* | **YES** | Follow `references/protocol-tests.md` test matrix |
| *"What is the binary payload layout for OpCode 0xD0 (Rover GNSS)?"* | **YES** | Consult `references/frame-format.md` |
| *"Debug physical USB port disconnects / reconnection timing"* | **NO** | Hand off to `transport-operations` |
| *"Format timesheet JSON payload for cloud HTTP sync"* | **NO** | Hand off to `response-preparation` |
| *"Display satellite count on the navigation header"* | **NO** | Hand off to `app-ui-specification` |

---

## 2. Skill Architecture

```
.agents/skills/command-protocol/
├── SKILL.md
└── references/
    ├── frame-format.md     # 0xAA 0x55 binary frame layout, endianness, CRC-16 CCITT
    ├── command-registry.md # Complete OpCode directory (0xD0, 0xD1, 0xD3, 0x52, 0x53, 0x06)
    └── protocol-tests.md   # Packet validation test cases, fuzz frames, error fixtures
```

---

## 3. Binary Frame Format Overview

All serial frames adhere to a strict 6-part binary structure:

```
┌───────────┬───────────┬─────────┬──────────────┬──────────────┬───────────┐
│ HEADER 1  │ HEADER 2  │ OPCODE  │ PAYLOAD LEN  │ DATA BYTES   │ CRC-16    │
│ 0xAA      │ 0x55      │ 1 Byte  │ 1 Byte (N)   │ N Bytes      │ 2 Bytes   │
└───────────┴───────────┴─────────┴──────────────┴──────────────┴───────────┘
```

1. **Preamble**: Fixed 2-byte synchronization sequence `0xAA 0x55`.
2. **OpCode**: Single-byte operation code identifying the packet payload type.
3. **Payload Length**: Number of data bytes $N$ ($0 \le N \le 255$).
4. **Data Bytes**: $N$ bytes of structured telemetry or command arguments (Little-Endian standard).
5. **CRC-16**: 2-byte checksum computed over `[OPCODE, PAYLOAD_LEN, DATA_BYTES...]`.

---

## 4. Key OpCodes Summary

| OpCode | Name | Direction | Payload Description |
|---|---|---|---|
| `0xD0` | **Rover GNSS Telemetry** | Controller $\rightarrow$ App | Latitude, Longitude, Elevation, Track Heading, Satellites, Fix Quality. |
| `0xD1` | **IMU Sensor Telemetry** | Controller $\rightarrow$ App | Boom Pitch/Roll, Stick Pitch/Roll, Bucket Pitch/Roll, Raw Accelerometer axes. |
| `0xD3` | **Base Station Status** | Base $\rightarrow$ App | Battery voltage, Radio RSSI, Satellite count, Proximity distance. |
| `0x52` | **Calibration Trigger** | App $\rightarrow$ Controller | Mode byte (`2`: Boom Tilt, `21`: Boom Accelero, `61`/`66`: Reset Offset). |
| `0x53` | **Set Parameter Command**| App $\rightarrow$ Controller | Parameter Type byte (`0`: Boom Length, `10`: Boom Base H) + 4-byte Int32 value. |
| `0x06` | **Acknowledge (ACK)** | Controller $\rightarrow$ App | Command confirmation packet confirming OpCode execution. |

---

## 5. Tooling & MCP Integration

| MCP Resource | Usage in Command Protocol |
|---|---|
| `protocol://commands` | Query active registered command OpCodes, payload field types, and argument schemas. |
| `protocol://frames/recent` | Inspect recent raw hex binary frames received over serial/USB to diagnose checksum errors. |

---

## 6. Related Skills & Hand-Off Rules

| Task Domain | Peer Skill | Hand-Off Trigger / Rule |
|---|---|---|
| **Physical Link & Reconnection** | `transport-operations` | Physical USB/BLE connection state, baud rate negotiation, watchdog timers. |
| **UI Telemetry Display** | `app-ui-specification` | Rendering parsed values into telemetry cards, angle capping, widgets. |
| **Response Serialization** | `response-preparation` | Formatting serialized responses, logs, or JSON DTOs for cloud dispatch. |
