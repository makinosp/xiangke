# Phase 3: Battle System — Functional Design Plan

## Context

Migrating the GDScript battle system (`systems/battle/`) to Rust
(`rust/battle/`). The battle crate already has 5 module stubs (participant,
state, action, manager, flow). Core data types are already implemented in
`rust/core/`.

Existing GDScript architecture:

- `BattleParticipant` (RefCounted): Wraps CharacterData with runtime state (HP,
  stat stages, status effects)
- `BattleState` (RefCounted): Battle state, turn queue, win/loss evaluation
- `ActionSystem` (RefCounted): Damage formula, accuracy, STAB, type
  effectiveness, recoil, healing, status effects
- `BattleManager` (RefCounted): Turn queue calculation (speed-based), round
  management
- `BattleFlowService` (Node): Battle loop orchestration, AI action selection,
  signals for UI

## Plan

- [x] Step 1: Analyze existing GDScript battle system interfaces and data flow
- [x] Step 2: Design Rust battle system architecture and ask clarifying questions
- [x] Step 3: Generate functional design artifacts
- [x] Step 4: Present completion and await approval

---

## Design Questions

Please answer each question by filling in the letter choice after the
`[Answer]:` tag. If none of the options match your needs, choose the last option
(Other) and describe your preference after the `[Answer]:` tag.

---

## Question 1

BattleFlowService Architecture

The GDScript `BattleFlowService` is a **Node** (extends Node, emits signals)
that:

1. Creates participants from CharacterData
2. Starts the battle via BattleManager
3. Runs the battle loop (yields between turns for UI updates)
4. Coordinates AI actions and player actions
5. Emits signals: `turn_started`, `action_executed`, `participant_defeated`,
   `battle_ended`, `log_updated`

How should we handle this in the Rust migration?

A) Pure Rust core + GDScript wrapper — Implement
Participant/State/Action/Manager in Rust; keep `BattleFlowService` in GDScript
as a thin wrapper that calls Rust via GDExtension

B) Full Rust GDExtension Node — Implement the entire `BattleFlowService` as a
Rust GDExtension Node class with Godot signals

C) Hybrid — Implement core logic (flow loop, turn management, AI) in Rust; use
GDScript only for signal relay and scene calls

D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 2

AI Logic Placement

The GDScript AI (`_get_ai_action`, `_find_weakest_enemy`, `_select_best_move`)
uses `DataRegistry.get_move()` — a GDScript autoload.

Where should the AI logic live after migration?

A) Rust battle crate — Migrate AI logic to Rust; pass all required move data to
the Rust side before battle starts (avoids GDScript interop during hot path)

B) GDScript layer — Keep AI in GDScript; Rust only provides the pure calculation
functions (calculate_damage, etc.)

C) Hybrid — Move simple AI (target selection, move scoring) to Rust; keep
complex AI decision trees in GDScript for future flexibility

D) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Question 3

Error Handling Strategy

The GDScript code uses `assert()` extensively. In Rust, what should the error
handling strategy be?

A) Panic on invariant violation — Use `assert!()` / `debug_assert!()` for all
business rule violations (same as GDScript). Simpler code, game will crash on
bugs (acceptable for an internal game).

B) Result-based error handling — Use `thiserror` + `Result<T, BattleError>` for
all fallible operations. Return errors instead of panicking. More robust, allows
graceful degradation.

C) Hybrid — Use `debug_assert!()` in debug builds for development feedback;
return `Result` types at public API boundaries for the bridge layer.

D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 4

Move Data Resolution

The GDScript code references moves by ID via `DataRegistry.get_move(move_id)` —
a GDScript autoload. In Rust, how should moves be resolved?

A) Pre-load all data — Before battle starts, pass all `CharacterData` and
`MoveData` to Rust side (they're already `Serialize`/`Deserialize`). No runtime
GDScript calls during battle.

B) GDExtension bridge — Call back into GDScript from Rust to resolve move IDs
during battle execution (more complex interop).

C) Move IDs + lookup table — Pass a `HashMap<String, MoveData>` lookup table to
the Rust battle state at initialization time.

D) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Question 5

Random Number Generation

GDScript uses `randi()`, `randf()`, `randf_range()` (implicit global seed). For
Rust, which approach?

A) `rand::thread_rng()` — Simple, non-deterministic. Good for production. Tests
use fixed seeds.

B) Thread-local `SmallRng` — Faster than ChaCha, seeded from entropy. Explicit
seed for reproducibility.

C) Pass `&mut impl Rng` — Inject RNG as a parameter to all functions that need
randomness. Maximum testability and determinism.

D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 6

Status Effect System Depth

The current GDScript status effects have basic support (apply, check for
confusion on start-of-turn, basic DoT on end-of-turn). Should we enhance during
migration?

A) Simple migration — Translate existing behavior exactly. StatusEffectData
remains a simple struct with fields. DoT and confusion checks only.

B) Moderate enhancement — Add duration tracking (turns remaining), proper
immunity checks, status resistance, stacking rules, and clearer effect trait
system.

C) Full status system — Implement a trait-based EffectSystem with configurable
effects (add, tick, expire, remove). Each status has start-of-turn / end-of-turn
/ on-apply / on-remove callbacks.

D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 7

Test Strategy

What level of test coverage should the Rust battle system have?

A) Unit tests — Test each module in isolation (participant creation, stat
stages, damage formula, accuracy, turn queue). Match the 55 existing tests
pattern.

B) Unit + Integration — Unit tests for modules + integration tests for full
battle scenarios (full battle loop with AI, win/loss conditions, status effects,
edge cases like all-defeated mid-round).

C) Property-based — Use `proptest` or `quickcheck` to generate random battle
configurations and verify invariants (damage >= 0, HP never exceeds max, turn
queue always sorted, etc.).

D) Other (please describe after [Answer]: tag below)

[Answer]: B
