# Build Instructions — Migration Phase 5 (Cleanup & Test)

## Prerequisites

- **Godot**: 4.3+ (matches `compatibility_minimum` in
  `addons/gdext/xiangke.gdextension`)
- **Rust**: stable toolchain (edition 2024), plus `nightly` + `rust-src` +
  `wasm32-unknown-emscripten` target for Web builds
- **Emscripten SDK**: 3.1.74 (for WASM builds)
- **System Requirements**: macOS/Linux/Windows for native; ~2 GB disk for target
  artifacts

## Build Steps

### 1. Install Rust Dependencies

```bash
rustup toolchain install nightly
rustup component add rust-src --toolchain nightly
rustup target add wasm32-unknown-emscripten --toolchain nightly
rustup target add wasm32-unknown-emscripten
```

### 2. Build Rust GDExtension (Native)

```bash
just build-rust
# equivalent: cd extensions && cargo build
```

Expected artifact: `extensions/target/debug/libxiangke_godot_bridge.*`
(platform-specific suffix).

### 3. Build Rust GDExtension (Web / WASM)

```bash
just build-rust-wasm
# or release + size-optimized:
just build-rust-wasm-release
```

Expected artifact:
`extensions/target/wasm32-unknown-emscripten/debug/xiangke_godot_bridge.wasm`.

> **NOTE**: The `.gdextension` `web.release.wasm32` path currently points to
> `res://rust/target/...` which is **incorrect** — the Cargo workspace lives at
> `extensions/`, not `rust/`. Fix before release export (see Cleanup section).

### 4. Verify Godot Project Loads

```bash
just inspect
# equivalent: godot --headless --check-only --quit
```

Expected: project parses with no script errors, GDExtension `RustBattleSystem`
class registered.

### 5. Run Full Game (Manual)

```bash
just run
# builds Rust, then launches Godot editor
```

Flow to validate: Title → Character Select → Deploy → Battle → Result.

## Troubleshooting

### GDExtension fails to load (`RustBattleSystem` unknown)

- **Cause**: native `.dylib/.so/.dll` not built or path mismatch in
  `.gdextension`.
- **Solution**: run `just build-rust`; verify library path matches
  `addons/gdext/`.

### WASM export fails to find binary

- **Cause**: `web.release.wasm32` path `res://rust/target/...` is wrong.
- **Solution**: change to
  `res://extensions/target/wasm32-unknown-emscripten/release/xiangke_godot_bridge.wasm`.

### `cargo build` fails on WASM target

- **Cause**: missing `rust-src` or Emscripten env not sourced.
- **Solution**: `source ./emsdk/emsdk_env.sh` then rebuild.
