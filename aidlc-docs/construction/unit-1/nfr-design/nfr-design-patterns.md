# NFR Design Patterns — Unit 1: Resources (Shared Data)

## Overview

Design patterns and structural decisions for incorporating NFR requirements into
the shared data layer. These patterns address resilience, scalability,
performance, security, and logical component organization.

---

## Resilience Patterns

### RP-1: Graceful Degradation with Placeholder Fallback

**Pattern**: When a `.tres` file is missing or corrupted, the system logs a
critical warning and uses default placeholder data instead of crashing.

**Design**:

```
DataLoader
  ├── load_character(id: String) -> CharacterData
  │     ├── Success: return loaded data
  │     ├── File Missing: log_warning("Character not found: {id}"), return placeholder
  │     └── Parse Error: log_warning("Corrupted character file: {id}"), return placeholder
  └── load_move(id: String) -> MoveData
        ├── Success: return loaded data
        ├── File Missing: log_warning("Move not found: {id}"), return placeholder
        └── Parse Error: log_warning("Corrupted move file: {id}"), return placeholder
```

**Placeholder Data**:

| Field        | Placeholder Value           |
| ------------ | --------------------------- |
| id           | Original requested ID       |
| name         | "Unknown"                   |
| hp           | 1                           |
| attack       | 1                           |
| defense      | 1                           |
| speed        | 1                           |
| intelligence | 1                           |
| spirit       | 1                           |
| moves        | [] (empty)                  |
| description  | "Data missing or corrupted" |

**Rationale**: Prevents single data error from blocking entire game. Developer
notifies via logs while game remains playable for testing.

---

### RP-2: Batch Validation with Summary Reporting

**Pattern**: The validation system collects all violations across all data
files, then reports them in a single summary instead of stopping at the first
error.

**Design**:

```
DataValidator
  └── validate_all() -> ValidationResult
        ├── errors: Array[ValidationError]     — critical issues
        ├── warnings: Array[ValidationWarning] — non-critical issues
        └── summary: ValidationSummary
              ├── total_files_scanned: int
              ├── valid_files: int
              ├── invalid_files: int
              └── error_counts_by_type: Dictionary
```

**Output Format**:

```
=== Data Validation Summary ===
Files scanned: 252
Valid: 248 | Invalid: 4

--- Errors (4) ---
[CR-2] character_zhang_fei: stat sum 3150 exceeds maximum 3000
[CR-4] character_li_bai: move slot 3 references unknown move "wind_slash"
[VR-1] character_sun_quan: move "fire_strike" does not exist in move registry
[TR-1] type_chart: missing entry for [Metal][Yin]

--- Warnings (2) ---
[MR-3] move_thunder: effect=Burn but effectChance=0
[CR-3] character_zhu_ge_liang: secondary type same as primary (Wood/Wood)

Validation complete. 4 errors, 2 warnings.
```

**Rationale**: Enables developers to fix all issues in one pass rather than
repeatedly rebuilding after each single error.

---

## Scalability Patterns

### SP-1: Directory Scanning for Content Discovery

**Pattern**: The data loader scans resource directories at startup to discover
all character and move files automatically, without requiring an explicit
registry.

**Design**:

```
DataLoader
  └── discover_characters() -> Array[String]
        ├── DirAccess.open("res://resources/characters/")
        ├── List all .tres files
        └── Return array of character IDs (filename without extension)

  └── discover_moves() -> Array[String]
        ├── DirAccess.open("res://resources/moves/")
        ├── List all .tres files
        └── Return array of move IDs (filename without extension)
```

**File Convention**:

- File name = resource ID (e.g., `zhuge_liang.tres` → ID `"zhuge_liang"`)
- One resource per file
- `.tres` extension required

**Rationale**: Adding new content requires only dropping a `.tres` file into the
correct directory. No registry file to maintain.

**Web Platform Note**: `DirAccess` may be limited in Web exports. A fallback to
explicit registry (JSON manifest) should be available for Web builds.

---

### SP-2: DLC Content Pack Support

**Pattern**: Additional content can be loaded from a designated DLC directory at
runtime, extending the base game content.

**Design**:

```
Directory Structure:
  res://resources/characters/     ← Base game characters
  res://resources/moves/           ← Base game moves
  res://dlc/characters/            ← DLC characters (optional)
  res://dlc/moves/                ← DLC moves (optional)

DataLoader
  └── load_all_characters() -> Dictionary
        ├── Load from res://resources/characters/
        ├── If DirAccess.exists("res://dlc/characters/"):
        │     Load from res://dlc/characters/
        └── Merge into single dictionary (DLC overrides base on ID collision)
```

**ID Collision Resolution**: DLC content overrides base game content when IDs
match. This allows DLC to rebalance existing characters.

**Rationale**: Simple DLC support without complex manifest system. Sufficient
for developer-controlled content expansion.

---

## Performance Patterns

### PP-1: Precomputed Type Effectiveness Matrix

**Pattern**: Type effectiveness is stored as a precomputed 7×7 2D array
constant, providing O(1) lookup with minimal memory overhead.

**Design**:

```gdscript
# type_chart.gd
const TYPE_ORDER = [TYPE_WOOD, TYPE_FIRE, TYPE_EARTH, TYPE_METAL, TYPE_WATER, TYPE_YANG, TYPE_YIN]

const TYPE_CHART: Array = [
    #  Wood  Fire  Earth Metal Water Yang  Yin   (Defender →)
    [1.0,  1.25, 0.5,  2.0,  1.0,  1.0, 1.0],  # Wood   (Attacker ↓)
    [2.0,  1.0,  1.25, 0.5,  1.0,  1.0, 1.0],  # Fire
    [1.25, 2.0,  1.0,  1.0,  0.5,  1.0, 1.0],  # Earth
    [0.5,  1.25, 2.0,  1.0,  1.0,  1.0, 1.0],  # Metal
    [1.0,  0.5,  1.25, 2.0,  1.0,  1.0, 1.0],  # Water
    [1.0,  1.0,  1.0,  1.0,  1.0,  1.0, 2.0],  # Yang
    [1.0,  1.0,  1.0,  1.0,  1.0,  2.0, 1.0],  # Yin
]

func resolve_type_effectiveness(attacker_type: int, defender_primary: int, defender_secondary: int) -> float:
    var primary_mult = TYPE_CHART[attacker_type][defender_primary]
    if defender_secondary == defender_primary:  # No secondary
        return primary_mult
    var secondary_mult = TYPE_CHART[attacker_type][defender_secondary]
    var result = primary_mult * secondary_mult
    return clamp(result, 0.25, 4.0)
```

**Memory Footprint**: 49 floats × 4 bytes = ~200 bytes. Negligible.

**Rationale**: Precomputed array is fastest possible lookup. No calculation
overhead at runtime. Type chart is small enough that memory is irrelevant.

---

### PP-2: Flat Dictionary for Resource Storage

**Pattern**: All character and move resources are stored in flat `Dictionary`
objects keyed by string ID, providing O(1) lookup.

**Design**:

```gdscript
# data_registry.gd
var characters: Dictionary = {}  # String → CharacterData
var moves: Dictionary = {}        # String → MoveData

func get_character(id: String) -> CharacterData:
    if characters.has(id):
        return characters[id]
    push_warning("Character not found: " + id)
    return null

func get_move(id: String) -> MoveData:
    if moves.has(id):
        return moves[id]
    push_warning("Move not found: " + id)
    return null
```

**Memory Layout**:

```
characters = {
    "zhuge_liang": CharacterData,
    "guan_yu": CharacterData,
    "zhang_fei": CharacterData,
    ... (50+ entries)
}

moves = {
    "fire_strike": MoveData,
    "thunder_bolt": MoveData,
    ... (200+ entries)
}
```

**Rationale**: Godot Dictionary provides fast string-keyed lookup. 250 entries
is small enough that memory overhead is negligible. Simpler than indexed arrays
or relying on Godot's internal resource cache.

---

## Security Patterns

### SEC-P-1: CRC32 Checksum for Save File Integrity

**Pattern**: Save files include a CRC32 checksum to detect accidental
corruption. No cryptographic protection needed (single-player offline).

**Design**:

```gdscript
# save_manager.gd
const SAVE_MAGIC = "XIANGKE_SAVE"
const SAVE_VERSION = 1

func save_game(path: String) -> void:
    var data = _serialize_game_state()
    var checksum = CRC32.checksum(data)
    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(SAVE_MAGIC)
    file.store_32(SAVE_VERSION)
    file.store_32(checksum)
    file.store_string(data)

func load_game(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    var magic = file.get_string(len(SAVE_MAGIC))
    if magic != SAVE_MAGIC:
        push_error("Invalid save file format")
        return {}
    var version = file.get_32()
    var stored_checksum = file.get_32()
    var data = file.get_string(file.get_len() - file.get_position())
    var computed_checksum = CRC32.checksum(data)
    if stored_checksum != computed_checksum:
        push_error("Save file checksum mismatch — file may be corrupted")
        return {}
    return _deserialize_game_state(data)
```

**Rationale**: CRC32 is fast and sufficient for corruption detection. No
cryptographic attack surface exists in single-player offline game.

---

## Traceability

| Pattern                    | Source Question | NFR Requirement |
| -------------------------- | --------------- | --------------- |
| RP-1: Placeholder Fallback | RP-1            | RE-1.1, RE-1.2  |
| RP-2: Batch Validation     | RP-2            | RE-1.3, RE-2.1  |
| SP-1: Directory Scanning   | SP-1            | SC-1.3, SC-1.4  |
| SP-2: DLC Support          | SP-2            | SC-1.3, SC-2.1  |
| PP-1: Precomputed Matrix   | PP-1            | PF-3.1, PF-3.2  |
| PP-2: Flat Dictionary      | PP-2            | PF-2.2, PF-3.1  |
| SEC-P-1: CRC32             | SEC-P-1         | SE-2.1          |
