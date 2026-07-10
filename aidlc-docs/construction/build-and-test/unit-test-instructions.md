# Unit Test Execution

## Run Unit Tests

### 1. Execute All Unit Tests
```bash
cargo test --workspace
```

### 2. Run Tests for a Specific Crate
```bash
cargo test -p xiangke-core
cargo test -p xiangke-battle
```

### 3. Review Test Results
- **Expected**: 103 tests pass (55 core + 48 battle), 0 failures
- **Test Report Location**: stdout of `cargo test`
- **Note**: `xiangke-godot-bridge` has no unit tests (gdext classes require Godot runtime)
