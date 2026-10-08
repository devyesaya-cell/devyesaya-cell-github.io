# Physical & Wireless Channels (channels.md)

> **Scope**: Serial USB OTG, RS-232 specifications, BLE wireless telemetry, and socket configurations.

---

## 1. Channel Configurations

### 1.1 USB OTG / RS-232 Serial Port
- **Baud Rate**: `115200 bps` (Default standard for machine controllers).
- **Data Bits**: `8`
- **Stop Bits**: `1`
- **Parity**: `None` (`8N1`)
- **Flow Control**: `None`
- **Android Permissions**: `android.permission.USB_PERMISSION` requested dynamically upon attachment intent.

### 1.2 Bluetooth Low Energy (BLE)
- **Profile**: Custom GATT Service with Notify characteristic for high-frequency telemetry.
- **MTU Size**: Negotiated to 247 bytes to avoid multi-packet MTU fragmentation.

### 1.3 Web & Desktop Sandboxes (`kIsWeb`)
- Browsers lack direct access to Android `usb_serial`.
- **Primary Strategy**: Autonomous mock telemetry generator streaming simulated excavator kinematics at 10 Hz.
- **Desktop Alternative**: Web Serial API (`navigator.serial`) on supported Chromium browsers.
