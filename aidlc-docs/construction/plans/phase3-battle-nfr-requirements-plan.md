# Phase 3: Battle System — NFR Requirements Plan

## Context

NFR requirements for the Rust battle system migration (`xiangke-battle` crate).
The battle module is a pure computation layer (no I/O, no persistence). Key NFR
concerns are performance, WASM compatibility, and debuggability.

Design decisions already locked in (from Functional Design):

- GDScript wrapper owns the battle loop; Rust provides pure functions
- All data is owned (Box<T>, no lifetime parameters)
- `HashMap<String, Box<MoveData>>` for move resolution (Q4-C)
- Panic on invariant violation (Q3-A)
- `rand::thread_rng()` for randomness (Q5-A)

## Plan

- [x] Step 1: Analyze functional design for NFR implications
- [x] Step 2: Generate NFR questions
- [x] Step 3: Generate NFR requirements artifacts
- [x] Step 4: Present completion and await approval

---

## NFR Questions

---

## Question 1

Performance Target: Damage Calculation Latency

The damage calculation (`ActionSystem::calculate_damage`) is the hottest path —
called once per move execution. In GDScript this completes in <1ms.

What latency target should the Rust implementation meet?

A) **<100μs** — 10× faster than GDScript. Rust's native speed should achieve
this easily. No optimization effort needed beyond idiomatic code.

B) **<10μs** — 100× faster. Requires attention to allocation patterns (avoid
Vec/String allocation in hot path, pre-allocate ActionResult).

C) **<1μs** — Extreme optimization. Requires zero-allocation hot path,
stack-only ActionResult, no HashMap lookups during damage calc.

D) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 2

Performance Target: Full Turn Processing

A full turn includes: action selection (AI or player input), damage calculation,
status processing, log generation, and UI updates via GDScript bridge.

What is the acceptable end-to-end latency for a single turn (Rust portion only,
excluding GDScript UI rendering)?

A) **<5ms** — GDScript-level performance. No optimization concerns.

B) **<1ms** — Noticeably faster. Rust should achieve this without effort.

C) **<100μs** — Near-instant. Only if running batch simulations (future AI
training).

D) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 3

WASM Compatibility

The primary target is Web/WASM (per migration requirements). Rust's `rand` crate
on WASM uses `getrandom` which works in browsers.

What WASM-specific considerations apply?

A) **Emscripten WASM target** — `wasm32-unknown-emscripten` with `rand` crate
(uses `getrandom`). Native `getentropy` support via Emscripten. No special
feature flags needed. `thread_rng` works.

B) **WASM with deterministic RNG** — Use a seedable RNG (e.g.,
`StdRng::seed_from_u64`) for WASM builds to ensure reproducibility. Avoid
`getrandom` dependency.

C) **No WASM concerns** — Defer to Phase 5 (Build and Test) for WASM
verification.

D) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Question 4

Error Observability

Q3-A chose panic-on-invariant-violation (fail-fast). How should errors be
surfaced for debugging?

A) **Panic + Godot push_error** — Rust panic propagates to GDScript via
GDExtension boundary; GDScript catches and calls `push_error()`. Game crashes on
invariant violation (true fail-fast).

B) **Panic + log file** — Same as A, but also write a crash dump with battle
state snapshot (participants, turn queue, last 20 log entries) before panicking.

C) **No special handling** — Default Rust panic behavior. Error appears in Godot
console output. Acceptable for internal tool.

D) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Question 5

Binary Size Budget

Rust GDExtension adds binary size compared to pure GDScript. The battle crate
depends on `xiangke-core`, `serde`, `rand`, `thiserror`.

What is the acceptable additional binary size for the Rust `.gdextension` shared
library?

A) **<500KB** — Minimal footprint. Requires stripping debug symbols, avoiding
unnecessary monomorphization, and LTO optimization.

B) **<2MB** — Reasonable budget. Standard release build with LTO. No special
optimization required.

C) **<5MB** — Generous budget. Debug symbols included. Acceptable for internal
tool on desktop.

D) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 6

Unit Test Performance

Per Q7-B (Unit + Integration tests), the battle crate will have tests. What is
the acceptable test suite execution time?

A) **<100ms** — Keep tests fast alongside the existing 55 core tests. No heavy
test fixtures.

B) **<500ms** — Allow for integration test scenarios (full battle loops with
AI). Each integration test simulates 1-50 turns.

C) **<2s** — Generous budget. Property-based tests or exhaustive boundary checks
included.

D) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 7

Rust Compilation Profile

The core crate uses `profile.dev` and `profile.release`. What compilation
profile should the battle crate use?

A) **Same as core** — Use workspace `[profile]` settings. `opt-level = 3` for
release.

B) **LTO for release** — Enable `lto = "fat"` and `codegen-units = 1` for
release builds to minimize binary size (important for WASM).

C) **Optimize for debug** — `opt-level = 2` in dev profile for reasonable debug
performance during development.

D) Other (please describe after [Answer]: tag below)

[Answer]: B
