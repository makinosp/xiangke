# Phase 3: Battle System — Business Rules (Rust Migration)

## Naming Convention

- **BR** = Battle Rule (invariant enforced during battle execution)
- **AR** = Action Rule (constraints on move execution and damage calculation)
- **IR** = Integration Rule (constraints on the GDScript-Rust bridge)
- **VR** = Validation Rule (input validation procedures)

---

## BR-1: Participant Lifecycle

| ID | Rule | Severity |
|---|---|---|
| BR-1.1 | `current_hp` must never exceed `max_hp` at any point | Error |
| BR-1.2 | `current_hp` must never underflow below 0 | Error |
| BR-1.3 | A participant with `current_hp == 0` MUST have `is_defeated == true` | Error |
| BR-1.4 | A defeated participant cannot take damage, heal, or act | Panic |
| BR-1.5 | Stat stages must always remain in [-6, +6] range | Panic |
| BR-1.6 | `slot_index` must be unique within each team | Error |
| BR-1.7 | Participants must have `max_hp > 0` at creation | Panic |

## BR-2: Turn Management

| ID | Rule | Severity |
|---|---|---|
| BR-2.1 | Defeated participants must be skipped in turn queue | Error |
| BR-2.2 | `turn_queue` must contain only active (non-defeated) participant indices | Error |
| BR-2.3 | Turn count must never exceed MAX_TURNS (50) | Error |
| BR-2.4 | Each participant must get exactly one action per round | Error |
| BR-2.5 | Round begins when all active participants have acted | Error |
| BR-2.6 | Turn order is determined by effective speed descending at round start | Invariant |
| BR-2.7 | Speed ties are resolved by random shuffle (stable sort) | Invariant |

## BR-3: Battle State

| ID | Rule | Severity |
|---|---|---|
| BR-3.1 | Battle must have at least 1 player participant and 1 enemy participant | Panic |
| BR-3.2 | `evaluate_status()` must be called before each turn begins | Error |
| BR-3.3 | Once `battle_status` is set to non-Active, no more turns may execute | Error |
| BR-3.4 | Victory: all enemy participants defeated | Invariant |
| BR-3.5 | Defeat: all player participants defeated | Invariant |
| BR-3.6 | Draw: turn_count >= MAX_TURNS (50) | Invariant |
| BR-3.7 | `participants` vector must not be modified during battle (no add/remove) | Invariant |

## AR-1: Damage Calculation

| ID | Rule | Severity |
|---|---|---|
| AR-1.1 | `damage_dealt` must always be >= 0 | Invariant |
| AR-1.2 | If `type_effectiveness == 0.0`, final damage MUST be 0 (immunity) | Error |
| AR-1.3 | Minimum damage per non-immune hit is 1 (MIN_DAMAGE) | Invariant |
| AR-1.4 | STAB multiplier is 1.2 if attacker's primary type matches move type | Invariant |
| AR-1.5 | Random variance must be in [0.85, 1.0] | Invariant |
| AR-1.6 | Critical hit chance is exactly 6% | Invariant |
| AR-1.7 | Critical hit multiplies final damage by 1.5 | Invariant |
| AR-1.8 | Defense must be clamped to minimum 1.0 before division | Invariant |
| AR-1.9 | Physical moves use Attack/Defense; Arts moves use Intelligence/Spirit | Invariant |

## AR-2: Move Execution

| ID | Rule | Severity |
|---|---|---|
| AR-2.1 | Accuracy must be in [1, 100] for damaging moves | Panic |
| AR-2.2 | Effect chance must be in [0, 100] | Panic |
| AR-2.3 | Accuracy check is: `rand() * 100.0 < move.accuracy` | Invariant |
| AR-2.4 | Effect chance check is: `rand() * 100.0 < move.effect_chance` | Invariant |
| AR-2.5 | Recoil damage: `max(1, damage_dealt * move.recoil / 100)` | Invariant |
| AR-2.6 | Recoil only applies if `move.recoil > 0` AND `damage_dealt > 0` | Invariant |
| AR-2.7 | Healing: `max(1, attacker.max_hp * move.healing / 100)` | Invariant |

## AR-3: Status Effects

| ID | Rule | Severity |
|---|---|---|
| AR-3.1 | A participant cannot have duplicate status effect types | Invariant |
| AR-3.2 | Status effect application is skipped if target already has the effect | Invariant |
| AR-3.3 | Status effects have no duration tracking (simple migration, Q6-A) | Design |
| AR-3.4 | DoT damage: `max(1, max_hp / 16)` per turn (simplified, matches GDScript) | Invariant |
| AR-3.5 | Confusion: 50% chance to skip turn (self-hit, no damage to opponent) | Invariant |

## AR-4: AI Logic (Hybrid)

| ID | Rule | Severity |
|---|---|---|
| AR-4.1 | AI must never target a defeated participant | Error |
| AR-4.2 | AI must never use a move targeting own team (healing is skipped, Q2-C) | Design |
| AR-4.3 | AI move selection: score = power × type_effectiveness × (accuracy / 100) | Invariant |
| AR-4.4 | AI target selection: lowest HP % among active opponents | Invariant |
| AR-4.5 | AI falls back to first move on first target if no valid selection | Invariant |
| AR-4.6 | AI always attacks (never heals in simple AI) | Design |

## IR-1: GDScript-Rust Bridge

| ID | Rule | Severity |
|---|---|---|
| IR-1.1 | Move lookup HashMap must be populated from DataRegistry before battle start | Error |
| IR-1.2 | BattleParticipant creation must be done via the GDScript wrapper | Design |
| IR-1.3 | All `CharacterData` references must be valid (not null) at construction | Panic |
| IR-1.4 | All move IDs in `character_data.moves` must have entries in move_lookup | Panic |
| IR-1.5 | GDScript wrapper owns the battle loop; Rust provides pure functions | Design |

## VR-1: Validation Procedures

| ID | Rule | Description |
|---|---|---|
| VR-1.1 | Participant creation validation | Validate CharacterData is non-null, team is valid, slot_index >= 0 |
| VR-1.2 | Battle state validation | Validate at least 1 player and 1 enemy participant, move_lookup covers all referenced moves |
| VR-1.3 | Action validation | Validate attacker and defender are not defeated, move is non-null |
| VR-1.4 | Move resolution validation | Validate move_id exists in `state.move_lookup` before lookup |
| VR-1.5 | Turn queue validation | After calculation, verify all entries are active (non-defeated) indices |

## Panic vs Error Severity Definitions

| Severity | Behavior | Source |
|---|---|---|
| **Panic** | `assert!()` / `panic!()` — crashes the process. Used for programming errors that should never happen in correct code. | Q3-A |
| **Error** | Logic-level error that can occur during gameplay (e.g., targeting a defeated participant). Returns expected behavior (skip, clamp, default). | Design |
| **Invariant** | Guaranteed by construction. Tests verify the invariant holds. Not checked at runtime (or debug-only). | Design |

## GDScript Rule Mapping

| GDScript Source | Rust Module | Rule IDs |
|---|---|---|
| `battle_participant.gd` create/assert | `participant.rs` | BR-1.x, VR-1.1 |
| `battle_participant.gd` stat_stages | `participant.rs` | BR-1.5 |
| `battle_participant.gd` take_damage/heal | `participant.rs` | BR-1.1, BR-1.2, BR-1.3 |
| `battle_state.gd` evaluate_status | `state.rs` | BR-3.x |
| `battle_state.gd` create/assert | `state.rs` | BR-3.1, VR-1.2 |
| `action_system.gd` calculate_damage | `action.rs` | AR-1.x, AR-2.x |
| `action_system.gd` accuracy/effect checks | `action.rs` | AR-2.x |
| `action_system.gd` status effect logic | `action.rs` | AR-3.x |
| `battle_manager.gd` turn queue | `manager.rs` | BR-2.x |
| `battle_flow_service.gd` AI logic | `flow.rs` | AR-4.x |
| `battle_flow_service.gd` bridge | GDScript wrapper | IR-1.x |
