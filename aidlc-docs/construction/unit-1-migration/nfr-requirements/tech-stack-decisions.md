# Phase 3: Battle System — Tech Stack Decisions

## Decision Log

### D-1: BattleFlowService Architecture

| Aspect | Decision |
|---|---|
| **Choice** | Pure Rust core + GDScript wrapper (Q1-A) |
| **Rationale** | BattleFlowService is deeply coupled to Godot (Node, signals, await). Rust core provides pure functions; GDScript wrapper retains ownership of the battle loop, signal emission, and UI interaction. |
| **Impact** | GDScript wrapper code in `battle_flow_service.gd` must be updated to call Rust functions. Core logic (damage, AI, state) is pure Rust. |

### D-2: AI Implementation

| Aspect | Decision |
|---|---|
| **Choice** | Hybrid: simple AI in Rust, complex AI in GDScript (Q2-C) |
| **Rationale** | Target selection (weakest enemy) and move scoring (power × effectiveness × accuracy) are simple heuristics well-suited to Rust. Future complex AI (tactical positioning, team synergy) can be implemented in GDScript using the existing signal architecture. |
| **Interface** | `flow.rs` exposes `select_ai_action(state, participant_index) -> Option<AIAction>` |

### D-3: Error Handling Strategy

| Aspect | Decision |
|---|---|
| **Choice** | Panic on invariant violation (Q3-A) |
| **Rationale** | Internal tool, fail-fast during development. Matches existing core crate pattern (assert! in calc.rs, types.rs, validator.rs). No Result types in internal function signatures. |
| **Impact** | Debugging requires `RUST_BACKTRACE=1` (NFR-R-3). |

### D-4: Move Data Resolution

| Aspect | Decision |
|---|---|
| **Choice** | `HashMap<String, Box<MoveData>>` lookup table (Q4-C) |
| **Rationale** | Move IDs in `CharacterData.moves: Vec<String>` are resolved at battle init into an owned HashMap. No runtime GDScript calls during battle. Boxing reduces HashTable resize cost. |
| **Impact** | Battle init includes one-time cost of iterating all characters' move IDs + DataRegistry lookups (GDScript side). |

### D-5: Random Number Generation

| Aspect | Decision |
|---|---|
| **Choice** | `rand::thread_rng()` (Q5-A) |
| **Rationale** | Simplest approach, adequate for an internal game. Thread-local ChaCha12 RNG seeded from OS entropy. No special WASM handling until Phase 5 (Q3-C). |
| **Impact** | RNG owned by `BattleState` as `ThreadRng`. Tests use non-deterministic randomness unless wrapped with seedable Rng. |

### D-6: Status Effect System

| Aspect | Decision |
|---|---|
| **Choice** | Simple migration (Q6-A) |
| **Rationale** | Translate existing GDScript behavior exactly. No duration tracking, no effect trait system. DoT + confusion checks only. `EffectType` enum replaces `StatusEffectData` struct. |
| **Impact** | `Vec<EffectType>` on `BattleParticipant`. No new types needed. |

### D-7: Test Strategy

| Aspect | Decision |
|---|---|
| **Choice** | Unit + Integration tests (Q7-B) |
| **Rationale** | Unit tests cover each module in isolation. Integration tests simulate full battle loops (1-50 turns) with AI to verify module interactions. |
| **Target** | <500ms full test suite execution (Q6-B). |

### D-8: Data Ownership Model

| Aspect | Decision |
|---|---|
| **Choice** | Owned `Box<CharacterData>` and `Box<MoveData>` (FD redesign) |
| **Rationale** | Eliminates lifetime parameters (`BattleState<'a>`). All data is independently owned on both sides of the GDScript-Rust boundary. GDScript's DataRegistry populates Rust at init time via field-by-field conversion. |
| **Impact** | One-time heap allocation at battle init (~50 small structs). No cross-language memory safety concerns. |

### D-9: Compilation Profile

| Aspect | Decision |
|---|---|
| **Choice** | LTO for release builds (Q7-B) |
| **Rationale** | `lto = "fat"` + `codegen-units = 1` for release profile minimizes binary size, critical for WASM deployment. Dev profile unchanged for fast iteration. |
| **Impact** | Release builds take longer but produce smaller binaries (<2MB target per NFR-B-3). |

## Dependency Graph

```
xiangke-battle
├── xiangke-core (types, calc, validator)
├── serde (MoveData/CharacterData deserialization at init)
├── rand (thread_rng for variance, accuracy, critical, confusion)
└── thiserror (Error types)
```

## Excluded Technologies

| Technology | Reason |
|---|---|
| `wasm-bindgen` | Godot GDExtension uses its own WASM ABI; wasm-bindgen not compatible |
| `gdnative` (pre-4.x) | Godot 4.x uses GDExtension API (godot-rust / gdext) |
| `proptest` / `quickcheck` | Property-based testing was opted out in Requirements Analysis |
| `rayon` / parallel iterators | Single-threaded Godot environment; parallelism adds complexity without benefit |
| `crossbeam` / channels | No concurrent access patterns in battle system |
