# Infrastructure Design Plan — Phase 1: Toolchain Setup

## Overview

Design the Rust development toolchain, Cargo workspace structure, godot-rust
(gdext) integration, and build pipeline for the GDScript → Rust migration.

## Prerequisites Analysis

This phase has no functional design (toolchain setup is purely infrastructure).
The execution plan defines the scope: Rust toolchain + gdext skeleton.

---

## Infrastructure Design Questions

Please answer the following questions about the development toolchain
infrastructure.

### Question 1

What Rust edition should the project use?

A) Rust 2021 edition (stable, widely compatible with current crates)

B) Rust 2024 edition (latest, if stable by the time of implementation)

C) Whatever is latest stable (use `rustup` default)

X) Other (please describe after [Answer]: tag below)

[Answer]:

### Question 2

What is the target Godot version for gdext compatibility?

A) Godot 4.3 (latest stable, widely supported by gdext)

B) Godot 4.4 (newer, may have gdext updates)

C) Whatever the project.godot currently specifies (check first)

X) Other (please describe after [Answer]: tag below)

[Answer]:

### Question 3

How should the Cargo workspace be structured?

A) Single crate: `rust/` with one library crate containing all Rust code

B) Multi-crate workspace: `rust/` workspace with separate crates for `core`
(data types), `battle` (battle system), and `godot_bridge` (gdext bindings)

C) Workspace + external crate: Cargo workspace in `rust/` with a `gdext` binding
crate, core logic as a separate library crate for testability

X) Other (please describe after [Answer]: tag below)

[Answer]:

### Question 4

What build pipeline approach for the GDExtension binary?

A) Manual: Developer runs `cargo build` separately, copies `.gdextension` binary
into Godot project

B) Scripted: Shell script or `justfile` recipe that builds Rust and then runs
Godot

C) Godot pre-build hook: Use Godot's build system to invoke Cargo before export

D) CI-only: Build GDExtension only in CI/CD pipeline; use pre-built dev binaries
locally

X) Other (please describe after [Answer]: tag below)

[Answer]:

### Question 5

What development workflow for iterating between Rust and Godot?

A) Editor-based: Edit Rust in VS Code, switch to Godot editor to test, manually
rebuild

B) Watcher-based: Use `cargo watch` to auto-rebuild on Rust changes; Godot
reloads GDExtension

C) Test-first: Write Rust unit tests (`#[cfg(test)]`), iterate via `cargo test`,
integrate with Godot later

D) Hybrid: Use unit tests for core logic, Godot for integration tests only

X) Other (please describe after [Answer]: tag below)

[Answer]:

### Question 6

What is the CI/CD approach for Rust builds?

A) None — local builds only (internal tool, no CI)

B) GitHub Actions — build Rust GDExtension and run `cargo test` on push

C) GitHub Actions — build + test + export Godot with GDExtension included

D) Full CI/CD — same as C plus deploy to GitHub Pages for Web (WASM) target

X) Other (please describe after [Answer]: tag below)

[Answer]:

### Question 7

How should Rust dependencies (crates) be managed?

A) Minimal dependencies — only `godot` crate, implement everything else from
scratch

B) Pragmatic — `godot` + `serde`/`serde_json` for serialization + `rand` for RNG
(battle variance)

C) Rich ecosystem — `godot` + `serde` + `rand` + `thiserror`/`anyhow` for error
handling + `strum` for enum utilities

X) Other (please describe after [Answer]: tag below)

[Answer]:

[Answer]:
