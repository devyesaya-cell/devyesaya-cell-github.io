# Reconnection Logic & Lifecycle Recovery (reconnection.md)

> **Scope**: Auto-reconnect retry limits, exponential backoff timing, and error recovery policies.

---

## 1. Auto-Reconnection Strategy

Mining machinery suffers intense vibration and thermal stress. If an established serial or BLE link disconnects unexpectedly:

```
[DISCONNECT DETECTED]
        │
        ▼
Attempt 1 (Immediate: 500ms delay) ──► Success? ──► [RESTORE CONNECTED]
        │ No
        ▼
Attempt 2 (1000ms delay)           ──► Success? ──► [RESTORE CONNECTED]
        │ No
        ▼
Attempt 3 (2000ms delay)           ──► Success? ──► [RESTORE CONNECTED]
        │ No
        ▼
Attempt 4 (4000ms delay)           ──► Success? ──► [RESTORE CONNECTED]
        │ No
        ▼
Attempt 5 (8000ms delay)           ──► Success? ──► [RESTORE CONNECTED]
        │ No
        ▼
[ENTER FAILED STATE] ──► Emit `telemetry:staleDetected` ──► Prompt Manual Re-scan
```

---

## 2. Reconnection Parameters

- **`maxRetries`**: `5` attempts.
- **`baseDelayMs`**: `500` ms.
- **`maxDelayMs`**: `8000` ms.
- **Backoff Formula**: `delay = min(baseDelayMs * pow(2, attempt), maxDelayMs)`.
- **UI Non-Blocking**: The retry loop runs entirely in the background notifier; never block the UI thread.
