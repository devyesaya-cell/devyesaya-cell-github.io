# Response Types & Cloud Payloads (response-types.md)

> **Scope**: REST API payload structures, WebSocket broadcast messages, and synchronization DTOs.

---

## 1. Timesheet Cloud Sync Endpoint (`POST /api/v1/sync/timesheets`)

```json
{
  "device_id": "TOHO-EGS-EX01-SN982",
  "sync_timestamp": 1775560800,
  "records": [
    {
      "client_id": 42,
      "uuid": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
      "operator_name": "Agus Pratama",
      "activity_type": "OPERASIONAL",
      "activity_name": "Digging",
      "start_time": 1775553600,
      "end_time": 1775560800,
      "hm_start": 4120.5,
      "hm_end": 4122.5,
      "total_spots_done": 48,
      "productivity": 24.0,
      "accuracy": 98.4
    }
  ]
}
```

---

## 2. Server Response Schema

```json
{
  "status": "success",
  "server_time": 1775560805,
  "processed_count": 1,
  "rejected_records": []
}
```

- When status is `success`, local database marks records with `isSynced = true`.
- If server returns HTTP 5xx or network times out, keep records queued with exponential retry.
