# Bridge Integration Tests

The `godot_bridge` crate has no automated unit tests because gdext classes
(`RustBattleSystem`, `#[func]` methods) require a running Godot 4.x runtime to
instantiate.

## Manual Testing (Godot Required)

1. Build: `cargo build -p xiangke-godot-bridge`
2. Open the Godot project
3. Run the battle scene
4. Verify:
   - `RustBattleSystem` appears as a child of `BattleFlowService`
   - Battle starts, turns advance, actions execute
   - The enemy AI attacks the player's front and switches at low HP / type
     disadvantage instead of attacking itself
   - No errors in Godot Output panel

## Rust-Side Coverage

The underlying battle logic is tested via `xiangke-battle` and `xiangke-core`.
The bridge layer is a thin delegation layer and its correctness is validated by
Godot runtime testing.

The AI turn execution (`flow::execute_ai_turn`) is unit-tested in
`xiangke-battle`: an enemy AI attack targets the player's front and an enemy AI
switch on low HP both have dedicated tests. `RustBattleSystem::perform_ai_turn`
delegates directly to that function, so those tests cover the bridge's AI path
without requiring a Godot runtime.
