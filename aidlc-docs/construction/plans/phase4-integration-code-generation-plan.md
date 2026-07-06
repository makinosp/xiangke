# Code Generation Plan — Phase 4: GDScript ↔ Rust Integration

## Unit Context

- **Unit**: Phase 4 — Integration (GDScript ↔ Rust Bridge)
- **Purpose**: Wire the Rust battle system (`xiangke-battle` + `xiangke-core`) into Godot via gdext so `battle_scene.gd` calls Rust instead of GDScript battle classes
- **Dependencies**: Phase 1 (Toolchain) ✅, Phase 2 (Core Data Types) ✅, Phase 3 (Battle System) ✅
- **Design Artifacts**: `aidlc-docs/inception/plans/migration-execution-plan.md` (§ Unit 4)
- **GDScript Source (to bridge)**: `systems/battle/` (5 files) + `scripts/type_enums.gd` + `scripts/type_chart.gd`

## Architecture

```
battle_scene.gd
    └── BattleFlowService (GDScript thin wrapper)
            └── RustBattleSystem (gdext Node, lib.rs)
                    ├── xiangke-battle (Rust)  →  participant, state, action, manager, flow
                    └── xiangke-core (Rust)     →  types, character, moves, status, calc

Data flow:
  GDScript CharacterData/MoveData (tres files)
    → Dictionary conversion
    → Rust internal types
    → Battle execution (pure Rust)
    → Dictionary results
    → GDScript display
```

## Data Passing Strategy

- GDScript `CharacterData` (Resource) and `MoveData` (Resource) are passed to Rust as `Dictionary` via `GodotDictionary` in gdext
- Rust converts `Dictionary` ↔ internal Rust types (`CharacterData`, `MoveData`)
- Battle results returned as `Dictionary` / `Array[Dictionary]`
- `RustBattleSystem` Node stores `BattleState` internally, emits Godot signals

## Files to Modify

| File | Action | Description |
| ---- | ------ | ----------- |
| `rust/godot_bridge/src/lib.rs` | Rewrite | Register all bridge classes + `RustBattleSystem` Node |
| `rust/godot_bridge/Cargo.toml` | Edit | Add `serde_json` dep for Dictionary↔Rust conversion |
| `systems/battle/battle_flow_service.gd` | Rewrite | Thin GDScript wrapper delegating to `RustBattleSystem` |
| `systems/battle/battle_participant.gd` | Keep (simplify) | Data holder for UI display; no battle logic |
| `systems/battle/battle_state.gd` | Keep (simplify) | Data holder; status evaluation done in Rust |
| `systems/battle/action_system.gd` | Remove | Replaced by Rust `xiangke-battle::action` |
| `systems/battle/battle_manager.gd` | Remove | Replaced by Rust `xiangke-battle::manager` |
| `scripts/foundation/battle_scene.gd` | Edit | Update signal connections, wrap Rust calls |

## Implementation Steps

### Step 1: Rust Bridge — `godot_bridge/src/lib.rs`
- Define `RustBattleSystem` struct with `#[derive(GodotClass)]`, extends `Node`
- Fields: `battle_state: Option<BattleState>`, `rng: StdRng`
- Signals: `turn_started`, `action_executed`, `participant_defeated`, `battle_ended`, `log_updated`
- `#[func]` methods:
  - `start_battle(player_chars: Array, enemy_chars: Array, move_lookup: Dictionary) -> bool`
  - `execute_player_action(move_data: Dictionary) -> Dictionary`
  - `advance_turn() -> bool`
  - `get_active_participant() -> Dictionary`
  - `get_player_participants() -> Array`
  - `get_enemy_participants() -> Array`
  - `get_recent_log(count: i64) -> Array`
  - `get_battle_status() -> i64`
  - `evaluate_battle_status() -> bool`
  - `stop_battle()`
  - `reset_state()`
- Helper functions: `dict_to_characterdata(d: Dictionary) -> CharacterData`, `dict_to_movedata(d: Dictionary) -> MoveData`, `participant_to_dict(p: &BattleParticipant) -> Dictionary`, `actionresult_to_dict(r: &ActionResult) -> Dictionary`

### Step 2: Rust Bridge — Type conversion helpers
- Implement Dictionary ↔ Rust type conversion functions
- Match Godot Resource field names: `type` → `element`, `secondary_type` → `secondary_element`, etc.
- Enums as `i64` (Godot int) matching GDScript enum values

### Step 3: GDScript — Simplify `battle_participant.gd`
- Remove all battle logic methods (take_damage, heal, apply_status, effective_stat, etc.)
- Keep as pure data holder: `character_data`, `current_hp`, `max_hp`, `team`, `slot_index`, `is_defeated`, `stat_stages`, `active_status_effects`
- Add constructor `from_dict(data: Dictionary) -> BattleParticipant`

### Step 4: GDScript — Simplify `battle_state.gd`
- Remove `evaluate_battle_status()`, `add_log()`, `get_recent_log()`, `reset()` — now in Rust
- Keep as data holder for UI: `participants`, `turn_count`, `round_count`, `battle_status`, `active_participant`

### Step 5: GDScript — Rewrite `battle_flow_service.gd`
- Remove all battle logic (damage calcs, turn queue, AI, status evaluation)
- Delegate to `RustBattleSystem` via `_rust_system: RustBattleSystem`
- Connect to Rust signals and re-emit as GDScript signals
- `start_battle(player_chars, enemy_chars)` → creates move_lookup dict, calls `_rust_system.start_battle()`
- `execute_player_action(move, target)` → converts move to dict, calls Rust
- `get_player_participants()` / `get_enemy_participants()` → call Rust, wrap results in GDScript BattleParticipant

### Step 6: GDScript — Update `battle_scene.gd`
- Signal connections unchanged (still connects to `BattleFlowService`)
- `_on_action_executed` wraps Rust ActionResult Dictionary for display
- Minor adjustments per Rust API changes

## Cross-Cutting Design Decisions

- D-1: **Dictionary serialization** — Use `serde_json` for struct↔Dictionary conversion in Rust; simpler than manual field mapping
- D-2: **RNG ownership** — `StdRng` seeded once in `RustBattleSystem::init()`, used for all battle RNG calls
- D-3: **Signal naming** — Keep exact GDScript signal names for backward compatibility with `battle_scene.gd`
- D-4: **Error handling** — Rust `BattleError` converted to `String` error messages returned to GDScript; no panic propagation
- D-5: **Resource files** — `.tres` files and `CharacterData`/`MoveData` GDScript Resource classes remain unchanged (Godot editor uses them directly)

## Verification

- [x] `cargo build` succeeds with 0 warnings for `xiangke-godot-bridge`
- [x] `cargo test` passes all 103 existing tests (55 core + 48 battle)
- [ ] GDScript `BattleFlowService` can instantiate without errors (requires Godot runtime)
- [x] `systems/battle/action_system.gd` removed without breaking references
- [x] `systems/battle/battle_manager.gd` removed without breaking references
- [ ] No Rust panics in Dictionary conversion paths (requires Godot runtime)
