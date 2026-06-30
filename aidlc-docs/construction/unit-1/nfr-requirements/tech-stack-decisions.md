# Tech Stack Decisions — Unit 1: Resources (Shared Data)

## Overview

Technology choices for the game's shared data layer, based on project
requirements and NFR assessment.

---

## Engine and Language

| Decision               | Choice                           | Rationale                           |
| ---------------------- | -------------------------------- | ----------------------------------- |
| **Game Engine**        | Godot Engine 4.x (latest stable) | FR-1.1, CON-1 — project requirement |
| **Scripting Language** | GDScript                         | CON-2 — project requirement         |
| **Primary Export**     | Web (HTML5/WebAssembly)          | FR-1.2, CON-3 — project requirement |
| **Secondary Export**   | Desktop (Windows, macOS, Linux)  | FR-1.3 — development and testing    |

---

## Data Storage Format

| Decision            | Choice                                        | Rationale                                                               |
| ------------------- | --------------------------------------------- | ----------------------------------------------------------------------- |
| **Resource Format** | Godot `.tres` resource files                  | Native Godot format; direct import without parsing; type-safe in editor |
| **Character Files** | `resources/characters/{character_id}.tres`    | One file per character; easy to add/modify individually                 |
| **Move Files**      | `resources/moves/{move_id}.tres`              | One file per move; supports 200+ moves with individual editing          |
| **Type Chart**      | `resources/type_chart.gd` or embedded in code | 7×7 lookup table; small enough to embed as a 2D array                   |
| **Status Effects**  | Embedded in code or small `.tres` files       | Only 5 status types; defined as constants/enums                         |

### Why `.tres` over alternatives

| Alternative   | Reason Not Selected                                               |
| ------------- | ----------------------------------------------------------------- |
| JSON          | Requires parsing at load time; no native Godot editor integration |
| CSV           | No native Godot support; requires import pipeline                 |
| Custom Binary | Over-engineered for this data size; harder to debug               |

---

## Data Loading Strategy

| Decision              | Choice                                       | Rationale                                                         |
| --------------------- | -------------------------------------------- | ----------------------------------------------------------------- |
| **Loading Method**    | Preloaded at startup                         | Data size is small (<200KB); all data needed before battle starts |
| **Memory Management** | All resources kept in memory                 | Fast runtime access; no load-time hitches during gameplay         |
| **Error Handling**    | Log warnings, skip invalid entries, continue | Prevents single data error from blocking entire game              |

### Loading Flow

```
Game Start
  → Load all .tres files from resources/characters/
  → Load all .tres files from resources/moves/
  → Load type chart
  → Validate all data (referential integrity, business rules)
  → Log warnings for any invalid entries
  → Game Ready
```

---

## Data Validation Strategy

| Decision              | Choice                                  | Rationale                                                      |
| --------------------- | --------------------------------------- | -------------------------------------------------------------- |
| **Validation Timing** | At load time                            | Catch errors early; prevent runtime issues                     |
| **Validation Rules**  | All rules from business-rules.md        | 20+ rules covering characters, moves, types, status, integrity |
| **Test Approach**     | Unit tests for validation logic         | Automated regression detection for balance patches             |
| **Test Framework**    | GDScript built-in test framework or GUT | Native Godot testing support                                   |

### Validation Rule Categories

| Category              | Rules | Test Priority                |
| --------------------- | ----- | ---------------------------- |
| Character Identity    | CR-1  | High                         |
| Character Stats       | CR-2  | High                         |
| Character Type        | CR-3  | High                         |
| Character Moves       | CR-4  | High (referential integrity) |
| Move Identity         | MR-1  | Medium                       |
| Move Power/Accuracy   | MR-2  | Medium                       |
| Move Effect           | MR-3  | Medium                       |
| Move Stat Mod         | MR-4  | Medium                       |
| Move Multi-Hit        | MR-5  | Low                          |
| Move Recoil           | MR-6  | Low                          |
| Move Healing          | MR-7  | Low                          |
| Type Validity         | TR-1  | High                         |
| Type Constraints      | TR-2  | Medium                       |
| Five Elements         | TR-3  | Medium                       |
| Status Identity       | SR-1  | Medium                       |
| Status Duration       | SR-2  | Low                          |
| Status Damage         | SR-3  | Medium                       |
| Status Modifications  | SR-4  | Medium                       |
| Status Interactions   | SR-5  | Medium                       |
| Referential Integrity | VR-1  | Critical                     |
| Completeness          | VR-2  | High                         |
| Balance               | VR-3  | High                         |

---

## Localization Strategy

| Decision               | Choice                             | Rationale                                  |
| ---------------------- | ---------------------------------- | ------------------------------------------ |
| **Initial Languages**  | Japanese + English                 | U2 response                                |
| **Translation System** | Godot built-in translation server  | Native support; no external tools needed   |
| **Data Structure**     | Translation keys in resource files | Allows per-character/per-move localization |
| **Expansion**          | Support for 3+ languages           | U2 response                                |

---

## Version Control and Patching

| Decision                   | Choice                                     | Rationale                                   |
| -------------------------- | ------------------------------------------ | ------------------------------------------- |
| **Data Versioning**        | Version field in resource files            | Detect patch compatibility                  |
| **Patch Distribution**     | Replace .tres files                        | Simple file replacement for balance patches |
| **Backward Compatibility** | New fields are optional; old fields remain | Prevent save data breakage                  |

---

## Traceability

| Decision             | Source Question | Requirement Source            |
| -------------------- | --------------- | ----------------------------- |
| .tres format         | T2              | Native Godot format           |
| Preloaded at startup | T3              | Small data size, offline game |
| Checksum validation  | SE2             | Basic integrity               |
| Unit tests           | R2              | Validation logic              |
| Multi-language       | U2              | 3+ languages                  |
