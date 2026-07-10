# Cleanup Instructions — Migration Phase 5

## Purpose

Finalize the GDScript → Rust migration: remove dead GDScript, fix config drift,
and confirm the project is fully Rust-backed.

## Cleanup Tasks

### 1. Remove Orphaned `.uid` Files

The following GDScript files were deleted in Phase 4 but their `.uid` companions
remain and now reference non-existent scripts:

- `systems/battle/action_system.gd.uid` → **DELETE** (body removed in Phase 4)
- `systems/battle/battle_manager.gd.uid` → **DELETE** (body removed in Phase 4)

Verify no other orphaned `.uid` files exist:

```bash
grep -rl "action_system\|battle_manager" systems/ scripts/ --include="*.gd"
```

Only `battle_flow_service.gd` (wrapper) and `battle_participant.gd` /
`battle_state.gd` (data holders) should remain.

### 2. Fix GDExtension WASM Release Path

File: `addons/gdext/xiangke.gdextension`

Current (WRONG):

```
web.release.wasm32 = "res://rust/target/wasm32-unknown-emscripten/release/xiangke_godot_bridge.wasm"
```

Correct (Cargo workspace is at `extensions/`):

```
web.release.wasm32 = "res://extensions/target/wasm32-unknown-emscripten/release/xiangke_godot_bridge.wasm"
```

The debug path is already correct (`res://extensions/target/...`).

### 3. Confirm GDScript Wrappers Are Thin

- `battle_participant.gd`: data holder only (no battle logic) ✅
- `battle_state.gd`: `Status` enum only ✅
- `battle_flow_service.gd`: delegates to `RustBattleSystem` ✅

No `ActionSystem` / `BattleManager` GDScript logic should remain.

### 4. Update Documentation References

Several `aidlc-docs/` plan files still reference `rust/` as the workspace root
(e.g. `phase2-core-code-generation-plan.md`,
`phase3-battle-code-generation-plan.md`). The actual location is `extensions/`.
Update paths for accuracy (non-blocking).

### 5. Final Validation

```bash
just build-rust && just inspect
just test-rust
```

Expected: build success, project loads, 100/100 Rust tests pass.
