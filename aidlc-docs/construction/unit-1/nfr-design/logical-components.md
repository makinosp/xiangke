# Logical Components — Unit 1: Resources (Shared Data)

## Overview

Logical component design for the data layer, including validation architecture,
localization storage, and versioning strategy.

---

## Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Game Application                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────┐    ┌─────────────────────────────┐ │
│  │  Battle System   │    │  UI / HUD System            │ │
│  │  (future unit)   │    │  (future unit)              │ │
│  └────────┬─────────┘    └──────────────┬──────────────┘ │
│           │                              │               │
│           ▼                              ▼               │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Data Registry (Autoload)                │ │
│  │  ┌──────────────┐  ┌──────────────┐                 │ │
│  │  │ characters   │  │ moves        │                 │ │
│  │  │ Dictionary   │  │ Dictionary   │                 │ │
│  │  └──────────────┘  └──────────────┘                 │ │
│  └─────────────────────────────────────────────────────┘ │
│           ▲                              ▲               │
│           │                              │               │
│  ┌────────┴──────────────────────────────┴─────────────┐ │
│  │                  DataLoader                         │ │
│  │  - discover_characters()                            │ │
│  │  - discover_moves()                                 │ │
│  │  - load_character(id)                               │ │
│  │  - load_move(id)                                    │ │
│  └─────────────────────────────────────────────────────┘ │
│           ▲                                              │
│           │                                              │
│  ┌────────┴─────────────────────────────────────────────┐ │
│  │              DataValidator                           │ │
│  │  - validate_all() -> ValidationResult                │ │
│  │  - validate_character(data) -> Array[Error]          │ │
│  │  - validate_move(data) -> Array[Error]               │ │
│  │  - validate_type_chart() -> Array[Error]             │ │
│  └─────────────────────────────────────────────────────┘ │
│           ▲                                              │
│           │                                              │
│  ┌────────┴─────────────────────────────────────────────┐ │
│  │           DataValidationUtils (Static)               │ │
│  │  - is_valid_id_format(id) -> bool                    │ │
│  │  - is_in_range(value, min, max) -> bool              │ │
│  │  - has_unique_ids(collection) -> bool                │ │
│  │  - is_valid_enum(value, enum_type) -> bool           │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Resource Files (.tres)                  │ │
│  │  res://resources/characters/{id}.tres               │ │
│  │  res://resources/moves/{id}.tres                     │ │
│  │  res://dlc/characters/{id}.tres (optional)           │ │
│  │  res://dlc/moves/{id}.tres (optional)                │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Type Chart (Script Constant)            │ │
│  │  scripts/type_chart.gd                               │ │
│  │  - TYPE_CHART: 7×7 array                            │ │
│  │  - resolve_type_effectiveness()                      │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## LC-1: Hybrid Validation Architecture

**Design**: Shared validation utilities with type-specific rule methods.

### DataValidationUtils (Static Utility Class)

```gdscript
# data_validation_utils.gd
class_name DataValidationUtils
extends RefCounted

static func is_valid_id_format(id: String) -> bool:
    """Check ID is non-empty, lowercase snake_case."""
    if id.is_empty():
        return false
    var regex = RegEx.new()
    regex.compile("^[a-z][a-z0-9_]*$")
    return regex.search(id) != null

static func is_in_range(value: int, min_val: int, max_val: int) -> bool:
    """Check value is within inclusive range."""
    return value >= min_val and value <= max_val

static func has_unique_ids(collection: Array) -> bool:
    """Check all IDs in collection are unique."""
    var seen = {}
    for item in collection:
        if seen.has(item.id):
            return false
        seen[item.id] = true
    return true

static func is_valid_enum(value: int, enum_type: String) -> bool:
    """Check value is valid for the given enum type."""
    match enum_type:
        "Type": return value >= TYPE_WOOD and value <= TYPE_YIN
        "DamageCategory": return value >= 0 and value <= 1
        "EffectType": return value >= EFFECT_NONE and value <= EFFECT_CHARM
        _: return false
```

### DataValidator (Main Validation Orchestrator)

```gdscript
# data_validator.gd
class_name DataValidator
extends RefCounted

var _characters: Dictionary
var _moves: Dictionary
var _errors: Array = []
var _warnings: Array = []

func validate_all() -> ValidationResult:
    _errors.clear()
    _warnings.clear()
    _validate_all_characters()
    _validate_all_moves()
    _validate_type_chart()
    _validate_referential_integrity()
    return ValidationResult.new(_errors, _warnings)

func _validate_all_characters() -> void:
    for id in _characters:
        var data = _characters[id]
        _validate_character_identity(id, data)
        _validate_character_stats(id, data)
        _validate_character_type(id, data)
        _validate_character_moves(id, data)

func _validate_character_stats(id: String, data) -> void:
    var stat_sum = data.hp + data.attack + data.defense + data.speed + data.intelligence + data.spirit
    if stat_sum > 3000:
        _errors.append("CR-2: %s stat sum %d exceeds maximum 3000" % [id, stat_sum])
    for stat_name in ["hp", "attack", "defense", "speed", "intelligence", "spirit"]:
        if not DataValidationUtils.is_in_range(data.get(stat_name), 1, 999):
            _errors.append("CR-2: %s %s out of range [1, 999]" % [id, stat_name])
        if data.get(stat_name) > 500:
            _errors.append("CR-2: %s %s exceeds single-stat maximum 500" % [id, stat_name])
```

**Rationale**: Shared utilities avoid code duplication. Type-specific rules are
organized by category for maintainability.

---

## LC-2: Default Text with Optional Translation Key

**Design**: `.tres` files store default text directly, with optional translation
keys for localization.

### Resource File Format

```tres
# character_zhuge_liang.tres
[gd_resource type="Resource" script_class="CharacterData" format=3]

[resource]
script = ExtResource("1")
id = "zhuge_liang"
name = "诸葛亮"
name_translation_key = "CHAR_ZHUGE_LIANG_NAME"
type = 0  # TYPE_WOOD
secondary_type = 4  # TYPE_WATER
hp = 320
attack = 180
defense = 210
speed = 250
intelligence = 280
spirit = 260
moves = Array[String](["fire_strike", "thunder_bolt", "heal", "strategy_boost"])
description = "蜀の丞相。知略に長ける。"
description_translation_key = "CHAR_ZHUGE_LIANG_DESC"
```

### Resolution Logic

```gdscript
func resolve_display_name(data) -> String:
    if data.name_translation_key != "":
        var translated = tr(data.name_translation_key)
        if translated != data.name_translation_key:  # Translation found
            return translated
    return data.name  # Fallback to default text
```

**Rationale**: Default text is visible in Godot Editor for quick reference.
Translation keys enable multi-language support without changing data files.
Fallback to default text when translation is missing.

---

## LC-3: Hybrid Versioning Strategy

**Design**: Global version for save compatibility, per-file version for detailed
tracking.

### Global Version

```gdscript
# data_version.gd
const DATA_VERSION: int = 1  # Increment on breaking structure changes
```

### Per-File Version

```tres
# character_zhuge_liang.tres
[resource]
script = ExtResource("1")
data_version = 1  # Increment when this file's content changes
id = "zhuge_liang"
...
```

### Version Check Logic

```gdscript
func check_save_compatibility(save_version: int) -> bool:
    return save_version == DATA_VERSION

func get_outdated_files() -> Array:
    var outdated = []
    for id in _characters:
        if _characters[id].data_version < DATA_VERSION:
            outdated.append(id)
    return outdated
```

**Rationale**: Global version prevents loading incompatible saves. Per-file
version enables incremental patching and identifies which files need updates.

---

## Component Dependency Diagram

```
Game Systems (Battle, UI, etc.)
        │
        ▼
┌───────────────────┐
│   Data Registry    │ ← Autoload singleton
│  (characters,     │
│   moves)          │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│    DataLoader      │ ← Discovers and loads .tres files
│  - discover_*()   │
│  - load_*()       │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│   DataValidator    │ ← Validates all loaded data
│  - validate_all() │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ DataValidationUtils│ ← Static utility functions
│  - is_valid_*()   │
└───────────────────┘
          ▲
          │
┌─────────┴─────────┐
│   Type Chart      │ ← Script constant (7×7 matrix)
│  - TYPE_CHART     │
└───────────────────┘
```

---

## Traceability

| Component                   | Source Question | NFR Requirement        |
| --------------------------- | --------------- | ---------------------- |
| DataValidator (Hybrid)      | LC-1            | RE-2.1, RE-2.2         |
| Default + Translation Key   | LC-2            | US-2.1, US-2.2, US-2.3 |
| Hybrid Versioning           | LC-3            | SC-2.2                 |
| DataLoader (Directory Scan) | SP-1            | SC-1.3, SC-1.4         |
| CRC32 Checksum              | SEC-P-1         | SE-2.1                 |
| Precomputed Matrix          | PP-1            | PF-3.1, PF-3.2         |
| Flat Dictionary             | PP-2            | PF-2.2, PF-3.1         |
