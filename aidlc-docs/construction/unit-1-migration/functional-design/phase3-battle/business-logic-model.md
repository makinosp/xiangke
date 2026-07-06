# Phase 3: Battle System — Business Logic Model (Rust)

## Module Architecture

```
xiangke-battle crate
├── participant.rs   → BattleParticipant, Team
├── state.rs         → BattleState, Status
├── action.rs        → ActionSystem, ActionResult
├── manager.rs       → BattleManager
└── flow.rs          → BattleFlowService (GDScript wrapper calls into these modules)
```

Flow (ownership & call graph):

```
GDScript wrapper (battle_flow_service.gd)
  │
  ├── calls BattleManager::start_battle(state)       [state.rs, manager.rs]
  ├── calls BattleManager::advance_to_next_turn(state)
  │
  ├── loop:
  │   ├── state.evaluate_status()                    [state.rs]
  │   ├── process_start_of_turn(participant)          [state.rs / participant.rs]
  │   ├── if enemy: AI logic → action                 [flow.rs]
  │   │   └── ActionSystem::calculate_damage(...)     [action.rs]
  │   ├── if player: await player_action              [GDScript]
  │   │   └── ActionSystem::calculate_damage(...)
  │   └── process_end_of_turn(participant)            [state.rs / participant.rs]
  │
  └── state.evaluate_status() → end battle
```

---

## 1. Stat Stage Calculation

**Module:** `participant.rs`

**Logic:** (migrated from `BattleParticipant.gd`)

- Each participant has 5 stat stages indexed by `Stat` enum (Attack, Defense, Speed, Intelligence, Spirit).
- Default value: 0 (neutral).
- `apply_stat_stage(stat, delta)`: new_value = clamp(current + delta, -6, +6).
- Stage multiplier (delegates to `xiangke_core::calc::stat_stage_multiplier`):
  - stage == 0: 1.0
  - stage > 0: (2.0 + stage) / 2.0  (e.g., +6 → 8/2 = 4.0×)
  - stage < 0: 2.0 / (2.0 - stage)  (e.g., -6 → 2/8 = 0.25×)
- `effective_stat(stat)`: base_stat × stage_multiplier (base from `CharacterData`).

**GDScript source:** `battle_participant.gd:68-107`

---

## 2. Damage Calculation

**Module:** `action.rs` → `ActionSystem::calculate_damage()`

**Formula (unchanged from GDScript):**

```
effective_atk = attacker.effective_stat(Stat::Attack)    [if physical]
             = attacker.effective_stat(Stat::Intelligence) [if arts]
effective_def = defender.effective_stat(Stat::Defense)    [if physical]
              = defender.effective_stat(Stat::Spirit)     [if arts]
effective_def = max(effective_def, 1.0)  // prevent division by zero

raw_damage = max(1, (effective_atk * move.power * 0.8) / effective_def)

type_effectiveness = TypeChart::effectiveness_dual(
    move.type,
    defender.character_data.type,
    defender.character_data.secondary_type
)  // uses xiangke_core::types::TypeChart

stab_multiplier = 1.2 if attacker has STAB (same type as move) else 1.0
variance = random(f64) in [0.85, 1.0]

final_damage = max(1, int(raw_damage * type_effectiveness * stab_multiplier * variance))
if immune (type_effectiveness == 0.0): final_damage = 0

critical_hit: 6% chance → final_damage *= 1.5
```

**Additional effects:**
- **Recoil:** if `move.recoil > 0` and damage_dealt > 0: recoil = max(1, damage_dealt * recoil / 100)
- **Healing:** if `move.healing > 0`: heal = max(1, attacker.max_hp * healing / 100)
- **Status effects:** if `move.effect != None` and `move.effect_chance > 0` and `effect_chance_check`: apply status if not resisted

**GDScript source:** `action_system.gd:56-156`

---

## 3. Turn Queue Management

**Module:** `manager.rs` → `BattleManager`

**Turn queue calculation:**
```
1. Filter active (non-defeated) participants
2. For each active participant, compute effective_speed
3. Shuffle entries (randomize ties)
4. Sort by effective speed descending
5. Return Vector of participant indices
```

**Round management:**
- `start_new_round(state)`: increment round_count, recalculate turn_queue, reset index to 0.
- `advance_to_next_turn(state)`: increment turn_queue_index; if exhausted, start new round. Skip defeated participants. Set active_participant.
- `start_battle(state)`: call start_new_round, set turn_count = 1, set first active participant.

**Edge cases:**
- All participants defeated → return false (battle ends as Defeat).
- Single participant → queue has 1 entry.

**GDScript source:** `battle_manager.gd:10-108`

---

## 4. Battle Flow Orchestration

**Module:** `flow.rs` (Rust core functions) + `battle_flow_service.gd` (GDScript wrapper per Q1-A)

Rust provides the following stateless/stateless-friendly functions that the GDScript wrapper calls:

```rust
// In flow.rs (pure functions, no Node dependency)

fn process_start_of_turn(participant: &mut BattleParticipant) -> Vec<String>;
// Check status effects at start of turn (confusion may skip turn)
// Returns log messages

fn process_end_of_turn(participant: &mut BattleParticipant) -> Vec<String>;
// Process DoT effects, decrement durations
// Returns log messages

fn select_ai_action(state: &BattleState, participant_index: usize) -> Option<AIAction>;
// AI logic (Q2-C hybrid: simple target selection and move scoring in Rust)
// Uses state.move_lookup for move data resolution

fn find_weakest_enemy<'a>(state: &'a BattleState, self_participant_index: usize) -> Option<usize>;
// Find weakest (lowest HP %) non-defeated opponent

fn score_move(
    state: &BattleState,
    move_id: &str,
    attacker_index: usize,
    target_index: usize,
) -> f64;
// Heuristic: power × type_effectiveness × (accuracy / 100)
```

**GDScript wrapper responsibilities** (in existing `battle_flow_service.gd`):
1. Create participants from CharacterData (calls `BattleParticipant::new`)
2. Build move lookup HashMap from DataRegistry (Q4-C)
3. Create BattleState (passes participants + move_lookup)
4. Call `BattleManager::start_battle(state)`
5. Run battle loop with yield points for UI
6. Handle signals (`turn_started`, `action_executed`, `participant_defeated`, `battle_ended`, `log_updated`)
7. For player turns: await input from scene, then execute via `ActionSystem::calculate_damage`
8. For enemy turns: call `select_ai_action(state, idx)` from Rust, then execute

**GDScript source:** `battle_flow_service.gd:37-326`

---

## 5. AI Action Selection

**Module:** `flow.rs` (hybrid per Q2-C)

**Simple AI in Rust (basic logic):**

```
select_ai_action(state, participant_index):
    if no active opponents: return None
    target = find_weakest_enemy(state, participant_index)
    if target is None: target = first active opponent
    move = select_best_move(state, participant_index, target)
    if move is None: return None
    return AIAction { move_id, target_index, score }

find_weakest_enemy(state, self_idx):
    for each active opponent:
        hp_ratio = current_hp / max_hp
        track minimum hp_ratio
    return index of opponent with lowest hp_ratio

select_best_move(state, attacker_idx, target_idx):
    best_score = -1.0, best_move = None
    for each move_id in attacker.character_data.moves:
        move = state.move_lookup.get(move_id)   // Q4-C HashMap lookup
        if move.healing > 0: continue (skip healing, AI attacks only)
        score = move.power
        if score <= 0: continue
        score *= type_effectiveness (via TypeChart)
        score *= move.accuracy / 100.0
        if score > best_score: update best
    return best_move
```

**GDScript source:** `battle_flow_service.gd:206-293`

**Hybrid boundary:** Rust handles simple target selection and move scoring. If GDScript needs to implement complex AI strategies (e.g., tactical positioning, status effect strategy, team synergy), it can override or extend via the GDScript wrapper layer.

---

## 6. Status Effect Processing

**Module:** `state.rs` / `participant.rs` (simple migration per Q6-A)

**Start-of-turn effects:**
- Confusion check: if participant has `EffectType::Confusion`, 50% chance to skip turn (self-hit). Stubbed in current GDScript; Rust implements the chance roll.

**End-of-turn effects:**
- For each active status effect with damage-over-time:
  - `damage = max(1, participant.max_hp * damage_per_turn / 100)`
  - Apply damage via `participant.take_damage()`
- Current implementation uses a flat 1/16 max HP for all DoT effects (simplified).

**No duration tracking** (per Q6-A): Effects last until battle ends or overridden. This matches GDScript behavior.

**GDScript source:** `battle_flow_service.gd:297-321`

---

## 7. Battle End Conditions

**Module:** `state.rs` → `BattleState::evaluate_status()`

```
evaluate_status():
    if status != Active: return status (already ended)
    
    if all enemies defeated → Victory
    if all players defeated → Defeat
    if turn_count >= MAX_TURNS (50) → Draw
    else → Active (continue)
```

**GDScript source:** `battle_state.gd:106-128`
