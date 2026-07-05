# Code Generation Plan — Phase 1: Toolchain Setup

## Unit Context

- **Unit**: Phase 1 — Toolchain Setup
- **Purpose**: Establish Rust development environment, Cargo workspace,
  godot-rust (gdext) skeleton, and build pipeline
- **Dependencies**: None (first phase)
- **Infrastructure Design**: Completed — Rust 1.94.0 (2024 edition), Godot 4.7,
  godot-rust v0.5.4, multi-crate workspace

## Generated Artifacts

All application code goes to workspace root (never `aidlc-docs/`).

### Step 1: Create Cargo Workspace Structure

- [x] Create `rust/` directory at workspace root
- [x] Create `rust/Cargo.toml` — workspace root with members: `core`, `battle`,
      `godot_bridge`
- [x] Create `rust/core/Cargo.toml` — library crate for shared data types (no
      godot dependency)
- [x] Create `rust/core/src/lib.rs` — empty library root
- [x] Create `rust/battle/Cargo.toml` — library crate for battle system (depends
      on `core`)
- [x] Create `rust/battle/src/lib.rs` — empty library root
- [x] Create `rust/godot_bridge/Cargo.toml` — gdextension crate (depends on
      `core`, `battle`, `godot` crate)
- [x] Create `rust/godot_bridge/src/lib.rs` — empty library root with
      `#[gdextension]` attribute

### Step 2: Configure Rust Toolchain

- [x] Create `rust/rust-toolchain.toml` — pin to stable, set edition 2024
- [x] Create `rust/rustfmt.toml` — style edition 2024 configuration
- [x] Create `rust/.cargo/config.toml` — WASM target configuration

### Step 3: Create GDExtension Configuration

- [x] Create `addons/gdext/` directory at workspace root
- [x] Create `addons/gdext/xiangke.gdextension` — GDExtension entry point for
      Godot

### Step 4: Update Justfile with Rust Build Commands

- [x] Add `just build-rust` — builds Rust GDExtension
- [x] Add `just test-rust` — runs `cargo test` for all crates
- [x] Add `just run-godot` — builds Rust then runs Godot
- [x] Add `just check-rust` — runs `cargo check` for fast validation

### Step 5: Create GitHub Actions CI Workflow

- [x] Create `.github/workflows/rust-ci.yml` — build + test on push

### Step 6: Create Core Crate Skeleton with Dependencies

- [x] Add dependencies to `rust/core/Cargo.toml`: `serde`, `serde_json`, `rand`,
      `thiserror`, `strum`, `strum_macros`
- [x] Create `rust/core/src/lib.rs` with re-exports and module declarations

### Step 7: Create Battle Crate Skeleton

- [x] Add dependencies to `rust/battle/Cargo.toml`: `xiangke-core` (path dep)
- [x] Create `rust/battle/src/lib.rs` with module declarations

### Step 8: Create Godot Bridge Crate Skeleton

- [x] Add dependencies to `rust/godot_bridge/Cargo.toml`: `godot` (v0.5.4),
      `xiangke-core`, `xiangke-battle`
- [x] Create `rust/godot_bridge/src/lib.rs` with `#[gdextension]` entry point
      and empty class registration

### Step 9: Verify Build

- [x] Run `cargo check` in `rust/` directory to verify compilation
- [x] Verify `cargo test` passes (no tests yet, but compilation succeeds)

### Step 10: Generate Code Summary

- [x] Create `aidlc-docs/construction/unit1/code/toolchain-summary.md` with
      overview of generated artifacts
