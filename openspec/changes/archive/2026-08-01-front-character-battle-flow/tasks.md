## 1. Rust battle crate: front/bench model

- [x] 1.1 Add `is_front: bool` field to `BattleParticipant` (initialized false,
      included in serde), update existing constructor tests
- [x] 1.2 Update `calculate_turn_queue` to include only
      `!is_defeated && is_front` participants
- [x] 1.3 Update `start_battle` to mark the first participant of each team as
      front
- [x] 1.4 Add `execute_switch(state, team, bench_index)` in manager: validate
      alive/same team/benched, swap front flags, log message
- [x] 1.5 Add `auto_replace(team)` in manager: promote first living benched
      participant to front, log message
- [x] 1.6 Add helper to find a team's front participant index and living bench
      indices
- [x] 1.7 Add unit tests: switch success/validation, auto-replace order,
      front-only turn queue

## 2. Rust battle crate: AI

- [x] 2.1 Convert `AIAction` to an enum (`Attack { move_id, target_index }` /
      `Switch { bench_index }`)
- [x] 2.2 Update `BasicAi::select_action` to target the opponent's front
      participant only
- [x] 2.3 Add switch heuristic to `BasicAi`: switch when front HP ratio low or
      type disadvantage vs player front
- [x] 2.4 Add unit tests for AI front targeting and switch selection

## 3. GDExtension bridge

- [x] 3.1 Remove `target_index` from `execute_player_action`; resolve enemy
      front participant internally
- [x] 3.2 After player action defeats the enemy front, call `auto_replace` for
      the enemy team
- [x] 3.3 Add `execute_switch(team, bench_index)` bridge method for both teams
      (player and enemy)
- [x] 3.4 Add `get_front_participant(team)` and `get_bench_participants(team)`
      bridge methods
- [x] 3.5 Include `is_front` in `part_dict` output
- [x] 3.6 Add bridge unit tests for target-less action and front/bench queries

## 4. GDScript flow service

- [x] 4.1 Update `execute_player_action` wrapper to drop the target argument
- [x] 4.2 Add `execute_switch(team, bench_index)`,
      `get_front_participant(team)`, `get_bench_participants(team)` wrappers
- [x] 4.3 Add shared helper for automatic bench replacement on front defeat
      (both teams)

## 5. GDScript battle scene UI

- [x] 5.1 Remove target-selection UI (`_show_target_selection`,
      `_on_target_selected`, cancel handler, `_selected_target_index`,
      `_is_selecting_target`)
- [x] 5.2 Add Switch menu: switch button in the action menu listing living
      benched characters; selection calls `execute_switch`
- [x] 5.3 Remove the "Wait (Skip Turn)" button
- [x] 5.4 Split HP display into front (highlighted) and bench (dimmed) sections
- [x] 5.5 Add enemy 3-character fielding helper (deterministic top-3 by combined
      stats from `opponent_corps`)
- [x] 5.6 Update `_execute_ai_turn` to target only the player's front and add AI
      switch decision
- [x] 5.7 Handle automatic replacement after the AI defeats the player's front
      (call shared helper)

## 6. Verification

- [x] 6.1 Update existing Rust tests affected by the front-only turn queue
- [x] 6.2 Add GDScript tests for front-line battle flow (switch, replacement,
      turn advancement with benched team)
- [x] 6.3 Run `cargo fmt --check`, `cargo clippy`, `cargo test --workspace`, and
      GDScript test runner; all pass
- [x] 6.4 Manual play verification: no target selection UI, switch works, defeat
      auto-replaces, AI switches, stat stages/status preserved on switch
