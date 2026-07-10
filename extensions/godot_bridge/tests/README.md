# Bridge Integration Tests

The `godot_bridge` crate has no automated unit tests because gdext classes
(`RustBattleSystem`, `#[func]` methods) require a running Godot 4.x runtime
to instantiate.

## Manual Testing (Godot Required)

1. Build: `cargo build -p xiangke-godot-bridge`
2. Open the Godot project
3. Run the battle scene
4. Verify:
   - `RustBattleSystem` appears as a child of `BattleFlowService`
   - Battle starts, turns advance, actions execute
   - No errors in Godot Output panel

## Rust-Side Coverage

The underlying battle logic is tested via `xiangke-battle` (48 tests) and
`xiangke-core` (55 tests). The bridge layer is a thin delegation layer and
its correctness is validated by Godot runtime testing.
