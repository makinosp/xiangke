# Functional Design — Unit 1 (Rust): Core Data Types Migration

## Overview

Migrate the game's core data types from GDScript (`scripts/` + `resources/`) to
Rust (`rust/core/src/`). This phase reimplements the shared domain entities —
type system, character data, move data, status effect data, and their associated
business logic — as Rust structs and enums with full validation.

The existing `rust/core/src/` has stub implementations that must be revised to
fully match GDScript's data model and business rules as defined in Unit 1's
functional design artifacts.

---

## Scope

| Area                | GDScript Source                  | Rust Target                                   |
| ------------------- | -------------------------------- | --------------------------------------------- |
| Type system enums   | `scripts/type_enums.gd`          | `rust/core/src/types.rs`                      |
| Type chart          | `scripts/type_chart.gd`          | `rust/core/src/types.rs`                      |
| Character data      | `scripts/character_data.gd`      | `rust/core/src/character.rs`                  |
| Move data           | `scripts/move_data.gd`           | `rust/core/src/moves.rs`                      |
| Status effect data  | `scripts/status_effect_data.gd`  | `rust/core/src/status.rs`                     |
| Data validation     | `systems/data/data_validator.gd` | `rust/core/src/validator.rs`                  |
| Type resource files | `resources/characters/*.tres`    | N/A (data loaded at runtime via Godot bridge) |

---

## 1. Domain Entities

### 1.1 TypeElement (types.rs)

**Current Rust issue**: Missing `EffectType`, `DamageCategory`, `Stat` enums;
type chart is row/column transposed.

**Target design** — align with `scripts/type_enums.gd`:

```rust
/// The seven element types based on 五行 (Five Elements) + 陰陽 (Yin-Yang).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, EnumString, FromRepr)]
#[repr(u8)]
pub enum TypeElement {
    Wood  = 0,  // 木
    Fire  = 1,  // 火
    Earth = 2,  // 土
    Metal = 3,  // 金
    Water = 4,  // 水
    Yang  = 5,  // 陽
    Yin   = 6,  // 陰
}

/// Status effect types inflictable by moves.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, EnumString, FromRepr)]
#[repr(u8)]
pub enum EffectType {
    None       = 0,
    Burn       = 1,  // 炎上 — deals damage over time each turn
    Poison     = 2,  // 毒 — deals increasing damage each turn
    Confusion  = 3,  // 混乱 — may cause target to hit itself
    Chain      = 4,  // 連環 — links damage across multiple targets
    Charm      = 5,  // 魅了 — reduces target's attack stat
}

/// Damage category determining which stats are used in calculation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, EnumString, FromRepr)]
#[repr(u8)]
pub enum DamageCategory {
    Physical = 0,  // Uses Attack / Defense
    Arts     = 1,  // Uses Intelligence / Spirit
}

/// Modifiable stat identifiers for stage modifications.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Display, EnumString, FromRepr)]
#[repr(u8)]
pub enum Stat {
    Attack       = 0,
    Defense      = 1,
    Speed        = 2,
    Intelligence = 3,
    Spirit       = 4,
}
```

### 1.2 TypeChart (types.rs)

**Current Rust issue**: Stored as `[[f64; 7]; 7]` with row=attacker,
column=defender — **transposed** from GDScript where row=defender,
column=attacker. The `effectiveness()` method signature assumes
`(attack, defense)` which is fine, but the internal matrix layout must match so
that `effectiveness(a, d)` returns `TYPE_CHART[d][a]` as GDScript does.

**Target design** — keep `[[f64; 7]; 7]` but ensure internal row-index =
defender, col-index = attacker:

```rust
pub struct TypeChart([[f64; TypeElement::COUNT]; TypeElement::COUNT]);
```

Implementation notes:

- Default: same 7×7 matrix from GDScript `TYPE_CHART`
- `effectiveness(attack, defense)` → returns `self.0[defense][attack]`
  (GDScript: `TYPE_CHART[defender][attacker]`)
- `effectiveness_dual(attack, defense_a, defense_b)` → product clamped to
  `[0.25, 4.0]`
- Const values: `MIN_MULTIPLIER = 0.25`, `MAX_MULTIPLIER = 4.0`

### 1.3 CharacterData (character.rs)

**Current Rust issue**: Uses `id: u32`, missing `secondary_type`, missing
`intelligence`/`spirit` in Stats, uses `display_name` instead of `name`.

**Target design** — align with `scripts/character_data.gd` +
`resources/characters/*.tres`:

```rust
pub struct Stats {
    pub hp: u32,            // 1-999
    pub attack: u32,        // 1-999
    pub defense: u32,       // 1-999
    pub speed: u32,         // 1-999
    pub intelligence: u32,  // 1-999 (was missing!)
    pub spirit: u32,        // 1-999 (was missing!)
}

pub struct CharacterData {
    pub id: String,                    // lowercase snake_case, e.g. "guan_yu" (was u32!)
    pub name: String,                  // display name, e.g. "関羽" (was display_name)
    pub element: TypeElement,          // primary type
    pub secondary_element: Option<TypeElement>,  // optional second type
    pub base_stats: Stats,
    pub moves: Vec<String>,            // list of 4 move IDs
    pub description: String,
}
```

Methods:

- `has_secondary_type() -> bool`
- `get_stat_sum() -> u32` (sum of all 6 stats)

### 1.4 MoveData (moves.rs)

**Current Rust issue**: Uses `id: u32`, missing `accuracy`, `effect`,
`effect_chance`, `stat_mod_stat`, `stat_mod_stage`, `hit_count`, `recoil`,
`healing` fields. `MoveCategory` is non-standard.

**Target design** — align with `scripts/move_data.gd` +
`resources/moves/*.tres`:

```rust
pub struct MoveData {
    pub id: String,                    // lowercase snake_case (was u32!)
    pub name: String,                  // display name (was display_name)
    pub element: TypeElement,          // move's type
    pub power: u32,                    // 0-255, 0 = non-damaging
    pub accuracy: u32,                 // 1-100 (was f64!)
    pub effect: EffectType,            // special effect category
    pub effect_chance: u32,            // 0-100
    pub stat_mod_stat: Option<Stat>,   // stat to modify (was missing)
    pub stat_mod_stage: i32,           // -3 to +3 (was missing)
    pub hit_count: u32,                // 1-5 (was missing)
    pub recoil: u32,                   // 0-100 (percent of damage) (was missing)
    pub healing: u32,                  // 0-100 (percent of max HP) (was missing)
    pub damage_category: DamageCategory, // Physical or Arts
    pub description: String,
}
```

Methods:

- `has_stat_mod() -> bool`
- `is_damaging() -> bool`

### 1.5 StatusEffectData (status.rs)

**Current Rust issue**: Missing `NONE` variant in StatusType. Missing all
properties except `status_type` and `name`. Missing `display_name`. Missing all
business methods.

**Target design** — align with `scripts/status_effect_data.gd`:

```rust
pub struct StatusEffectData {
    pub status_type: EffectType,  // reuses EffectType from types.rs (matching GDScript's pattern)
    pub name: String,                      // display name
    pub description: String,
    pub damage_per_turn: f64,              // 0.0-1.0 (fraction of max HP)
    pub escalating: bool,                  // damage increases each turn
    pub max_damage_cap: f64,               // 0.0-1.0
    pub stat_mod_stat: Option<Stat>,       // stat affected (was -1)
    pub stat_mod_multiplier: f64,          // e.g. 0.5 for Burn's attack reduction
}
```

Methods:

- `has_damage_over_time() -> bool`
- `has_stat_modification() -> bool`

---

## 2. Business Logic Models

### 2.1 Type Effectiveness Resolution

Already partially implemented in `types.rs` — needs the matrix fix
(row=defender, col=attacker).

**Process** (unchanged from Unit 1 FD):

1. Lookup `chart[defender][attacker]` → primary multiplier
2. If no secondary type → return primary
3. Lookup `chart[secondary][attacker]` → secondary multiplier
4. Return product clamped to `[0.25, 4.0]`

### 2.2 Stat Stage Calculation

The stat stage system from `BattleParticipant` uses a formula:

- Positive stages: `(2.0 + stage) / 2.0`
- Negative stages: `2.0 / (2.0 - stage)`

This is a pure calculation that belongs in the types module since it has no
dependency on Godot. Add as:

```rust
pub fn stat_stage_multiplier(stage: i32) -> f64 {
    match stage.cmp(&0) {
        std::cmp::Ordering::Equal => 1.0,
        std::cmp::Ordering::Greater => (2.0 + stage as f64) / 2.0,
        std::cmp::Ordering::Less => 2.0 / (2.0 - stage as f64),
    }
}
```

With range check: stage must be in `[-6, 6]`.

### 2.3 Damage Calculation Helper

The base damage formula from `action_system.gd`:

```
raw_damage = max(1, (effective_atk * power * 0.8) / effective_def)
```

Since this is a pure math function with no Godot dependencies, it belongs in
`rust/core/src/`:

```rust
pub fn calculate_raw_damage(attack: f64, power: u32, defense: f64) -> u32 {
    let def = defense.max(1.0);
    ((attack * power as f64 * 0.8) / def).ceil().max(1.0) as u32
}
```

### 2.4 Status Effect Application Rules

- A character can only have one status effect at a time (new replaces old).
- Burn and Poison are mutually exclusive.
- Confusion, Chain, and Charm are mutually exclusive.
- These rules are enforced at the battle system level (Phase 3), but the data
  model must support them.

---

## 3. Business Rules (Validation)

### 3.1 Character Validation Rules (CR-1 through CR-4)

```rust
pub fn validate_character(data: &CharacterData) -> Result<(), Vec<ValidationError>> {
    // CR-1: id must be non-empty lowercase snake_case
    // CR-2: all stats in [1, 999]; sum <= 3000; no stat > 500
    // CR-3: secondary_element must differ from element
    // CR-4: exactly 4 moves; all valid IDs; at least one damaging move
}
```

### 3.2 Move Validation Rules (MR-1 through MR-7)

```rust
pub fn validate_move(data: &MoveData) -> Result<(), Vec<ValidationError>> {
    // MR-1: id must be non-empty lowercase snake_case
    // MR-2: power in [0, 255]; accuracy in [1, 100]
    // MR-3: effect None → effect_chance 0; effect not None → effect_chance in [1, 100]
    // MR-4: stat_mod_stage in [-3, +3]
    // MR-5: hit_count in [1, 5]
    // MR-6: recoil > 0 → power > 0
    // MR-7: healing in [0, 100]
}
```

---

## 4. File Structure Changes

### Modified files:

| File                         | Action  | Description                                 |
| ---------------------------- | ------- | ------------------------------------------- |
| `rust/core/src/types.rs`     | Rewrite | Add enums, fix TypeChart matrix layout      |
| `rust/core/src/character.rs` | Rewrite | Fix id type, add missing fields/methods     |
| `rust/core/src/moves.rs`     | Rewrite | Fix id type, add all missing fields/methods |
| `rust/core/src/status.rs`    | Rewrite | Add None variant + all missing fields       |
| `rust/core/src/lib.rs`       | Minor   | Add new module exports if needed            |

### New files:

| File                         | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| `rust/core/src/validator.rs` | Data validation logic (migrated from GDScript) |
| `rust/core/src/calc.rs`      | Pure calculation helpers (stat stage, damage)  |

---

## 5. Test Plan

### Types tests (`rust/core/src/types.rs`)

- Enum serialization/deserialization round-trips
- TypeChart effectiveness for key matchups (Wood→Fire=1.25, Water→Fire=2.0, Wood→Metal=2.0, etc.)
- TypeChart effectiveness_dual clamping

### Character tests (`rust/core/src/character.rs`)

- Character creation with valid data
- Character with secondary type
- Stat sum calculation
- Serialization round-trip

### Move tests (`rust/core/src/moves.rs`)

- Move creation with all field types
- Damaging vs non-damaging classification
- Stat mod detection
- Serialization round-trip

### Status tests (`rust/core/src/status.rs`)

- Status creation with all field types
- Damage-over-time detection
- Stat modification detection
- `None` handling

### Validation tests (`rust/core/src/validator.rs`)

- Valid character/move passes validation
- Various constraint violations produce correct errors
- Multiple errors are accumulated (not short-circuited)

### Calculation tests (`rust/core/src/calc.rs`)

- stat_stage_multiplier: 0→1.0, +1→1.5, -1→0.667, +6→4.0, -6→0.25
- calculate_raw_damage: known values produce expected results
- Edge cases: minimum damage guarantee, defense clamping
