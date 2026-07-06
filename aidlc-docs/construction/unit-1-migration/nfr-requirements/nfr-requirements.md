# Phase 3: Battle System — NFR Requirements

## 1. Performance Requirements

| ID | Requirement | Target | Source |
|---|---|---|---|
| NFR-P-1 | Damage calculation latency | <10μs per invocation | Q1-B |
| NFR-P-2 | Full turn processing (Rust portion) | <1ms end-to-end | Q2-B |
| NFR-P-3 | Turn queue calculation (O(n log n)) | <5μs for 6 participants | Functional Design |
| NFR-P-4 | TypeChart lookup | <0.1μs (O(1) array index) | Functional Design |
| NFR-P-5 | BattleState creation | <100μs (includes Box allocations) | Functional Design |

**Verification Method:** Benchmark tests using `#[bench]` or manual timing harness in CI. Key hot paths (damage calc, turn queue) should have dedicated benchmarks.

## 2. Compatibility Requirements

| ID | Requirement | Source |
|---|---|---|
| NFR-C-1 | Rust battle system must compile for `x86_64-apple-darwin` (dev) | Existing toolchain |
| NFR-C-2 | Rust battle system must compile for `wasm32-unknown-unknown` (deploy target) | MS-1 |
| NFR-C-3 | WASM compatibility deferred to Phase 5 (Build & Test) for verification | Q3-C |
| NFR-C-4 | Must link with Godot 4.x GDExtension ABI | Phase 1 toolchain |
| NFR-C-5 | Must not introduce GDScript-level dependencies (DataRegistry called at init only) | Q4-C, IR-1.x |

**Verification Method:** CI pipeline compiles for both native and WASM targets. Phase 5 adds Godot export test.

## 3. Reliability Requirements

| ID | Requirement | Source |
|---|---|---|
| NFR-R-1 | Fail-fast on invariant violation (panic) | Q3-A |
| NFR-R-2 | Input validation at all public Rust function boundaries | VR-1.x |
| NFR-R-3 | Default panic behavior; no custom error routing | Q4-C |
| NFR-R-4 | 55 existing core crate tests + new battle tests must pass | Q7-B |

**Verification Method:** `cargo test` covers unit and integration tests. CI blocks merge on test failure.

## 4. Maintainability Requirements

| ID | Requirement | Source |
|---|---|---|
| NFR-M-1 | All public types and functions documented with doc comments | Project convention |
| NFR-M-2 | Module structure mirrors GDScript original (participant, state, action, manager, flow) | Migration plan |
| NFR-M-3 | No unsafe code in battle crate | Safety policy |
| NFR-M-4 | All functions must be pure (no side effects beyond mutation of passed state) | Functional Design |

## 5. Build Requirements

| ID | Requirement | Source |
|---|---|---|
| NFR-B-1 | Release profile: LTO = "fat", codegen-units = 1 | Q7-B |
| NFR-B-2 | Dev profile: unchanged from workspace defaults (fast compile) | Q7-B |
| NFR-B-3 | Binary size budget: <2MB for release build per GDExtension shared library | Q5-B |
| NFR-B-4 | Test suite execution: <500ms for full battle crate | Q6-B |

**Verification Method:** `cargo build --release` checked in CI. Binary size and test time monitored via CI artifacts.

## 6. Verification Matrix

| NFR ID | Test Type | Verification | Success Criteria |
|---|---|---|---|
| NFR-P-1 | Benchmark | cargo bench or timing assertion | <10μs per calc |
| NFR-P-2 | Integration | Full battle loop timing | <1ms per turn |
| NFR-P-3 | Unit | Turn queue with 6 participants | <5μs |
| NFR-C-1 | Build | cargo build | Compiles |
| NFR-C-2 | Build | cargo build --target wasm32-unknown-unknown | Compiles |
| NFR-R-1 | Unit | Invalid input → panic | Expected panic |
| NFR-R-4 | Test | cargo test | All 55+ tests pass |
| NFR-B-1 | Build | release build with LTO | No warnings |
| NFR-B-3 | Measure | ls -lh target/release/*.so | <2MB |
| NFR-B-4 | Measure | cargo test -- --quiet | <500ms |
