# Integration Test Instructions — Migration Phase 5

## Purpose

Verify the GDScript ↔ Rust GDExtension bridge works end-to-end in the running
Godot project. The Rust `RustBattleSystem` Node owns all battle state; GDScript
wrappers (`BattleFlowService`, `BattleParticipant`, `BattleState`) delegate to
it.

## Setup

### 1. Build Native Extension

```bash
just build-rust
```

### 2. Launch Headless Smoke Test

```bash
godot --headless --quit-after 5
```

Expected: no `RustBattleSystem` registration errors in output.

## Test Scenarios

### Scenario 1: GDExtension Class Registration

- **Description**: `RustBattleSystem` Node is available to GDScript.
- **Steps**: Open `battle_scene.tscn`; confirm no "Identifier not found" errors.
- **Expected**: Scene loads; `BattleFlowService._init()` creates
  `RustBattleSystem`.

### Scenario 2: Battle Start (GDScript → Rust)

- **Setup**: Select 3 player chars + opponent corps in `CorpsRoster`.
- **Steps**: Enter battle; `BattleFlowService.start_battle()` builds char/move
  arrays and calls `_rust_system.start_battle()`.
- **Expected**: `started == true`; participants initialized in Rust state.

### Scenario 3: Player Action Execution

- **Steps**: Select move + target → `execute_player_action(move, target_index)`.
- **Expected**: Rust returns `ActionResult` Dictionary; HP delta applied;
  `action_executed` signal emitted with correct source/target.

### Scenario 4: AI Turn (Rust → GDScript)

- **Steps**: End player turn; Rust `BasicAi` selects action; scene applies it.
- **Expected**: Enemy acts; `log_updated` signal fires; HP changes reflected in
  UI.

### Scenario 5: Battle End & Transition

- **Steps**: Defeat all enemies (or player).
- **Expected**: `battle_ended(status)` signal; `ResultScreen` shows outcome;
  save data updated via `SaveManager`.

### Scenario 6: Full Loop (Title → Result)

- **Steps**: Run complete playthrough headlessly or manually.
- **Expected**: No crashes; all signals wired; state returns to Title.

## Cleanup

- Close Godot; no persistent test artifacts beyond normal save file.
