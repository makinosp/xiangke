# Code Generation Plan — Phase 2: Core Data Types

## Overview

Migrate core data types from GDScript (`scripts/` + `resources/`) to Rust (`rust/core/src/`). Fix stub implementations to fully match GDScript's data model and business rules as defined in the Functional Design artifacts.

## Files to Modify

| File                             | Action  | Description                                   |
| -------------------------------- | ------- | --------------------------------------------- |
| `rust/core/src/types.rs`         | Rewrite | Add `EffectType`, `DamageCategory`, `Stat` enums; fix `TypeChart` row/col layout |
| `rust/core/src/character.rs`     | Rewrite | Change `id: u32` → `id: String`; add `intelligence`/`spirit` to `Stats`; rename fields |
| `rust/core/src/moves.rs`         | Rewrite | Change `id: u32` → `id: String`; replace `MoveCategory` with `DamageCategory`; add all missing fields |
| `rust/core/src/status.rs`        | Rewrite | Replace `StatusType` with `EffectType`; add all missing business fields |
| `rust/core/src/lib.rs`           | Edit    | Add `validator` and `calc` module exports     |

## Files to Create

| File                             | Description                                    |
| -------------------------------- | ---------------------------------------------- |
| `rust/core/src/validator.rs`     | Data validation logic (migrated from GDScript `DataValidator` + `DataValidationUtils`) |
| `rust/core/src/calc.rs`          | Pure calculation helpers (stat stage multiplier, raw damage formula) |

---

## Step-by-Step Execution

### Step 1: Rewrite `types.rs` — Add enums, fix TypeChart matrix

**Current issues**: Missing `EffectType`, `DamageCategory`, `Stat` enums. TypeChart is row/col transposed. Missing 1.25 values (generating relationships).

**Changes**:
- Add `EffectType` enum (None, Burn, Poison, Confusion, Chain, Charm) with `#[repr(u8)]`
- Add `DamageCategory` enum (Physical, Arts) with `#[repr(u8)]`
- Add `Stat` enum (Attack, Defense, Speed, Intelligence, Spirit) with `#[repr(u8)]`
- Add `impl TypeElement` with `const ALL` and `const COUNT`
- Fix `TypeChart` matrix: row = defender, column = attacker (was inverted)
- Fix matrix values: add 1.25 for generating relationships matching GDScript `TYPE_CHART`
- `effectiveness(attack, defense)` → returns `self.0[defense as usize][attack as usize]`
- `effectiveness_dual(attack, def_a, def_b)` → product clamped to [0.25, 4.0]
- Update tests to verify correct values

**Verification**: `cargo test -p xiangke-core` passes type chart tests

---

### Step 2: Rewrite `character.rs` — Fix fields and add methods

**Current issues**: `id: u32`, missing `intelligence`/`spirit`, uses `display_name` instead of `name`, missing `moves: Vec<String>`.

**Changes**:
- `id: u32` → `id: String`
- Remove `display_name`, keep `name: String`
- Add `intelligence: u32` and `spirit: u32` to `Stats`
- Add `moves: Vec<String>` to `CharacterData`
- Add `description: String` (already present)
- Remove old `Stats::new()` constructor
- Add methods: `has_secondary_type() -> bool`, `get_stat_sum() -> u32`
- Update test to use `String` IDs

**Verification**: `cargo test -p xiangke-core` passes character tests

---

### Step 3: Rewrite `moves.rs` — Fix fields, use DamageCategory

**Current issues**: `id: u32`, non-standard `MoveCategory`, missing `accuracy` (as u32), `effect`, `effect_chance`, `stat_mod_stat`, `stat_mod_stage`, `hit_count`, `recoil`, `healing`.

**Changes**:
- `id: u32` → `id: String`
- Remove `MoveCategory`; use `crate::types::DamageCategory`
- Remove `display_name`; keep `name: String`
- `accuracy: f64` → `accuracy: u32` (1-100)
- `effect_chance: f64` → `effect_chance: u32` (0-100)
- Add `effect: EffectType`
- Add `stat_mod_stat: Option<Stat>`
- Add `stat_mod_stage: i32` (-3 to +3)
- Add `hit_count: u32` (1-5)
- Add `recoil: u32` (0-100)
- Add `healing: u32` (0-100)
- Add methods: `has_stat_mod() -> bool`, `is_damaging() -> bool`
- Update test to use `String` IDs and new field types

**Verification**: `cargo test -p xiangke-core` passes move tests

---

### Step 4: Rewrite `status.rs` — Use EffectType, add business fields

**Current issues**: Uses `StatusType` enum instead of `EffectType`, missing all business fields (damage_per_turn, escalating, etc.), missing `None` variant.

**Changes**:
- Remove `StatusType` enum; use `crate::types::EffectType`
- Change `status_type: StatusType` → `status_type: EffectType`
- Remove `display_name`; keep `name: String`
- Remove `duration: u32`
- Add `damage_per_turn: f64`
- Add `escalating: bool`
- Add `max_damage_cap: f64`
- Add `stat_mod_stat: Option<Stat>`
- Add `stat_mod_multiplier: f64`
- Add methods: `has_damage_over_time() -> bool`, `has_stat_modification() -> bool`
- Update test

**Verification**: `cargo test -p xiangke-core` passes status tests

---

### Step 5: Create `calc.rs` — Pure calculation helpers

**New file** with:
- `stat_stage_multiplier(stage: i32) -> f64` — positive: `(2 + stage) / 2`, negative: `2 / (2 - stage)`, range assert [-6, +6]
- `calculate_raw_damage(attack: f64, power: u32, defense: f64) -> u32` — `max(1, (atk * power * 0.8) / def).ceil()`
- Comprehensive tests covering all stage values and edge cases

**Verification**: `cargo test -p xiangke-core` passes calc tests

---

### Step 6: Create `validator.rs` — Data validation logic

**New file** with:
- `ValidationError` struct (code, message, context fields + Display)
- `ValidationResult` struct (errors, warnings, file counts + summary generation)
- `validate_character(data: &CharacterData, moves: &[MoveData]) -> Result<(), Vec<ValidationError>>` — CR-1 through CR-4
- `validate_move(data: &MoveData) -> Result<(), Vec<ValidationError>>` — MR-1 through MR-7
- `validate_type_chart(chart: &TypeChart) -> Result<(), Vec<ValidationError>>` — TR-1 through TR-3
- ID format validation (lowercase snake_case regex)
- Range checks, enum validity checks
- Tests for all validation rules

**Verification**: `cargo test -p xiangke-core` passes validator tests

---

### Step 7: Edit `lib.rs` — Add new module exports

**Changes**:
- Add `pub mod validator;`
- Add `pub mod calc;`

---

### Step 8: Run full verification

- `cargo check -p xiangke-core`
- `cargo test -p xiangke-core`
- Verify all tests pass

---

## Test Plan

| Test Group   | File            | Tests                                                              |
| ------------ | --------------- | ------------------------------------------------------------------ |
| Types        | `types.rs`      | Enum round-trips, TypeChart effectiveness (Wood→Fire=1.25, Water→Fire=2.0, etc.), dual-type clamping |
| Character    | `character.rs`  | Creation with String ID, secondary type, stat sum, serialization   |
| Move         | `moves.rs`      | Creation with all field types, damaging/non-damaging, stat mod     |
| Status       | `status.rs`     | Creation, DOT detection, stat mod detection, None handling         |
| Calc         | `calc.rs`       | stat_stage_multiplier (all stages +6 to -6), raw damage formula, edge cases |
| Validator    | `validator.rs`  | Valid data passes, constraint violations produce correct errors, multiple errors accumulate |

---

## Execution Order

Steps 1-6 are independent and can be written together. Step 7 (`lib.rs`) must follow steps 5-6. Step 8 must be last.

**Recommended order**: 1, 2, 3, 4, 5, 6, 7, 8
