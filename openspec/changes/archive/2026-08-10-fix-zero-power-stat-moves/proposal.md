## Why

For moves with `power = 0` (status boosts, healing, status-inflicting moves),
there is a bug where **status-boosting moves like `earth_barrier` activate but
produce no visible effect**.\
`action.rs::calculate_damage()` does not reference `stat_mod_stat` /
`stat_mod_stage` at all, so the behavior promised in the spec (`domain`
spec)—“if `stat_mod_stat` is set, the participant’s stats are modified”—is not
implemented.\
Additionally, non-damaging moves only call `build_damage_log` inside the
`power > 0` block, so `log_message` remains empty and **the move appears not to
have activated**.

## What Changes

- Add a **`stat_mod_target`** field (`SELF` = self / `TARGET` = opponent) to
  `MoveData` so that the target of a status boost can be specified (currently
  there is no way to express the target, making it impossible to implement
  self-boosting moves like `earth_barrier`).
- Add status-boost application logic to `action.rs::calculate_damage()`:
  - `SELF` → apply `apply_stat_stage(stat, stage)` to the attacker
  - `TARGET` → apply `apply_stat_stage(stat, stage)` to the defender
- Generate **log messages for non-damaging moves** (`power == 0`) as well, so
  that move effects (buffs/debuffs/healing/status) appear in the battle log.
- Add tests to verify status-boost application (Rust unit/integration, GDScript
  bridge).
- Set `stat_mod_target = SELF` on the existing `earth_barrier.tres`.

**BREAKING**: None (only adds a field; does not change existing fields).

## Capabilities

### New Capabilities

- None (only fixes existing capabilities; does not introduce new ones).

### Modified Capabilities

- `domain`: Add `stat_mod_target` requirement to Move Data, and add a scenario
  where “status-boosting moves are applied when executed.” Clarify runtime
  application of Stat Stage Multipliers requirements.
- `rust-bridge`: Add parsing/serialization of `stat_mod_target` to `dict_move`
  data conversion.
- `front-line-battle`: Explicitly document that self-targeted (SELF) status
  moves are an exception that do not target the opponent’s front line.

## Impact

- **Rust core**: `extensions/core/src/types.rs` (add `StatModTarget` enum),
  `extensions/core/src/moves.rs` (add `MoveData.stat_mod_target`),
  `extensions/core/src/validator.rs` (add target validity check to MR-4)
- **Rust battle**: `extensions/battle/src/action.rs` (add stat_mod application +
  non-damaging move log generation to `calculate_damage`)
- **Rust bridge**: `extensions/godot_bridge/src/lib.rs` (add `stat_mod_target`
  parsing to `dict_move`)
- **GDScript**: `scripts/type_enums.gd` (add `StatModTarget` enum),
  `scripts/move_data.gd` (add exported `stat_mod_target`),
  `resources/moves/earth_barrier.tres` (set `stat_mod_target = 0`)
- **Data validation**: `systems/data/data_validator.gd` (extend MR-4),
  `tools/data_export.gd` (add `stat_mod_target` to exported JSON),
  `extensions/tools/xiangke_checker` (`MOVE_KEYS` 14→15)
- **Tests**: `extensions/battle/src/action.rs` (unit),
  `extensions/battle/tests/integration.rs` (integration),
  `tests/unit/test_battle_flow_service.gd` (bridge)
- **Not affected**: AI strategy (`BasicAi` / `_select_best_move`) continues not
  to spam non-damaging moves (no change)
