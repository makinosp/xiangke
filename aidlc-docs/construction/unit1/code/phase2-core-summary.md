# Code Generation Summary — Phase 2: Core Data Types

## Overview

Migrated core data types from GDScript to Rust. All 5 existing files were rewritten to match the GDScript data model, and 2 new files were created. All 55 unit tests pass.

## Files Modified

| File                              | Changes                                                                      |
| --------------------------------- | ---------------------------------------------------------------------------- |
| `rust/core/src/types.rs`          | Added `EffectType`, `DamageCategory`, `Stat` enums. Fixed `TypeChart` matrix layout (row=defender, col=attacker) with correct 1.25 generating values. |
| `rust/core/src/character.rs`      | Changed `id: u32` → `String`. Added `intelligence`/`spirit` to `Stats`. Added `moves: Vec<String>`. Added `has_secondary_type()` and `get_stat_sum()` methods. |
| `rust/core/src/moves.rs`          | Changed `id: u32` → `String`. Replaced `MoveCategory` with `DamageCategory`. Added `accuracy`, `effect`, `effect_chance`, `stat_mod_stat`, `stat_mod_stage`, `hit_count`, `recoil`, `healing` fields. |
| `rust/core/src/status.rs`         | Replaced `StatusType` with `EffectType`. Added `damage_per_turn`, `escalating`, `max_damage_cap`, `stat_mod_stat`, `stat_mod_multiplier` fields. |
| `rust/core/src/lib.rs`            | Added `validator` and `calc` module exports.                                 |

## Files Created

| File                              | Description                                                                 |
| --------------------------------- | --------------------------------------------------------------------------- |
| `rust/core/src/calc.rs`           | `stat_stage_multiplier()` and `calculate_raw_damage()` — 13 tests           |
| `rust/core/src/validator.rs`      | CR-1~4, MR-1~7, TR-1~3 validation rules — 14 tests                         |

## Test Results

**55/55 tests passed** across all modules:
- types: 15 tests (enum roundtrips, TypeChart effectiveness, dual-type clamping)
- character: 4 tests (creation, secondary type, stat sum, serialization)
- moves: 5 tests (creation, non-damaging, stat mod, multi-hit, serialization)
- status: 5 tests (creation, no-damage, none effect, poison escalating, serialization)
- calc: 12 tests (stat stage multipliers, raw damage, stage bounds)
- validator: 14 tests (type chart, move validation, character validation, ID format, result summary)

## Verification

- `cargo check -p xiangke-core`: no warnings
- `cargo test -p xiangke-core`: 55/55 passed
- `cargo check` (workspace): all 3 crates pass
