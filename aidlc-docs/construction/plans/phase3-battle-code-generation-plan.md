# Code Generation Plan — Phase 3: Battle System

## Unit Context

- **Unit**: Phase 3 — Battle System (xiangke-battle crate)
- **Purpose**: Implement core battle mechanics in Rust: participant management, state tracking, damage calculation, turn queue management, battle flow orchestration, and AI logic
- **Dependencies**: Phase 1 (Toolchain) ✅, Phase 2 (Core Data Types) ✅
- **Design Artifacts**:
  - `aidlc-docs/construction/unit-1-migration/functional-design/phase3-battle/domain-entities.md`
  - `aidlc-docs/construction/unit-1-migration/functional-design/phase3-battle/business-logic-model.md`
  - `aidlc-docs/construction/unit-1-migration/functional-design/phase3-battle/business-rules.md`
  - `aidlc-docs/construction/unit-1-migration/nfr-requirements/nfr-requirements.md`
- **GDScript Source**: `systems/battle/battle_participant.gd`, `battle_state.gd`, `action_system.gd`, `battle_manager.gd`, `battle_flow_service.gd`

## Files to Modify

| File | Action | Description |
| ---- | ------ | ----------- |
| `rust/battle/src/participant.rs` | Rewrite | BattleParticipant struct + Team enum (replace TODO stub) |
| `rust/battle/src/state.rs` | Rewrite | BattleState struct + Status enum + BattleError (replace TODO stub) |
| `rust/battle/src/action.rs` | Rewrite | ActionSystem + ActionResult (replace TODO stub) |
| `rust/battle/src/manager.rs` | Rewrite | BattleManager (replace TODO stub) |
| `rust/battle/src/flow.rs` | Rewrite | Battle flow + AI trait + BasicAi (replace TODO stub) |
| `rust/battle/src/lib.rs` | Edit | No changes needed (module declarations already exist) |

---

## Cross-Cutting Design Decisions

Based on Rust language specification review:

### D-1: RNG Ownership (No `ThreadRng` in `BattleState`)
`ThreadRng` does not implement `Serialize` or `Clone`, which would prevent `BattleState` from deriving these traits. All functions requiring randomness accept `&mut ThreadRng` as a parameter. `BattleState` remains free of RNG state.

### D-2: Error Handling (Result, not assert for recoverable errors)
Game logic errors (invalid move selection, defeated participant targeting, out-of-bounds access) are **recoverable errors**, not programming bugs. Use `Result<T, BattleError>` instead of `assert!`/`panic!`. A `BattleError` enum with typed variants is defined in `state.rs`. `assert!` is reserved only for truly unrecoverable invariants (memory corruption, null data).

### D-3: Stat Stage Index Type Safety
Add `Stat::to_index() -> usize` method to avoid raw `as usize` casts. This ensures type safety even if the `Stat` enum variant order changes.

### D-4: AI Strategy Pattern (Trait + Dynamic Dispatch)
Define `AiStrategy` trait with `select_action()` method. Implement `BasicAi` as the default strategy. The battle flow accepts `Box<dyn AiStrategy>`. This enables future AI strategies without changing battle flow code.

---

## Step-by-Step Execution

### Step 1: Implement `participant.rs` — BattleParticipant + Team

- [x] Implement BattleParticipant struct, Team enum, all methods per domain-entities.md
- [x] 11 unit tests (factory valid/invalid, stat stages, effective stats, damage/heal, defeat, status effects)

**Design reference**: domain-entities.md §BattleParticipant, business-rules.md BR-1.x

**Implementation**:
- `Team` enum with `Player`, `Enemy` variants (derive: Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)
- `BattleParticipant` struct with fields:
  - `character_data: Box<CharacterData>` (owned, no lifetime)
  - `current_hp: u32`, `max_hp: u32`
  - `team: Team`, `slot_index: u32`
  - `is_defeated: bool`
  - `stat_stages: [i32; 5]` indexed by `Stat::to_index()`
  - `active_status_effects: Vec<EffectType>`
- Derive: Debug, Clone, Serialize, Deserialize (no RNG field, so serializable)
- Static factory `new(data: Box<CharacterData>, team: Team, slot: u32) -> Result<Self, BattleError>`:
  - Validate non-null data, valid team, slot >= 0
  - Return `Err(BattleError::InvalidParticipant(...))` on failure
- Methods:
  - `stat_stage(stat: Stat) -> i32` — clamped [-6, +6]
  - `apply_stat_stage(stat: Stat, delta: i32)` — clamped via `clamp()`
  - `reset_stat_stages()` — reset all to 0
  - `effective_stat(stat: Stat) -> f64` — base × stage multiplier via `xiangke_core::calc::stat_stage_multiplier`
  - `take_damage(amount: u32) -> u32` — capped to current_hp, sets is_defeated at 0
  - `heal(amount: u32) -> u32` — capped to max_hp
  - `apply_status(effect: EffectType)` — append to Vec
  - `has_status(effect: EffectType) -> bool` — linear search
  - `effective_attack()`, `effective_defense()`, `effective_speed()`, `effective_intelligence()`, `effective_spirit()` — convenience methods delegating to `effective_stat()`

**Tests**:
- `test_participant_create_valid`
- `test_participant_create_invalid_data` — Err expected
- `test_stat_stage_clamping` — apply beyond [-6, +6] clamps
- `test_stat_stage_roundtrip` — apply + reset
- `test_effective_stat` — base × multiplier
- `test_take_damage` — basic damage, cap at 0
- `test_heal` — basic heal, cap at max
- `test_defeated_flag` — HP=0 → is_defeated
- `test_status_application` — apply + has_status

**Verification**: `cargo test -p xiangke-battle` passes participant tests

---

### Step 2: Implement `state.rs` — BattleState + Status + BattleError

- [x] Implement BattleState struct, Status enum, BattleError enum with thiserror
- [x] 12 unit tests (creation valid/invalid, evaluate_status victory/defeat/draw/active, filtering, log, reset, error display)

**Design reference**: domain-entities.md §BattleState, business-rules.md BR-2.x, BR-3.x

**Implementation**:
- `Status` enum: `Active`, `Victory`, `Defeat`, `Draw`, `Escaped` (derive: Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)
- `MAX_TURNS: u32 = 50` constant
- `BattleError` enum for typed error handling:
  - `InvalidParticipant(String)` — participant creation validation failure
  - `InvalidBattleState(String)` — battle state validation failure (no players/enemies)
  - `DefeatedParticipant(String)` — action on defeated participant
  - `MoveNotFound(String)` — move_id missing from move_lookup
  - `NoActiveParticipants` — turn queue empty
  - `BattleAlreadyEnded` — action attempted after battle end
  - `InvalidTarget(String)` — targeting error
- Derive: Debug, Clone, PartialEq, Display, Error (thiserror)
- `BattleState` struct with fields (NO `rng` field — per D-1):
  - `battle_id: String`
  - `participants: Vec<BattleParticipant>`
  - `turn_count: u32`, `round_count: u32`
  - `battle_status: Status`
  - `turn_queue: Vec<usize>`, `turn_queue_index: usize`
  - `active_participant: Option<usize>`
  - `move_lookup: HashMap<String, Box<MoveData>>`
  - `battle_log: Vec<String>`
- Derive: Debug, Clone, Serialize, Deserialize
- Static factory `new(participants, move_lookup) -> Result<Self, BattleError>`:
  - Validate at least 1 player and 1 enemy
  - Return Err on validation failure
- Methods:
  - `player_participants() -> impl Iterator` — filter by Team::Player
  - `enemy_participants() -> impl Iterator` — filter by Team::Enemy
  - `active_participants() -> impl Iterator` — filter non-defeated
  - `evaluate_status() -> Status` — Victory/Defeat/Draw/Active per BR-3.x
  - `add_log(msg: String)` — timestamped "[T{}/R{}] {}" format
  - `recent_log(n: usize) -> Vec<&str>` — last N entries
  - `reset()` — reset runtime state for new battle

**Tests**:
- `test_battle_state_create_valid`
- `test_battle_state_create_no_players` — Err expected
- `test_evaluate_victory` — all enemies defeated → Victory
- `test_evaluate_defeat` — all players defeated → Defeat
- `test_evaluate_draw` — turn_count >= MAX_TURNS → Draw
- `test_evaluate_active` — both sides alive → Active
- `test_participant_filtering` — player/enemy/active filters
- `test_add_log` — log entry format
- `test_recent_log` — last N entries
- `test_reset` — full state reset
- `test_battle_error_display` — error message formatting

**Verification**: `cargo test -p xiangke-battle` passes state tests

---

### Step 3: Implement `action.rs` — ActionSystem + ActionResult

- [x] Implement ActionResult struct, calculate_damage with Result-based error handling
- [x] 12 unit tests (damage physical/arts, miss, STAB, critical, recoil, healing, status, error cases)

**Design reference**: domain-entities.md §ActionResult, business-logic-model.md §2, business-rules.md AR-1.x, AR-2.x, AR-3.x

**Implementation**:
- `ActionResult` struct with fields:
  - `damage_dealt: u32`, `target_index: usize`
  - `hit: bool`, `is_critical: bool`
  - `type_effectiveness: f64`
  - `is_super_effective: bool`, `is_not_very_effective: bool`, `is_immune: bool`
  - `status_applied: Option<EffectType>`, `status_resisted: bool`
  - `recoil_damage: u32`, `heal_amount: u32`
  - `raw_damage: u32`, `log_message: String`
- `ActionSystem` struct (stateless, free functions)
- `calculate_damage(attacker, defender, move, rng) -> Result<ActionResult, BattleError>`:
  - Input validation → return `Err(BattleError::DefeatedParticipant(...))` if attacker/defender defeated
  - Accuracy check via `rng.gen::<f64>() * 100.0 < move.accuracy`
  - Miss → `ActionResult` with `hit: false`, appropriate log
  - Damage formula per business-logic-model.md §2
  - Type effectiveness via `TypeChart::effectiveness_dual()`
  - STAB: 1.2× if attacker primary type matches move type
  - Variance: `rng.gen_range(0.85..1.0)`
  - Final damage modifiers (immunity, critical 6%→1.5×)
  - `defender.take_damage()` — inflicts damage
  - Recoil per AR-2.5/AR-2.6
  - Healing per AR-2.7
  - Status effects per AR-3.x (check resistance, effect chance)
  - Build log_message string
- Free functions:
  - `check_accuracy(accuracy: u32, rng: &mut ThreadRng) -> bool`
  - `check_effect_chance(chance: u32, rng: &mut ThreadRng) -> bool`
  - `has_stab(attacker: &BattleParticipant, mv: &MoveData) -> bool`
  - `build_damage_log(...) -> String`
- Add `Stat::to_index(&self) -> usize` in `types.rs` (or in this module) for type-safe array indexing per D-3

**Tests**:
- `test_damage_calculation_basic` — standard physical hit
- `test_damage_arts` — arts damage (intelligence/spirit)
- `test_damage_immunity` — type_effectiveness == 0.0 → 0 damage
- `test_miss` — accuracy fail → `hit=false`
- `test_stab` — same type → 1.2×
- `test_critical_hit` — 6% chance, 1.5×
- `test_recoil` — recoil > 0 → attacker takes damage
- `test_healing` — healing > 0 → attacker healed
- `test_status_application` — effect applied
- `test_status_resisted` — duplicate effect → status_resisted=true
- `test_raw_damage_formula` — verify (atk × power × 0.8) / def
- `test_damage_on_defeated_attacker` — Err expected
- `test_damage_on_defeated_defender` — Err expected

**Verification**: `cargo test -p xiangke-battle` passes action tests

---

### Step 4: Implement `manager.rs` — BattleManager

- [x] Implement BattleManager free functions (calculate_turn_queue, start_battle, advance_to_next_turn, start_new_round)
- [x] 7 unit tests (turn queue order, exclude defeated, start_battle, advance, new round, empty queue error)

**Design reference**: business-logic-model.md §3, business-rules.md BR-2.x

**Implementation**:
- `BattleManager` struct (stateless, free functions)
- `calculate_turn_queue(participants: &[BattleParticipant], rng: &mut ThreadRng) -> Vec<usize>`:
  - Filter active (non-defeated) by index
  - Build (index, effective_speed) pairs
  - Shuffle to randomize ties (speed tie resolved by random shuffle)
  - Sort by speed descending
  - Return indices vector
- `start_new_round(state: &mut BattleState) -> Result<(), BattleError>`:
  - Increment round_count
  - Recalculate turn_queue with `calculate_turn_queue()`
  - Reset turn_queue_index to 0
  - Return Err if queue empty
- `advance_to_next_turn(state: &mut BattleState, rng: &mut ThreadRng) -> Result<(), BattleError>`:
  - If queue exhausted, call start_new_round
  - Increment turn_queue_index
  - Skip defeated participants
  - Set active_participant
  - Increment turn_count
  - Return Err if no valid participants
- `start_battle(state: &mut BattleState, rng: &mut ThreadRng) -> Result<(), BattleError>`:
  - Validate status == Active
  - Call start_new_round
  - Set first active participant
  - turn_count = 1
  - Add log "Battle started! Round 1."

**Tests**:
- `test_turn_queue_order` — verify speed descending
- `test_turn_queue_excludes_defeated` — defeated participants excluded
- `test_start_battle` — state properly initialized
- `test_advance_to_next_turn` — normal progression
- `test_advance_skips_defeated` — defeated skipped queue
- `test_new_round` — round_count incremented, queue recalculated
- `test_start_battle_no_participants` — Err expected

**Verification**: `cargo test -p xiangke-battle` passes manager tests

---

### Step 5: Implement `flow.rs` — Battle Flow + AI Trait

- [x] Implement AiStrategy trait + BasicAi struct + process_start_of_turn + process_end_of_turn
- [x] 6 unit tests (confusion, DoT, AI selection, trait object dispatch)

**Design reference**: business-logic-model.md §4, §5, §6, business-rules.md AR-4.x

**Implementation**:
- `AIAction` struct:
  - `move_id: String`, `target_index: usize`, `score: f64`
- `AiStrategy` trait (per D-4):
  - `fn select_action(&self, state: &BattleState, participant_index: usize, rng: &mut ThreadRng) -> Option<AIAction>`
- `BasicAi` struct implementing `AiStrategy`:
  - `find_weakest_enemy(state, self_index) -> Option<usize>` — lowest HP % among active opponents
  - `score_move(state, move_id, attacker_index, target_index) -> f64` — power × type_effectiveness × (accuracy / 100.0)
  - `select_action(state, participant_index, rng) -> Option<AIAction>` per AR-4.1 through AR-4.6:
    - Skip healing moves (AI attacks only per AR-4.6)
    - Target weakest enemy per AR-4.4
    - Select highest-scoring move per AR-4.3
    - Fallback to first move on first target per AR-4.5
- `process_start_of_turn(participant: &mut BattleParticipant, rng: &mut ThreadRng) -> Vec<String>`:
  - Confusion check per AR-3.5: 50% chance to skip turn
  - Returns log messages
- `process_end_of_turn(participant: &mut BattleParticipant, rng: &mut ThreadRng) -> Vec<String>`:
  - DoT damage per AR-3.4: max(1, max_hp / 16) per active DoT effect
  - Returns log messages

**Tests**:
- `test_confusion_skip` — confusion → 50% turn skip (probabilistic)
- `test_dot_damage` — DoT effect → damage applied
- `test_basic_ai_selects_weakest` — target is lowest HP opponent
- `test_basic_ai_selects_best_move` — highest scoring move selected
- `test_basic_ai_fallback` — no valid moves → fallback to first
- `test_basic_ai_skips_healing` — healing moves excluded
- `test_score_move` — score = power × effectiveness × accuracy/100
- `test_find_weakest_enemy` — returns index of lowest HP
- `test_ai_strategy_trait_object` — Box<dyn AiStrategy> dispatch works

**Verification**: `cargo test -p xiangke-battle` passes flow tests

---

### Step 6: Run full verification

- [x] `cargo check -p xiangke-battle` — no warnings
- [x] `cargo test -p xiangke-battle` — 45/45 tests pass
- [x] `cargo test` (all crates) — 100/100 pass (55 core + 45 battle, no regressions)
- [x] Verify no use of `assert!` for game-logic errors (only Result-based error handling)

---

### Step 7: Generate Code Summary

- [x] Create `aidlc-docs/construction/unit-1-migration/code/phase3-battle-summary.md` with overview of generated artifacts, module structure, test counts, and type safety measures

---

## Test Plan

| Test Group | File | Tests |
| ---------- | ---- | ----- |
| Participant | `participant.rs` | Factory (valid/invalid), stat stages, effective stats, damage/heal, defeat, status effects |
| State | `state.rs` | Creation (valid/invalid), filtering, evaluate_status (Victory/Defeat/Draw/Active), log, reset, error display |
| Action | `action.rs` | Damage formula (physical/arts), immunity, miss, STAB, critical, recoil, healing, status/effect application/resistance, defeated participant error |
| Manager | `manager.rs` | Turn queue ordering/sorting, exclude defeated, start_battle, advance turn, new round, skip defeated, empty queue error |
| Flow | `flow.rs` | Confusion, DoT, AI target selection, AI move scoring, AI fallback, healing skip, trait object dispatch |

## Execution Order

Steps 1-5 can be written in parallel. Step 6 (verification) must be last. Step 7 (summary) follows Step 6.

**Recommended order**: 1, 2, 3, 4, 5, 6, 7
