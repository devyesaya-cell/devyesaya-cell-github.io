# Protocol Testing & Verification (protocol-tests.md)

> **Scope**: Test suites, synthetic byte sequences, fuzzy validation, and edge-case fixtures.

---

## 1. Test Matrices

| Test Case | Byte Sequence Description | Expected Behavior |
|---|---|---|
| `TC-PROTO-01` | Valid `0xAA 0x55` header with matching CRC-16 | Packet parsed successfully, payload dispatched. |
| `TC-PROTO-02` | Corrupted CRC (single bit flip in checksum) | Frame discarded with `CRC_MISMATCH` log entry. |
| `TC-PROTO-03` | Truncated frame (stream breaks midway through payload) | Buffer retains bytes until timeout (100ms), then flushes. |
| `TC-PROTO-04` | Unknown OpCode (`0xEF`) | Frame discarded with `UNKNOWN_OPCODE` warning; parser advances to next `0xAA 0x55`. |
| `TC-PROTO-05` | Zero-length payload ($N=0$) | Handled safely if OpCode allows zero payload; valid CRC verified. |

---

## 2. Sample Verification Fixtures

```dart
// Test fixture: Synthetic ACK packet
// Header: 0xAA 0x55, OpCode: 0x06, Len: 0x01, Data: [0x53], CRC: [calculated]
final validAckFrame = Uint8List.fromList([
  0xAA, 0x55, 0x06, 0x01, 0x53, 0xD4, 0x89
]);

// Test fixture: Frame with garbage pre-amble
final noisyStream = Uint8List.fromList([
  0x00, 0xFF, 0x12, 0xAA, 0x55, 0x06, 0x01, 0x53, 0xD4, 0x89
]);
```
