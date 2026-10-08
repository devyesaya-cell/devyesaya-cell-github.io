# Binary Frame Format & Checksum Specification (frame-format.md)

> **Scope**: Byte-level framing, byte ordering, synchronization preambles, and CRC-16 computation.

---

## 1. Frame Structure Overview

```
Byte Offset:   0       1       2       3             4 .. 4+(N-1)       4+N       4+N+1
Field:       [0xAA]  [0x55] [OPCODE] [LENGTH]     [DATA BYTES (N)]   [CRC_HIGH] [CRC_LOW]
Length:      1 Byte  1 Byte 1 Byte   1 Byte            N Bytes        1 Byte     1 Byte
```

- **Header Preamble (`0xAA 0x55`)**: Synchronization markers. A receiver scanning an asynchronous serial stream must scan byte-by-byte until detecting `0xAA` followed immediately by `0x55`.
- **OpCode**: An unsigned 8-bit integer (`0x00` - `0xFF`) identifying the command or telemetry message.
- **Payload Length ($N$)**: The number of payload bytes following the header. Maximum payload is 255 bytes.
- **Data Payload**: Binary data formatted according to the OpCode's schema. Multi-byte numeric fields are stored in **Little-Endian** byte order.
- **CRC-16**: 16-bit Cyclic Redundancy Check (CCITT-FALSE, polynomial `0x1021`, initial value `0xFFFF`) calculated over `[OPCODE, LENGTH, DATA...]`.

---

## 2. CRC-16 Calculation Algorithm

```dart
int computeCRC16(Uint8List data) {
  int crc = 0xFFFF;
  for (int i = 0; i < data.length; i++) {
    crc ^= (data[i] << 8);
    for (int j = 0; j < 8; j++) {
      if ((crc & 0x8000) != 0) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  return crc;
}

bool verifyPacketCRC(Uint8List packet) {
  if (packet.length < 5) return false;
  // CRC is the last 2 bytes
  final int receivedCrc = (packet[packet.length - 2] << 8) | packet[packet.length - 1];
  // Checksum covers opcode (byte 2) up to data end
  final int calculatedCrc = computeCRC16(packet.sublist(2, packet.length - 2));
  return receivedCrc == calculatedCrc;
}
```

---

## 3. Streaming Framing State Machine

When consuming raw byte buffers from a continuous serial stream:

1. **LOOKING_FOR_HEADER_1**: Read bytes until finding `0xAA`.
2. **LOOKING_FOR_HEADER_2**: Next byte must be `0x55`. If not, reset to step 1.
3. **READ_OPCODE**: Read 1 byte.
4. **READ_LENGTH**: Read 1 byte to determine $N$.
5. **READ_PAYLOAD**: Accumulate $N$ bytes into payload buffer.
6. **READ_CRC**: Read 2 bytes.
7. **VERIFY_AND_DISPATCH**: Run `verifyPacketCRC()`. If valid, dispatch to presenter stream. If invalid, log frame dropped and reset.
