# Local Configuration I/O (config-io.md)

> **Scope**: Safe atomic serialization, backup handling, schema migration, and corruption avoidance.

---

## 1. Atomic File Write Protocol

To prevent corrupted JSON configurations when machine battery power drops unexpectedly:

1. Serialize data into in-memory JSON string.
2. Write to a temporary file: `app_config.json.tmp`.
3. Flush and synchronize buffer to physical disk (`flush()`).
4. Atomically rename/replace `app_config.json.tmp` to `app_config.json`.
5. Keep previous revision as `app_config.json.bak` for emergency fallback.

---

## 2. Configuration Schema Versioning

Every persistent configuration file must include a `schema_version` integer:

```json
{
  "schema_version": 2,
  "system_mode": "SPOT",
  "spot_completion_delay_sec": 1.5,
  "crumbling_radius_m": 2.0,
  "target_depth_m": 3.4
}
```

If the loaded version is older than current runtime, run sequential migration functions prior to initializing application state stores.
