## Why

The enemy AI never attacks the player. `execute_player_action` in the Rust
bridge hard-codes its target to `Team::Enemy`'s front, so when the AI turn calls
the same function, the enemy's move is aimed at its own front (and can even
panic on the `split_at_mut` borrow split). Meanwhile the Rust crate already
contains a correct `BasicAi` strategy that derives the opponent team from the
attacker's team, but it is never exposed through the bridge — only used in
tests. The result is duplicated AI logic (GDScript vs. Rust), a broken target,
and an enemy that never harms the player.

## What Changes

- Add a `perform_ai_turn` `#[func]` to `RustBattleSystem` that resolves the
  active participant's team, runs `BasicAi::select_action`, and executes the
  chosen action (attack the opponent's front, or switch with a benched
  participant).
- Reuse the existing damage pipeline (`action::calculate_damage`) so AI attacks
  resolve identically to player attacks, including auto-replacement when the
  player's front is defeated.
- Add a `perform_ai_turn()` wrapper to `BattleFlowService` (GDScript).
- Replace the GDScript-side AI (`_execute_ai_turn`, `_select_best_move`,
  `_should_ai_switch`) in `battle_scene.gd` with a single call to the bridge.
- Remove the duplicated AI decision logic from GDScript so all AI decisions live
  in Rust (`BasicAi`).

## Capabilities

### New Capabilities

- None. This change wires existing Rust AI logic into the bridge rather than
  introducing a brand-new capability surface.

### Modified Capabilities

- `front-line-battle`: The AI action requirement now mandates that AI decisions
  (attack vs. switch) are computed by the Rust `BasicAi` strategy and that the
  AI's attack targets the player's current front character — fixing the
  self-targeting bug.
- `rust-bridge`: The GDExtension bridge gains a `perform_ai_turn` method that
  executes the Rust AI strategy for the active participant and returns the
  action result.

## Impact

- `extensions/godot_bridge/src/lib.rs`: new `#[func] perform_ai_turn`; the
  existing `execute_player_action` remains the player-only path.
- `extensions/battle/src/flow.rs`: `BasicAi`/`AiStrategy` already exist; may add
  a shared action-execution helper to avoid duplicating damage/switch logic.
- `systems/battle/battle_flow_service.gd`: new `perform_ai_turn()` wrapper.
- `scripts/foundation/battle_scene.gd`: remove `_execute_ai_turn`,
  `_select_best_move`, `_should_ai_switch`; call the bridge for enemy turns.
- No data-format or persistence changes. Web (WASM) target unaffected at the
  build level.
