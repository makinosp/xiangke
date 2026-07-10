# Unit Test Execution — Migration Phase 5

## Run All Rust Unit Tests

### 1. Execute Test Suite

```bash
just test-rust
# equivalent: cd extensions && cargo test
```

### 2. Review Results

- **Expected**: 100 tests pass, 0 failures (55 core + 45 battle)
- **Coverage**: battle crate covers participant, state, action, manager, flow
  modules
- **Report**: terminal output; use `cargo test -- --nocapture` for logs

### 3. Fix Failing Tests

If any fail:

1. Read failure output (module + assertion)
2. Fix Rust source in `extensions/{core,battle}/src/`
3. Rerun `just test-rust` until green

## Rust Test Inventory (from Phase 2 & 3)

| Crate          | Module                                                           | Tests   |
| -------------- | ---------------------------------------------------------------- | ------- |
| xiangke-core   | types, character, moves, status, calc, validator                 | 55      |
| xiangke-battle | participant (11), state (12), action (12), manager (7), flow (6) | 45      |
| **Total**      |                                                                  | **100** |

## GDScript Validation (No Logic Remaining)

The migrated GDScript files (`battle_participant.gd`, `battle_state.gd`,
`battle_flow_service.gd`) are now thin data holders / wrappers. They contain no
battle logic to unit-test. Validation is covered by integration tests below.
