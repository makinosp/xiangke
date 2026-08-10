## 1. Core Types - StatModTarget Enum

- [x] 1.1 Add `StatModTarget` enum to `extensions/core/src/types.rs` with
      `Self_ = 0` and `Target = 1`
- [x] 1.2 Add `stat_mod_target: StatModTarget` field to `MoveData` struct in
      `extensions/core/src/moves.rs`
- [x] 1.3 Add `has_stat_mod_target()` helper method to `MoveData`
- [x] 1.4 Add validation for `stat_mod_target` in
      `extensions/core/src/validator.rs` (MR-4 extension)

## 2. GDScript Types - StatModTarget Enum

- [x] 2.1 Add `enum StatModTarget { SELF, TARGET }` to `scripts/type_enums.gd`
- [x] 2.2 Add `@export var stat_mod_target: int = TypeEnums.StatModTarget.SELF`
      to `scripts/move_data.gd`
- [x] 2.3 Update `has_stat_mod()` method in `scripts/move_data.gd` to check
      `stat_mod_target`

## 3. Godot Bridge - Data Conversion

- [x] 3.1 Update `dict_move()` in `extensions/godot_bridge/src/lib.rs` to parse
      `stat_mod_target`
- [x] 3.2 Update `part_dict()` in `extensions/godot_bridge/src/lib.rs` to
      include `stat_stages` in result (already exists, verify)
- [x] 3.3 Add `stat_mod_applied` and `stat_mod_stage` to `result_dict()` for
      stat modification feedback

## 4. Battle Action - Stat Modification Application

- [x] 4.1 Add stat modification logic to `calculate_damage()` in
      `extensions/battle/src/action.rs`
- [x] 4.2 Add log message generation for stat modifications (e.g., "Attacker's
      Defense rose sharply!")
- [x] 4.3 Ensure non-damaging moves generate `log_message` even when
      `power == 0`

## 5. Data Validation - GDScript

- [x] 5.1 Update `systems/data/data_validator.gd` MR-4 to validate
      `stat_mod_target` range
- [x] 5.2 Update `tools/data_export.gd` to export `stat_mod_target` field

## 6. Checker Tool

- [x] 6.1 Update `extensions/tools/xiangke_checker/src/main.rs` MOVE_KEYS array
      (14 → 15)

## 7. Data Files

- [x] 7.1 Set `stat_mod_target = 0` (SELF) in
      `resources/moves/earth_barrier.tres`

## 8. Tests

- [x] 8.1 Add Rust unit test for `power=0 + SELF + stat_mod` in
      `extensions/battle/src/action.rs`
- [x] 8.2 Add Rust unit test for `power=0 + TARGET + stat_mod` in
      `extensions/battle/src/action.rs`
- [x] 8.3 Add Rust unit test for non-damaging move log message generation
- [x] 8.4 Add Rust integration test for stat modification in battle flow
- [x] 8.5 Add GDScript integration test in
      `tests/unit/test_battle_flow_service.gd` for stat modification via bridge
