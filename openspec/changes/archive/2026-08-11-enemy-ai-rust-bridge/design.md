## Context

See proposal.md - Why. The battle runs through a single Rust GDExtension node
(`RustBattleSystem`). Player actions use `execute_player_action`, which
hard-codes the target to `Team::Enemy`'s front. The `xiangke-battle` crate
already ships a `BasicAi` implementation of the `AiStrategy` trait whose
`select_action` returns an `AIAction::Attack` (targeting the opponent team's
front) or `AIAction::Switch`, but it is only exercised by unit tests. GDScript
duplicates AI logic in `battle_scene.gd` (`_execute_ai_turn`,
`_select_best_move`, `_should_ai_switch`) and routes enemy turns through the
player-only `execute_player_action`, which is the source of the self-targeting
bug.

## Goals / Non-Goals

**Goals:**

- Route enemy turns through the existing Rust `BasicAi` strategy via a single
  bridge call.
- Eliminate the duplicated GDScript AI (attack selection and switch heuristics).
- Guarantee AI attacks target the player's front character, never the AI's own
  front.
- Keep the player action path (`execute_player_action`) behavior unchanged.

**Non-Goals:**

- No changes to the `BasicAi` heuristic algorithm itself (keep thresholds and
  move scoring as-is).
- No new data formats, persistence changes, or scene-structure changes.
- No configurable AI difficulty/tuning surface.

## Decisions

### D1: Single `perform_ai_turn` bridge method

Add one `#[func] perform_ai_turn` to `RustBattleSystem` that (a) resolves the
active participant index, (b) runs `BasicAi::select_action`, and (c) executes
the chosen action, returning a Dictionary describing what happened.

Rationale: keeps AI internals inside Rust, gives GDScript a single entry point,
and matches the existing pattern where the bridge owns action execution.

Alternatives considered:

- _Fix the target only_ (make `execute_player_action` target the active
  participant's opponent). Rejected: leaves two competing AI implementations and
  makes the function's contract ambiguous about which team it serves.
- _Two-phase select + execute_ (expose `ai_select_action` and let GDScript call
  the action methods). Rejected: more round trips and leaks AI decision shape
  into GDScript for no benefit.

### D2: Shared damage-execution helper in `xiangke-battle`

Extract a helper (e.g.
`flow::execute_damage_action(state, attacker_index,
target_index, move_id, rng)`)
that performs the `split_at_mut` borrow split, calls `action::calculate_damage`,
and returns the `ActionResult`. Both the player path and `perform_ai_turn` call
it with their respective attacker/target.

Rationale: today `execute_player_action` reimplements the split_at_mut dance.
Factoring it out removes duplication and the panic risk in one place; the AI
attack path gets correct behavior for free because it shares the exact same
damage pipeline as the player.

### D3: Auto-replace the player's defeated front inside `perform_ai_turn`

When the AI's attack defeats the player's front, the bridge calls
`manager::auto_replace(state, Team::Player)` — mirroring how
`execute_player_action` already replaces the enemy's defeated front. The
existing GDScript `_advance_turn` also calls `replace_front_if_defeated`, so the
replacement is idempotent (a no-op if already handled).

Rationale: keeps action execution complete at the bridge layer and the HP
display consistent immediately after the AI acts, exactly as the player path
behaves.

### D4: Remove the GDScript AI

In `battle_scene.gd`, delete `_execute_ai_turn`, `_select_best_move`, and
`_should_ai_switch`. The enemy branch of `_handle_current_turn` becomes a call
to `_flow_service.perform_ai_turn()` (a new thin wrapper in
`battle_flow_service.gd` that forwards to the bridge) followed by
`_advance_turn()`.

Rationale: removes the duplicated heuristics and the wrong-target call site in
one stroke. All AI decisions now live in Rust.

## Risks / Trade-offs

- [Rebuild required] → Rebuild the GDExtension (`cargo build --workspace`); the
  WASM/export build picks it up via the existing pipeline and CI runs
  `cargo test --workspace`.
- [AI behavior shifts subtly] → `BasicAi` excludes healing moves from attack
  candidates and never self-targets; the old GDScript AI also self-targeted, so
  this only makes AI behave sanely. Covered by existing battle unit tests plus a
  manual playthrough.
- [Bridge return contract] → GDScript reads `action_type` / `log_message` /
  damage fields from the result Dictionary; document the shape in the bridge and
  validate with the scene.

## Migration Plan

1. Add `flow::execute_damage_action` helper plus unit tests in `xiangke-battle`.
2. Refactor `execute_player_action` to use the helper.
3. Add `#[func] perform_ai_turn` to the bridge.
4. Add `BattleFlowService.perform_ai_turn()` wrapper in GDScript.
5. Simplify the enemy branch in `battle_scene.gd` and delete the GDScript AI.
6. Run `cargo test --workspace`, rebuild the extension, and do a manual battle.

Rollback: revert the commits; the previous GDScript AI remains functional, so a
bad rollout is recoverable by reverting.

## Open Questions

None that would change the specs or approach. The exact result-Dictionary keys
and helper naming are implementation details left to tasks.
