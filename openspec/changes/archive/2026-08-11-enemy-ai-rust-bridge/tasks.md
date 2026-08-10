## 1. Shared damage-execution helper (xiangke-battle)

- [x] 1.1 Add
      `flow::execute_damage_action(state, attacker_index, target_index, move_id, rng)`
      that performs the `split_at_mut` borrow split and calls
      `action::calculate_damage`, returning the `ActionResult`
- [x] 1.2 Add unit tests for `execute_damage_action` covering attack, miss, and
      attacker/defender ordering (attacker index before and after target index)
- [x] 1.3 Run `cargo test -p xiangke-battle` and confirm all tests pass

## 2. Refactor the player action path to use the helper

- [x] 2.1 Refactor `execute_player_action` in
      `extensions/godot_bridge/src/lib.rs` to call `flow::execute_damage_action`
      instead of its inline `split_at_mut` logic, keeping player-only target
      resolution (`Team::Enemy` front) and enemy auto-replacement behavior
      unchanged

## 3. Bridge `perform_ai_turn`

- [x] 3.1 Add `#[func] perform_ai_turn` to `RustBattleSystem` that resolves the
      active participant, runs `BasicAi::select_action`, and executes the action
- [x] 3.2 For `AIAction::Attack`, call `execute_damage_action` targeting the
      player's front (`Team::Player`) and auto-replace the player's defeated
      front via `manager::auto_replace(state, Team::Player)`
- [x] 3.3 For `AIAction::Switch`, call `manager::execute_switch` with the AI's
      team and the selected bench index
- [x] 3.4 Return a result Dictionary with `action_type` (`"attack"`, `"switch"`,
      or `"none"`), `log_message`, and the attack result fields when applicable
- [x] 3.5 Handle `AIAction`/`select_action` returning `None` by returning an
      `action_type = "none"` result
- [x] 3.6 Add a bridge integration test covering an enemy AI attack targeting
      the player's front and an enemy AI switch

## 4. GDScript wiring

- [x] 4.1 Add `perform_ai_turn() -> Dictionary` wrapper to
      `systems/battle/battle_flow_service.gd` forwarding to
      `_rust_system.perform_ai_turn()`
- [x] 4.2 In `scripts/foundation/battle_scene.gd`, replace the enemy branch of
      `_handle_current_turn` to call `_flow_service.perform_ai_turn()` and then
      `_advance_turn()`
- [x] 4.3 Delete `_execute_ai_turn`, `_select_best_move`, and
      `_should_ai_switch` from `battle_scene.gd`

## 5. Verification

- [x] 5.1 Run `cargo test --workspace` and confirm all tests pass
- [x] 5.2 Rebuild the GDExtension and confirm Godot loads it without errors
- [x] 5.3 Run a manual battle and confirm the enemy AI attacks the player's
      front, switches at low HP/type disadvantage, and never attacks its own
      front
- [x] 5.4 Run `openspec validate --change enemy-ai-rust-bridge` and confirm the
      change is valid
