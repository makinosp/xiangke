# Code Summary — Unit 1: Resources (Shared Data)

## Generated Files

### Resource Type Definitions

| File                            | Description                                                                                                     |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `scripts/type_enums.gd`         | Shared enums: `Type` (7 elements), `EffectType` (6 effects), `DamageCategory` (Physical/Arts), `Stat` (5 stats) |
| `scripts/character_data.gd`     | `CharacterData` resource class with all character properties and helper methods                                 |
| `scripts/move_data.gd`          | `MoveData` resource class with all move properties and helper methods                                           |
| `scripts/status_effect_data.gd` | `StatusEffectData` resource class for status effect definitions                                                 |

### Type Chart

| File                    | Description                                                                                                                                       |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scripts/type_chart.gd` | 7×7 type effectiveness matrix implementing 五行 + 陰陽 cycles. Includes `resolve_type_effectiveness()` with dual-type multiplication and clamping |

### Data Infrastructure

| File                                    | Description                                                                                                                                         |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `systems/data/data_validation_utils.gd` | Static validation helpers: `is_valid_id_format`, `is_in_range`, `has_unique_ids`, `is_valid_type`, etc.                                             |
| `systems/data/data_validator.gd`        | Batch validation with summary reporting. Validates against all business rules (CR-1 through MR-7, TR-1 through TR-3)                                |
| `systems/data/data_loader.gd`           | File discovery and loading with graceful degradation. Placeholder fallback for missing/corrupted files (NFR pattern RP-1). Supports DLC directories |
| `autoloads/data_registry.gd`            | Autoload singleton providing in-memory dictionary store with lookup methods for characters and moves                                                |

### Sample Resource Files

| File                                    | Description                                                     |
| --------------------------------------- | --------------------------------------------------------------- |
| `resources/characters/zhuge_liang.tres` | Dual-type character (Wood/Water) — high intelligence and spirit |
| `resources/characters/guan_yu.tres`     | Single-type character (Metal) — high attack and HP              |
| `resources/characters/zhou_yu.tres`     | Dual-type character (Fire/Yang) — high speed and intelligence   |
| `resources/moves/fire_strike.tres`      | Physical fire move with burn chance                             |
| `resources/moves/water_surge.tres`      | Arts water move with speed reduction                            |
| `resources/moves/metal_slash.tres`      | Physical metal move with recoil                                 |
| `resources/moves/wood_heal.tres`        | Non-damaging heal move (50% HP)                                 |
| `resources/moves/earth_barrier.tres`    | Status move with defense boost                                  |
| `resources/moves/iron_cleave.tres`      | Multi-hit physical move (3 hits)                                |
| `resources/moves/war_cry.tres`          | Status move with charm effect                                   |
| `resources/moves/flame_burst.tres`      | High-power arts fire move with recoil                           |

### Project Configuration

| File            | Description                                                           |
| --------------- | --------------------------------------------------------------------- |
| `project.godot` | Godot 4.x project configuration with DataRegistry autoload registered |

## Architecture Overview

```
Game Systems (future units)
        │
        ▼
�─────────────────────────────┐
│   DataRegistry (Autoload)   │
│  - get_character(id)        │
│  - get_move(id)             │
│  - get_all_characters()     │
│  - get_all_moves()          │
│  - get_type_effectiveness() │
└──────────────┬──────────────�
               │ loads from
               ▼
┌─────────────────────────────┐
│       DataLoader            │
│  - discover_characters()    │
│  - discover_moves()         │
│  - load_character(id)       │
│  - load_move(id)            │
│  - placeholder fallback     │
└──────────────┬──────────────┘
               │ validates
               ▼
┌─────────────────────────────┐
│      DataValidator          │
│  - validate_all()           │
│  - validate_character()     │
│  - validate_move()          │
│  - validate_type_chart()    │
└──────────────�──────────────┘
               │ uses
               ▼
┌─────────────────────────────┐
│   DataValidationUtils       │
│  - is_valid_id_format()     │
│  - is_in_range()            │
│  - has_unique_ids()         │
│  - is_valid_type()          │
└─────────────────────────────┘
```

## Business Rules Implemented

- **CR-1 through CR-4**: Character identity, stats, type assignment, move
  assignment
- **MR-1 through MR-7**: Move identity, power/accuracy, effects, stat mods,
  multi-hit, recoil, healing
- **TR-1 through TR-3**: Type validity, effectiveness constraints, Five Elements
  cycle compliance

## NFR Patterns Implemented

- **RP-1**: Graceful degradation with placeholder fallback for missing/corrupted
  data
- **RP-2**: Batch validation with summary reporting
- **SP-1**: Directory scanning for content discovery
- **SP-2**: DLC content pack support (optional directories)
