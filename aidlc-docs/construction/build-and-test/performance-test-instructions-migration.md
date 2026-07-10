# Performance Test Instructions — Migration Phase 5

## Purpose

Validate that the Rust-backed battle system meets the NFR targets defined in
Phase 3 NFR Requirements (damage calc <10μs, turn <1ms, binary <2MB).

## Performance Requirements (from NFR)

- **Damage calculation**: < 10 μs per call
- **Turn queue processing**: < 1 ms
- **Binary size**: < 2 MB (WASM release, optimized)
- **Full test suite**: < 500 ms

## Setup

### 1. Build Release WASM

```bash
just build-rust-wasm-release
```

### 2. Benchmark via Rust Bench (optional)

Add a `#[bench]` or use `cargo test --release` timing in `xiangke-battle`.

## Test Scenarios

### Scenario 1: Damage Calc Latency

- **Target**: < 10 μs
- **Method**: `action::calculate_damage` over 10k iterations; measure mean.
- **Expected**: mean < 10 μs.

### Scenario 2: Turn Queue

- **Target**: < 1 ms for full 6v6 participant sort.
- **Method**: `manager::calculate_turn_queue` benchmark.
- **Expected**: < 1 ms.

### Scenario 3: WASM Binary Size

- **Target**: < 2 MB after `wasm-opt -Oz`.
- **Method**:
  `ls -la extensions/target/wasm32-unknown-emscripten/release/xiangke_godot_bridge.wasm`.
- **Expected**: < 2 MB.

### Scenario 4: Runtime FPS (Web)

- **Target**: ≥ 30 FPS Web, ≥ 60 FPS Desktop during battle.
- **Method**: Export to HTML5; profile in browser devtools.
- **Expected**: stable frame rate, no GC stalls (Rust owns hot path).

## Analysis

- Compare against GDScript baseline (Unit 3 perf targets: turn <100ms, damage
  <10ms). Rust should show order-of-magnitude improvement.
- If binary > 2 MB: enable `opt-level = "z"` + `lto = true` in `Cargo.toml`.
