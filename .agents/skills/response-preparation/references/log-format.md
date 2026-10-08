# Structured Audit Log Standards (log-format.md)

> **Scope**: Diagnostic logging schema, audit trail persistence, and session record formats.

---

## 1. Log Event JSON Schema

Each log entry is written as a JSON line (JSONL) with required telemetry context:

```json
{
  "timestamp": "2026-10-08T03:20:00.123Z",
  "epoch_seconds": 1775560800,
  "level": "INFO",
  "category": "TELEMETRY",
  "event": "telemetry:staleDetected",
  "device_id": "TOHO-EGS-EX01-SN982",
  "operator_id": 14,
  "details": {
    "channel": "USB_OTG_SERIAL",
    "stale_duration_sec": 2.4,
    "last_opcode": "0xD1"
  }
}
```

---

## 2. Severity Guidelines

- **`DEBUG`**: Detailed byte counts, individual raw frame traces (development only).
- **`INFO`**: Mode changes, operator login/logout, spot completion, sync batch dispatch.
- **`WARN`**: Telemetry gap $>2$s, retry attempt initiated, minor GPS accuracy degradation.
- **`ERROR`**: CRC checksum failure, USB port disconnect, HTTP 500 sync error, database write failure.
