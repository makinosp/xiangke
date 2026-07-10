# Phase 3: Battle System — Domain Entities (Rust)

## Overview

Rust domain entities for the battle system migration. These types live in the `xiangke-battle` crate and depend on `xiangke-core` for shared type definitions.

---

## BattleParticipant

Mutable battle entity wrapping a `CharacterData` with runtime state.

```
BattleParticipant
├── character_data: Box<CharacterData> → Owned character definition (no lifetime)
├── current_hp: u32                    → Current HP (0..max_hp)
├── max_hp: u32                        → Maximum HP (derived from character_data.hp)
├── team: Team                         → PLAYER or ENEMY
├── slot_index: u32                    → Display index for UI targeting (0-based within team)
├── is_defeated: bool                  → true when current_hp == 0
├── stat_stages: [i32; 5]             → Stage modifiers per Stat enum (-6..+6, 0 = neutral)
└── active_status_effects: Vec<EffectType> → Active status effect types
```

**Team enum:**
```rust
enum Team { Player, Enemy }
```

**Constructors:**
- `BattleParticipant::new(data: Box<CharacterData>, team: Team, slot: u32)` — Factory constructor, validates inputs, panics on invalid data (per Q3-A fail-fast).

**Key methods:**
- `stat_stage(stat: Stat) -> i32` — Get current stage for a stat (clamped -6..+6).
- `apply_stat_stage(stat: Stat, delta: i32)` — Apply stage change, clamped to [-6, +6].
- `reset_stat_stages()` — Reset all stages to 0.
- `effective_stat(stat: Stat) -> f64` — Base value × stage multiplier (uses `xiangke_core::calc::stat_stage_multiplier`).
- `take_damage(amount: u32) -> u32` — Reduce HP, capped to current_hp. Sets is_defeated if HP reaches 0.
- `heal(amount: u32) -> u32` — Restore HP, capped to max_hp.
- `apply_status(effect: EffectType)` — Append to active_status_effects.
- `has_status(effect: EffectType) -> bool` — Check if a status effect is active.

**Design notes:**
- Uses `Box<CharacterData>` (owned, heap-allocated) instead of `&CharacterData` — this eliminates the need for a lifetime parameter on `BattleParticipant` and `BattleState`. No complex `BattleState<'a>` generic required.
- `CharacterData` is constructed on the Rust side by deserializing/converting GDScript resource data at battle initialization time. The GDScript wrapper reads `.tres` / `DataRegistry` values and passes them to Rust via GDExtension API calls.
- HP stored as `u32` — zero is valid (defeated), positive is alive. Bounds checked in `take_damage`/`heal`.
- `stat_stages` is a fixed-size array `[i32; 5]` indexed by `Stat` enum (not Vec).
- Status effects stored as `Vec<EffectType>` (copyable enum) — `StatusEffectData` struct is not needed on Rust side for the simple migration (Q6-A); `EffectType` alone suffices.

---

## BattleState

Central state object representing the current status of a battle. No lifetime parameters (`BattleState<'a>` not needed) — all data is owned.

```
BattleState
├── battle_id: String                       → Unique identifier (format: "battle_<timestamp>")
├── participants: Vec<BattleParticipant>    → All participants (player + enemy)
├── turn_count: u32                         → Current turn number (1-indexed)
├── round_count: u32                        → Current round number
├── battle_status: Status                   → ACTIVE, VICTORY, DEFEAT, DRAW, ESCAPED
├── turn_queue: Vec<usize>                  → Participant indices for current round (speed-sorted)
├── turn_queue_index: usize                 → Position in turn queue
├── active_participant: Option<usize>       → Index of current active participant
├── move_lookup: HashMap<String, Box<MoveData>> → Owned move data for AI resolution (Q4-C)
├── rng: ThreadRng                          → Random number generator (Q5-A)
└── battle_log: Vec<String>                 → Timestamped log entries
```

**Status enum:**
```rust
enum Status { Active, Victory, Defeat, Draw, Escaped }
```

**Constants:**
- `MAX_TURNS: u32 = 50` — Maximum turns before forced draw.

**Constructors:**
- `BattleState::new(participants: Vec<BattleParticipant>, move_lookup: HashMap<String, Box<MoveData>>)` — Creates state from pre-loaded participants and move lookup table.

**Key methods:**
- `player_participants() -> impl Iterator<Item = &BattleParticipant>` — Filter by Team::Player.
- `enemy_participants() -> impl Iterator<Item = &BattleParticipant>` — Filter by Team::Enemy.
- `active_participants() -> impl Iterator<Item = &BattleParticipant>` — Filter non-defeated.
- `evaluate_status() -> Status` — Check win/loss/draw conditions (all enemies defeated → Victory, all players defeated → Defeat, turn_count >= MAX_TURNS → Draw).
- `add_log(msg: String)` — Append timestamped log entry.
- `recent_log(n: usize) -> Vec<&str>` — Last N log entries.
- `reset()` — Reset all runtime state for a new battle (HP, status effects, stat stages, queue, log).

**Design notes:**
- `participants` is a flat Vec; team affiliation is on each participant, not separate arrays.
- `turn_queue` stores indices into `participants` (not references), avoiding borrow-checker issues.
- `move_lookup` owns its data via `Box<MoveData>`. Populated from GDScript `DataRegistry` at battle init time via the GDScript wrapper. The GDScript wrapper iterates all characters' move IDs, retrieves `MoveData` from `DataRegistry`, converts each field to Rust equivalents, and inserts into the HashMap. After battle start, no further GDScript calls are needed for move resolution.
- `rng` is owned by BattleState (Q5-A) — `thread_rng()` is simple and adequate. Tests can construct with a seedable `StdRng` wrapper if deterministic output is needed.

---

## ActionResult

Result of executing a single move action. Returned from Rust to the GDScript wrapper for UI display and log rendering.

```
ActionResult
├── damage_dealt: u32                 → Total damage dealt to defender (0 if healing/no-damage/immune)
├── target_index: usize               → Index of the target participant in BattleState.participants
├── hit: bool                         → true if accuracy check passed; false = missed
├── is_critical: bool                 → true if critical hit occurred (6% chance, 1.5× damage)
├── type_effectiveness: f64           → Type effectiveness multiplier (0.0, 0.25, 0.5, 1.0, 1.25, 2.0, 4.0)
├── is_super_effective: bool          → type_effectiveness > 1.0 (for UI: "It's super effective!")
├── is_not_very_effective: bool       → 0.0 < type_effectiveness < 1.0 (for UI: "It's not very effective...")
├── is_immune: bool                   → type_effectiveness == 0.0 (for UI: "It doesn't affect...")
├── status_applied: Option<EffectType>→ Status effect applied (Some(effect)) or None
├── status_resisted: bool             → Target already has the status effect (no re-application)
├── recoil_damage: u32                → Recoil damage dealt to the attacker (0 if none)
├── heal_amount: u32                  → HP restored to attacker (0 if non-healing move; damage and heal are mutually exclusive per move)
├── raw_damage: u32                   → Damage before type_effectiveness × STAB × variance modifiers
└── log_message: String               → Human-readable log entry returned to GDScript for battle log UI
```

**Design notes:**
- Pure data struct with no methods. Constructed by `ActionSystem::calculate_damage()`.
- All fields are `pub` and semantically meaningful for UI display. GDScript wrapper reads `log_message` for the battle log and individual booleans for conditional UI styling.
- `heal_amount` is separate from `damage_dealt` — a move is either damaging (power > 0) or healing (healing > 0), never both. `damage_dealt` and `heal_amount` are mutually exclusive per move execution.
- `target_index` enables the GDScript wrapper to identify which participant was targeted without name-based lookups.
- `is_critical` is the canonical name (mapped from GDScript's `critical_hit`). GDScript wrapper reads this for UI overlay ("A critical hit!").
- No `Result` type here (Q3-A); invariants are enforced via assertions in `ActionSystem`.

---

## AIAction

Simple action selection result for AI-controlled enemies.

```
AIAction
├── move_id: String           → The move ID to execute (resolved from state.move_lookup)
├── target_index: usize       → Target participant index
└── score: f64                → Heuristic score for this action (debugging/analysis)
```

**Design notes:**
- Simple struct returned by AI functions in `flow.rs`.
- AI is hybrid (Q2-C): basic target selection and move scoring in Rust; complex decision trees remain in GDScript.
- Move data is resolved from `BattleState.move_lookup` using `move_id` at action execution time.

---

## Data Ownership Architecture

### Principle: All Rust Data is Owned

The Rust battle crate owns ALL of its data. No borrowed references across the GDScript↔Rust boundary. This decision eliminates lifetime parameter complexity and avoids subtle use-after-free bugs that could arise when GDScript garbage collection or reference counting interacts with Rust references.

### Data Flow at Battle Initialization

```
GDScript Layer                          Rust Layer
─────────────────                       ──────────────────
DataRegistry (master data)
       │
       ▼
BattleFlowService (GDScript)
  │   reads CharacterData from registry
  │   reads MoveData from registry
  │   converts each field to Rust types
  │
  ├──→ BattleParticipant::new(boxed_data, team, slot)
  │       Box<CharacterData> ───────────→ owned heap allocation
  │
  └──→ move_lookup.insert(id, Box::new(move_data))
          Box<MoveData> ────────────────→ owned heap allocation
```

### Why Box<T> (not Arc/Rc/reference)

| Approach | Lifetime Param | Runtime Cost | Complexity | Verdict |
|---|---|---|---|---|
| `&'a CharacterData` | `BattleState<'a>` | Zero | High (borrow checker) | ❌ Rejected |
| `Arc<CharacterData>` | None | Atomic ops overhead | Medium | ❌ Overkill (single-threaded Godot) |
| `Rc<CharacterData>` | None | Non-atomic refcount | Medium | ⚠️ Possible but unnecessary |
| `Box<CharacterData>` | None | One heap alloc | Low (simplest) | ✅ Selected |

**Rationale:**
1. Data is small (a few KB per character/move — 9+ characters × ~4 moves each = ~50 entries total).
2. Heap allocation cost is negligible (one-time at battle init, not per-turn).
3. No lifetime parameters anywhere — `BattleParticipant`, `BattleState`, and all function signatures remain simple.
4. Ownership is clear: `BattleState` owns everything, and it is dropped as a unit when the battle ends.
5. The GDScript wrapper already holds references in `DataRegistry`; Rust makes independent owned copies, eliminating cross-boundary memory safety concerns.

### move_lookup: Box<MoveData> (Owned, Not Reference)

`move_lookup: HashMap<String, Box<MoveData>>` uses **owned** `Box<MoveData>` values:

- **Not `&'a MoveData`** — would require `BattleState<'a>`.
- **Not `MoveData` inline** — `MoveData` is a large struct (~20 fields including strings). Boxing reduces memory pressure when storing in a HashMap (avoids moving large structs on hash table resize).
- **Not `Arc<MoveData>`** — no shared ownership needed. Each battle has its own independent snapshot.
- Access pattern: `state.move_lookup.get(move_id) -> Option<&Box<MoveData>>` — auto-deref to `&MoveData` via Deref trait.

### Comparison: GDScript vs Rust Data Model

| Aspect | GDScript (Current) | Rust (Target) |
|---|---|---|
| CharacterData storage | Resource (`.tres`), reference-counted by Godot | `Box<CharacterData>` owned by `BattleParticipant` |
| MoveData storage | `DataRegistry` autoload, singleton | `Box<MoveData>` owned by `BattleState.move_lookup` |
| Data lifetime | Godot reference tree | Battle session only (dropped with `BattleState`) |
| Cross-language refs | N/A | **None** — all data is independently owned on both sides |
| Init overhead | N/A | One-time clone/conversion of ~50 small structs |
