# Data Models & Schema Specification (data_models.md)

> **Toho EGS — Version 4.2.20 (Build 90)**  
> **Scope**: Domain Entities, Database Schemas, Timestamps & Serialization Standards  
> **Universal Compatibility**: Flutter (`isar_community`), Web / React (TypeScript Interfaces & Zod), Mobile (SQLite / Realm / Room / CoreData).

---

## 1. Architectural Philosophy & Universal Data Rules

In modern enterprise applications, data models bridge three distinct worlds:
1. **Persistent Local Storage** (Offline-First local database: Isar, SQLite, Room, CoreData, or IndexedDB).
2. **In-Memory Domain Logic** (Immutability, state management stores, reactive calculations).
3. **Transport & Serialization Layer** (JSON payloads, REST endpoints, binary hardware packets).

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DATA FLOW & MODEL LAYERS                        │
├──────────────────────────────────┬─────────────────────────────────────┤
│ 1. TRANSPORT DTO (Network/Serial)│ 2. PERSISTENT ENTITY (Local DB)     │
│ - Raw Hex / JSON payloads        │ - Managed IDs, Indices, Auto-inc    │
│ - Strict parse & validation      │ - Atomic read/write transactions    │
├──────────────────────────────────┼─────────────────────────────────────┤
│ 3. IN-MEMORY DOMAIN ENTITY       │ 4. SERIALIZATION STANDARDS          │
│ - Immutable final fields         │ - Timestamps in SECONDS (int)       │
│ - copyWith constructors          │ - Enums as stable strings/integers  │
└──────────────────────────────────┴─────────────────────────────────────┘
```

### 1.1 Golden Rules for Data Modeling
1. **Timestamps in Seconds**: Always store timestamps as **Unix Epoch Seconds** (`int`), NOT milliseconds, unless microsecond telemetry precision is explicitly required. This guarantees native cross-platform compatibility across C/C++, Python, Dart, and JavaScript.
2. **Preserve Entity IDs on Update**: When modifying and persisting existing records in the database, always retain the entity `id` (or primary key) to prevent duplicate ghost records.
3. **Enums as Stable Strings**: Persist enums as uppercase string values (e.g. `'SPOT'`, `'CRUMBLING'`, `'MAINT'`) or explicit integers, never by arbitrary language ordinal indices which break when enums are reordered.
4. **Sanitize Numeric Constraints**: Prevent invalid division-by-zero or negative boundaries at the model level (e.g. `targetDepth <= 0` must fallback to default `100.0` cm; angle displays capped at $360.00^\circ$).

---

## 2. Core Domain Entities Catalogue

### 2.1 Identity & Organization Entities

#### `Person` (Operator & Technician)
- **Purpose**: Authenticates excavator operators, manages PIN access codes, and tracks machine shifts.
- **Fields**:
  | Field | Type | Attributes | Description |
  |---|---|---|---|
  | `id` | `int` / `Id` | Primary Key, Auto-increment | Internal database record ID |
  | `uid` | `String` | `@Index(unique: true)` | Machine-readable unique identifier |
  | `firstName` | `String` | Required | Operator first name |
  | `lastName` | `String` | Required | Operator family name |
  | `kontraktor` | `String` | Required | Associated mining contractor organization |
  | `password` | `String` | Required | 6-digit access PIN code |
  | `picURL` | `String?` | Optional | Avatar asset path (e.g. `images/driver_exca.png`) |
  | `createdAt` | `int` | Unix seconds | Registration timestamp |

#### `Equipment` (Machine Fleet Asset)
- **Purpose**: Stores machine configuration, model, serial number, and kinematics arm lengths.
- **Fields**:
  | Field | Type | Attributes | Description |
  |---|---|---|---|
  | `id` | `int` / `Id` | Primary Key, Auto-increment | Database ID |
  | `equipmentName`| `String` | Index | Fleet unit name (e.g. `EX-320D-01`) |
  | `model` | `String` | Required | Excavator model (e.g. `CAT 320D`, `PC200-8`) |
  | `boomLength` | `double` | Millimeters | Physical center-to-center boom length |
  | `stickLength` | `double` | Millimeters | Physical stick/arm length |
  | `bucketLength`| `double` | Millimeters | Bucket hinge to tooth tip length |

---

### 2.2 Operational Job Execution Entities

#### `WorkFile` (Guidance Job File)
- **Purpose**: Represents an imported CAD/GIS excavation project containing design boundaries and spots.
- **Fields**:
  | Field | Type | Attributes | Description |
  |---|---|---|---|
  | `id` | `int` / `Id` | Primary Key | Job file record ID |
  | `areaName` | `String` | Required | Mining pit or civil works area |
  | `equipment` | `String` | Operational Mode | Filter tag (`SPOT` or `CRUMBLING`) |
  | `panjang` | `double` | Spacing X | Spacing along contour/grid (e.g. 4.0m) |
  | `lebar` | `double` | Spacing Y | Spacing between parallel lines (e.g. 1.87m) |
  | `totalSpot` | `int` | Count | Total spots or segments in project |
  | `spotDone` | `int` | Count | Number of verified excavated spots |
  | `status` | `String` | Index | `'Pending'`, `'In Progress'`, or `'Done'` |
  | `createdAt` | `int` | Unix seconds | Import timestamp |

#### `WorkingSpot` (Spatial Guidance Point)
- **Purpose**: Individual target location for bucket tip guidance.
- **Fields**:
  | Field | Type | Attributes | Description |
  |---|---|---|---|
  | `id` | `int` / `Id` | Primary Key | Sequential spot index |
  | `lineId` | `int` | Line index | Contour swath or grid line number |
  | `targetLat` | `double` | WGS-84 Latitude | Designed target latitude |
  | `targetLng` | `double` | WGS-84 Longitude| Designed target longitude |
  | `targetAlt` | `double` | Meters | Designed target grade elevation |
  | `status` | `int` | Operational State | `0`: Pending, `1`: Done (Green), `2`: Block (Yellow) |
  | `devX` | `double?` | Error (meters) | Radial horizontal deviation |
  | `devY` | `double?` | Error (meters) | Cross-track deviation |
  | `depth` | `double?` | Centimeters | Achieved excavation depth |

---

### 2.3 Productivity & Telemetry Entities

#### `TimesheetRecord` (Shift Activity & Productivity Log)
- **Purpose**: Records machine hours, activities, fuel, and digging accuracy for supervisor reporting.
- **Fields**:
  | Field | Type | Description |
  |---|---|---|
  | `id` | `int` / `Id` | Primary Key |
  | `operatorName` | `String` | Operator full name |
  | `activityType` | `String` | `'OPERASIONAL'`, `'MDT'` (Mechanical Downtime), `'ODT'` (Operational Delay) |
  | `activityName` | `String` | Detail name (e.g. `'Digging'`, `'Refueling'`, `'Breakdown'`) |
  | `startTime` | `int` | Shift activity start (Unix seconds) |
  | `endTime` | `int?` | Shift activity end (Unix seconds, null if running) |
  | `hmStart` | `double` | Initial machine Hour Meter reading |
  | `hmEnd` | `double?` | Final machine Hour Meter reading |
  | `totalSpotsDone`| `int` | Number of spots excavated during this session |
  | `productivity` | `double` | Rate achieved: $(\text{Spots} / \text{Hours})$ |
  | `accuracy` | `double` | Average bucket tip accuracy percentage |

#### `MapConfig` (System Settings & Operational Parameters)
- **Purpose**: Persists operator preferences and kinematic tolerances.
- **Fields**:
  | Field | Type | Default | Description |
  |---|---|---|---|
  | `id` | `int` / `Id` | `1` | Singleton configuration ID |
  | `spotCompletionDelay` | `double` | `1.0` s | Delay inside radius before auto-marking Done |
  | `autoCompleteEnabled` | `bool` | `true` | Automatic target completion toggle |
  | `targetingMethod` | `int` | `1` | Targeting algorithm (`0`: Any, `1`: Method 1, `2`: Method 2) |
  | `autoMethodEnabled` | `bool` | `false` | Dynamically switch method based on terrain slope |
  | `steepThreshold` | `double` | `0.15` (15%) | Slope threshold triggering steep digging method |
  | `crumblingRadius` | `double` | `15.0` m | Active excavator sub-segment detail radius |
  | `crumblingIdleDelay` | `double` | `3.0` s | Idle lift delay before auto-completing segment |
  | `crumblingBendThreshold`| `double`| `5.0` deg | Angle threshold for curve polyline segmentation |
  | `targetDepth` | `double` | `100.0` cm | Target trench/crumbling depth (must be $>0$) |
  | `showDigDeep` | `bool` | `true` | Display vertical depth bar on HUD guidance |

---

## 3. Cross-Framework Model Implementation

### 3.1 Dart / Flutter (Isar Community Collection)
```dart
import 'package:isar/isar.dart';

part 'workfile.g.dart';

@collection
class WorkFile {
  Id id = Isar.autoIncrement;

  @Index()
  String? areaName;

  String? equipment; // 'SPOT' or 'CRUMBLING'
  double? panjang;
  double? lebar;
  int? totalSpot;
  int? spotDone;

  @Index()
  String? status; // 'Pending', 'In Progress', 'Done'

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
```

### 3.2 TypeScript / React / Next.js (Zod Schema & Interface)
```typescript
import { z } from 'zod';

export const WorkFileSchema = z.object({
  id: z.number().int().positive().optional(),
  areaName: z.string().min(1, 'Area name is required'),
  equipment: z.enum(['SPOT', 'CRUMBLING', 'MAINTENANCE']).default('SPOT'),
  panjang: z.number().positive(),
  lebar: z.number().positive(),
  totalSpot: z.number().int().nonnegative().default(0),
  spotDone: z.number().int().nonnegative().default(0),
  status: z.enum(['Pending', 'In Progress', 'Done']).default('Pending'),
  createdAt: z.number().int().default(() => Math.floor(Date.now() / 1000)),
});

export type WorkFile = z.infer<typeof WorkFileSchema>;
```

### 3.3 Python / Pydantic (Backend / Microservices)
```python
from pydantic import BaseModel, Field
from typing import Optional, Literal
import time

class WorkFileModel(BaseModel):
    id: Optional[int] = None
    area_name: str
    equipment: Literal['SPOT', 'CRUMBLING', 'MAINTENANCE'] = 'SPOT'
    panjang: float = Field(gt=0)
    lebar: float = Field(gt=0)
    total_spot: int = 0
    spot_done: int = 0
    status: Literal['Pending', 'In Progress', 'Done'] = 'Pending'
    created_at: int = Field(default_factory=lambda: int(time.time()))
```

---

## 4. Entity Migration & Seed Database SOP

When establishing a new project environment:
1. **Initial Seeding**: The application must automatically seed default entities if database is empty:
   - Default Administrator / Operator profile (`Person`: ID 1, PIN `'123456'`).
   - Default Machine kinematics (`Equipment`: CAT 320D, Boom 3400mm, Stick 2500mm, Bucket 1200mm).
   - Default Map Configuration (`MapConfig`: Target Depth 100cm, Delay 1.0s, Radius 15m).
2. **Schema Code Generation**:
   - Flutter: Run `dart run build_runner build --delete-conflicting-outputs`.
   - TypeScript: Run `prisma generate` or `npx zod-to-ts`.
