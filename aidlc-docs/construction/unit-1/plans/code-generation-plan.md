# Code Generation Plan — Unit 1: Resources (Shared Data)

## Objective

Generate all GDScript code, resource files, and supporting artifacts for the
shared data layer (Unit 1) of the Three Kingdoms turn-based command battle game.

## Context Summary

- **Project Type**: Greenfield — Godot 4.x 2D game
- **Primary Export**: Web (HTML5/WebAssembly)
- **Data Layer**: `.tres` resource files + GDScript autoloads
- **Data Size**: <200KB total, preloaded at startup
- **Workspace Root**: `.` (greenfield single-unit structure: `src/`, `scripts/`,
  `resources/`)
- **Dependencies**: None (base unit — all other units depend on this one)

---

## Unit Context

### Stories Implemented by This Unit

Unit 1 defines all shared game data used across systems:

- Character definitions (name, stats, type, move list)
- Move data (name, power, type, accuracy, effects)
- Type effectiveness charts (7×7 matrix with 五行 + 陰陽 relationships)
- Status effect definitions (Burn, Poison, Confusion, Chain, Charm)

### Expected Interfaces and Contracts

| Interface             | Type                 | Purpose                                                     |
| --------------------- | -------------------- | ----------------------------------------------------------- |
| `CharacterData`       | Resource (`.tres`)   | Character entity data container                             |
| `MoveData`            | Resource (`.tres`)   | Move entity data container                                  |
| `TypeChart`           | GDScript (`.gd`)     | Type effectiveness lookup + resolution                      |
| `DataRegistry`        | Autoload singleton   | In-memory data store (characters + moves dictionaries)      |
| `DataLoader`          | GDScript (`.gd`)     | Discovers and loads `.tres` files from resource directories |
| `DataValidator`       | GDScript (`.gd`)     | Validates all data against business rules                   |
| `DataValidationUtils` | Static utility class | Shared validation helper functions                          |

### Resource File Locations

- `resources/characters/{id}.tres` — Character resource files
- `resources/moves/{id}.tres` — Move resource files

### Key Design Decisions

1. **Hybrid Validation Architecture**: Shared utilities + type-specific rules
2. **Graceful Degradation**: Placeholder fallback for missing/corrupted data
3. **Batch Validation**: Collect all violations, report summary
4. **Type Chart as Script Constant**: 7×7 matrix embedded in GDScript
5. **No STAB in v1**: Type effectiveness only (no same-type attack bonus)

---

## Plan Steps

### Project Structure Setup

- [x] **Step 1**: Create project directory structure (`scripts/`, `autoloads/`,
      `systems/data/`, `resources/characters/`, `resources/moves/`)

### Resource Type Definitions

- [x] **Step 2**: Create `scripts/character_data.gd` — CharacterData resource
      class (extends Resource)
- [x] **Step 3**: Create `scripts/move_data.gd` — MoveData resource class
      (extends Resource)
- [x] **Step 4**: Create `scripts/type_enums.gd` — Shared enums (Type,
      EffectType, DamageCategory, Stat)
- [x] **Step 5**: Create `scripts/status_effect_data.gd` — StatusEffectData
      resource class

### Type Chart Implementation

- [x] **Step 6**: Create `scripts/type_chart.gd` — Type effectiveness 7×7
      matrix + `resolve_type_effectiveness()` function

### Data Validation Utilities

- [x] **Step 7**: Create `systems/data/data_validation_utils.gd` — Static
      validation helper functions (is_valid_id_format, is_in_range,
      has_unique_ids, is_valid_enum)

### Data Validator

- [x] **Step 8**: Create `systems/data/data_validator.gd` — Batch validation
      with summary reporting (validate_all, validate_character, validate_move,
      validate_type_chart)

### Data Loader

- [x] **Step 9**: Create `systems/data/data_loader.gd` — File discovery and
      loading with graceful degradation (discover_characters, discover_moves,
      load_character, load_move, placeholder fallback)

### Data Registry (Autoload)

- [x] **Step 10**: Create `autoloads/data_registry.gd` — In-memory dictionary
      store with lookup methods (get_character, get_move, get_all_characters,
      get_all_moves, is_loaded)

### Sample Resource Files

- [x] **Step 11**: Create 3 sample character `.tres` files in
      `resources/characters/` (demonstrating single-type and dual-type
      characters)
- [x] **Step 12**: Create 7 sample move `.tres` files in `resources/moves/`
      (demonstrating different damage categories, effects, and special
      properties)

### Godot Project Configuration

- [x] **Step 13**: Create `project.godot` — Godot project configuration file
      with autoload registration

### Code Summaries (Documentation)

- [x] **Step 14**: Create
      `aidlc-docs/construction/unit-1/code/data-layer-summary.md` — Markdown
      summary of generated code

---

## Story Traceability

| Step       | Story Coverage                                     |
| ---------- | -------------------------------------------------- |
| Step 1     | Project foundation                                 |
| Step 2-5   | Character/Move/Type/Status data definitions        |
| Step 6     | Type effectiveness chart                           |
| Step 7-8   | Data validation (business rules CR-1 through MR-7) |
| Step 9     | Data loading with graceful degradation (RP-1)      |
| Step 10    | Data registry for cross-system access              |
| Step 11-12 | Sample data demonstrating all entity types         |
| Step 13    | Godot project integration                          |
| Step 14    | Documentation                                      |

---

## Generation Notes

- All code comments and documentation in English (per project convention)
- GDScript follows Godot 4.x conventions (typed signals, `@onready`, `@export`)
- Resource classes use `@export` properties for Godot editor integration
- Validation follows business rules from `business-rules.md`
- Type chart matrix from `domain-entities.md` Type Chart section
- Graceful degradation per NFR pattern RP-1
- Batch validation per NFR pattern RP-2
