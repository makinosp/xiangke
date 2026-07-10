# Build Instructions

## Prerequisites
- **Build Tool**: Rust 2024 edition via `rustc`/`cargo` (MSRV determined by workspace)
- **Dependencies**: `godot` (gdext) 0.5.4, `rand` 0.8, `xiangke-core`, `xiangke-battle` (workspace members)
- **System Requirements**: macOS (tested on Darwin arm64), Linux or Windows also supported

## Build Steps

### 1. Build All Crates
```bash
cargo build --workspace
```

### 2. Build Release (Optional)
```bash
cargo build --release --workspace
```

### 3. Verify Build Success
- **Expected Output**: `Finished dev profile [unoptimized + debuginfo] target(s) in X.XXs`
- **Build Artifacts**: `target/debug/libxiangke_godot_bridge.{dylib,so,dll}`
- **Common Warnings**: 0 warnings expected

## Troubleshooting

### Build Fails with gdext Errors
- **Cause**: `godot-rust` 0.5.4 requires specific Godot 4.x headers. If compilation fails on `godot::` imports, re-run `cargo build` to rebuild proc macros.

### Build Fails with Missing Dependency
- **Cause**: Workspace dependency not resolved
- **Solution**: Ensure all crates are listed in `rust/Cargo.toml` workspace members
