# Link Diagnostics & Health Metrics (diagnostics.md)

> **Scope**: Watchdog monitoring, metrics aggregation, frame loss detection, and telemetry throughput counters.

---

## 1. Real-Time Link Metrics

The transport manager exposes a diagnostic state object for live troubleshooting:

```dart
class TransportDiagnostics {
  final int packetsReceived;
  final int packetsDropped;
  final int bytesReceived;
  final double currentPacketsPerSecond;
  final Duration timeSinceLastPacket;
  final String? activePortName;

  const TransportDiagnostics({
    this.packetsReceived = 0,
    this.packetsDropped = 0,
    this.bytesReceived = 0,
    this.currentPacketsPerSecond = 0.0,
    this.timeSinceLastPacket = Duration.zero,
    this.activePortName,
  });
}
```

---

## 2. Liveness Watchdog Implementation

```dart
Timer? _watchdogTimer;

void startWatchdog() {
  _watchdogTimer?.cancel();
  _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (state.isConnected) {
      final elapsed = DateTime.now().difference(lastPacketTimestamp);
      if (elapsed.inSeconds >= 2) {
        state = state.copyWith(isStale: true);
        ref.read(eventBusProvider).emit('telemetry:staleDetected', elapsed.inSeconds);
      }
    }
  });
}
```
