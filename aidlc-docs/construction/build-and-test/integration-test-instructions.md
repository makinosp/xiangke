# Integration Test Instructions

## Purpose
Test the GDScript ↔ Rust integration layer to ensure `BattleFlowService` correctly delegates to `RustBattleSystem` and battle results flow back to GDScript correctly.

## Test Scenarios

### Scenario 1: Rust Battle System Initialization
- **Description**: Verify that `RustBattleSystem` compiles and its `#[func]` methods are registered correctly
- **Setup**: `cargo build` succeeds
- **Test Steps**: Verify `.dylib`/`.so`/`.dll` is produced in `target/debug/`

### Scenario 2: GDScript ↔ Rust Bridge (Manual - Godot Runtime Required)
- **Description**: In the Godot editor, verify that `BattleFlowService` instantiates `RustBattleSystem` without errors
- **Setup**: Open project in Godot 4.x with gdext extension enabled
- **Test Steps**: 
  1. Ensure the compiled library is in the Godot project's extension path
  2. Open a scene that uses `BattleFlowService` (e.g., battle scene)
  3. Check the Godot Output panel for any gdext/extension errors
- **Expected Results**: No extension-related errors; `RustBattleSystem` node appears in the scene tree

### Scenario 3: Battle Flow Execution
- **Description**: Start a battle and verify turn progression
- **Setup**: Godot project with compiled `.dylib`
- **Test Steps**:
  1. Run the battle scene
  2. Select a move and target
  3. Observe that damage/healing is calculated correctly
  4. Verify battle log messages appear
- **Expected Results**: Battle flows through multiple turns without errors

## Setup Integration Test Environment

### 1. Build Rust Library
```bash
cargo build --workspace
```

### 2. Configure Godot Extension Path
Copy `target/debug/libxiangke_godot_bridge.dylib` to the Godot project's extension directory (typically `godot/addons/` or `rust/` directory, configured via `.gdextension` file)

## Run Integration Tests

### 1. Open Godot Project
```bash
# Path to Godot 4.x executable
/path/to/godot4 --path /Volumes/Data/Projects/xiangke
```

### 2. Verify Service Interactions
- Open the battle scene
- Monitor the Output panel
- Check the scene tree for `RustBattleSystem` as a child of `BattleFlowService`

### 3. Cleanup
No cleanup required. Tests are non-destructive.
