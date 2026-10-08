# Command Registry Specification (command-registry.md)

> **Scope**: Definitive catalog of all supported hardware OpCodes, bit definitions, directionality, and payload layouts.

---

## 1. Registered OpCodes Catalog

| OpCode | Hex | Direction | Description | Typical Rate / Trigger |
|---|---|---|---|---|
| `GNSS_TELEMETRY` | `0xD0` | Controller $\rightarrow$ App | Rover GNSS high-precision coordinates | 10 Hz (Streaming) |
| `IMU_TELEMETRY` | `0xD1` | Controller $\rightarrow$ App | Boom, Stick, Bucket pitch/roll & accelerations | 20 Hz (Streaming) |
| `BASE_STATION` | `0xD3` | Base $\rightarrow$ App | Base station battery, radio RSSI, RTK satellites | 1 Hz |
| `CALIB_TRIGGER` | `0x52` | App $\rightarrow$ Controller | Initiates sensor zero/offset calibration | On operator tap |
| `SET_PARAM` | `0x53` | App $\rightarrow$ Controller | Writes machine dimensions and tuning offsets | On setting save |
| `ACK` | `0x06` | Controller $\rightarrow$ App | Acknowledgment confirmation packet | In response to commands |

---

## 2. Payload Detailed Schemas

### 2.1 OpCode `0xD0`: Rover GNSS Telemetry ($N = 21$)
- `latitude` (Float64, 8 bytes): Latitude in decimal degrees.
- `longitude` (Float64, 8 bytes): Longitude in decimal degrees.
- `elevation` (Float32, 4 bytes): Orthometric height in meters.
- `fixQuality` (UInt8, 1 byte): `0` = Invalid, `1` = Autonomous, `2` = RTK Float, `4` = RTK Fix.

### 2.2 OpCode `0xD1`: IMU Sensor Telemetry ($N = 24$)
- `boomPitch` (Float32, 4 bytes): Angle in degrees ($0.0 \dots 360.0^\circ$).
- `boomRoll` (Float32, 4 bytes): Lateral tilt in degrees.
- `stickPitch` (Float32, 4 bytes): Angle in degrees ($0.0 \dots 360.0^\circ$).
- `stickRoll` (Float32, 4 bytes): Lateral tilt in degrees.
- `bucketPitch` (Float32, 4 bytes): Angle in degrees ($0.0 \dots 360.0^\circ$).
- `bucketRoll` (Float32, 4 bytes): Lateral tilt in degrees.

### 2.3 OpCode `0x53`: Set Parameter Command ($N = 5$)
- `paramType` (UInt8, 1 byte):
  - `0`: Boom Length (mm)
  - `10`: Boom Base Height (mm)
  - `20`: Stick Length (mm)
  - `30`: Bucket Depth Target Offset (mm)
- `paramValue` (Int32, 4 bytes): Signed 32-bit integer value in millimeters.
