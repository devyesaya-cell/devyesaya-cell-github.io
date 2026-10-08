---
name: transport-operations
description: >
  Manages physical and wireless transport channels (RS-232, USB Serial OTG,
  BLE, WiFi). Use when configuring serial baud rates, managing connection
  state machines, implementing auto-reconnect, watchdog liveness timers,
  or debugging physical link dropouts. Triggers on "serial disconnect",
  "reconnect", "baud rate", "USB OTG", "connection state", or link errors.
---

# Transport Operations Specification Skill

This skill governs physical and wireless link layer management, connection state machines, watchdog health checks, auto-reconnection algorithms, and web/desktop simulation abstraction layers.

---

## 1. When to Use (Trigger Table & Scope Boundaries)

| User Request Example | In Scope? | Action / Destination |
|---|---|---|
| *"Configure USB OTG serial baud rate to 115200 8N1"* | **YES** | Consult `references/channels.md` |
| *"Implement exponential backoff auto-reconnect on port disconnect"* | **YES** | Follow state machine in `references/reconnection.md` |
| *"Debug watchdog timer dropping connection after 2 seconds"* | **YES** | Verify liveness watchdog logic in `references/diagnostics.md` |
| *"Simulate GPS/IMU stream on Flutter Web without native USB drivers"* | **YES** | Consult `kIsWeb` mock provider rules |
| *"Parse 0xAA 0x55 binary frame or verify CRC-16"* | **NO** | Hand off to `command-protocol` |
| *"Format shift productivity report JSON"* | **NO** | Hand off to `response-preparation` |
| *"Display USB connection status badge on AppBar"* | **NO** | Hand off to `app-ui-specification` |

---

## 2. Skill Architecture

```
.agents/skills/transport-operations/
├── SKILL.md
└── references/
    ├── channels.md       # Hardware specs: RS-232, USB OTG, BLE, WiFi parameters
    ├── reconnection.md   # Connection state machine, backoff loops, retry thresholds
    └── diagnostics.md    # Link health metrics, liveness watchdog, packet counters
```

---

## 3. Connection State Machine & Watchdog

```
┌──────────────┐      Auto-Scan       ┌────────────┐
│ Disconnected ├─────────────────────►│ Connecting │
└──────▲───────┘                      └─────┬──────┘
       │                                    │
       │ Handshake Failed                   ▼ Handshake ACK
┌──────┴───────┐      Stream Stale    ┌───────────┐
│    Failed    │◄─────────────────────┤ Connected │
└──────────────┘      (diff > 2s)     └─────┬─────┘
       ▲                                    │ Live Binary Stream
       └────────────────────────────────────┴──────────────────► ACTIVE
```

### 3.1 States
1. `disconnected`: No physical USB cable or BLE device detected.
2. `connecting`: Port opened, negotiating baud rate.
3. `retrying`: Re-establishing connection following dropout (up to 5 attempts).
4. `connected`: Port open, awaiting initial telemetry.
5. `failed`: Permission denied or communication handshake failed.

### 3.2 Liveness Watchdog Threshold ($< 2$ Seconds)
The link is considered **ACTIVE** only if:
- `usbState.isConnected == true`
- `DateTime.now().difference(lastDataReceived).inSeconds < 2`

---

## 4. Tooling & MCP Integration

| MCP Resource | Usage in Transport Operations |
|---|---|
| `serial://ports` | Enumerate available physical serial/COM ports, baud rates, and hardware descriptors. |
| `ble://connections` | Inspect paired and discovered Bluetooth Low Energy peripherals and RSSI levels. |
| `wifi://status` | Verify network adapter connectivity, IP address, and signal strength for cloud sync. |

---

## 5. Related Skills & Hand-Off Rules

| Task Domain | Peer Skill | Hand-Off Trigger / Rule |
|---|---|---|
| **Binary Framing & OpCodes** | `command-protocol` | Hand off once raw stream is established for packet framing and CRC checks. |
| **Status Badge UI** | `app-ui-specification` | Hand off abstract `ConnectionStatus` stream for display in `GlobalAppBarActions`. |
| **Cloud Sync Payload** | `response-preparation` | Hand off when network is online to trigger batched REST data sync. |
