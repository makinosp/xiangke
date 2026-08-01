## Why

Game data lives in Godot `.tres` resource files, but the authoritative schema
and validation rules live in Rust (`extensions/core/src/character.rs`,
`validator.rs`). Today Rust never reads the real `.tres` files — its integration
test uses hand-maintained JSON "structured like" the resources — so schema drift
between the `.tres` files and the Rust core goes undetected until runtime. A
legacy GDScript validator (`data_validator.gd`) is already marked `@deprecated`
in favor of the Rust validator, but no tooling wires the real data through the
Rust path.

## What Changes

- Add a Godot export scene (`tools/data_export.tscn`) that loads all `.tres`
  files via the existing `DataLoader` and writes them to a **temporary** JSON
  file.
- Add a Rust binary crate (`tools/xiangke_checker`) in the Cargo workspace that
  deserializes the exported JSON into the core serde structs and runs the
  existing Rust validator, exiting non-zero on validation errors.
- Add a `just verify-data` recipe that chains export → validate.
- Fix drift detection: the Rust integration test's inline JSON is replaced with
  data produced by the export path, so the test exercises the real resource
  schema.
- The Go roster report tool (`tools/roster_report.go`) is left as-is for now
  (display only); its regex parser is **not** used by the verify path.

## Capabilities

### New Capabilities

- `data-verify`: A development-only command that exports `.tres` resources to
  temporary JSON and validates them against the Rust core's serde structs and
  validator, reporting errors and failing the command on invalid data.

### Modified Capabilities

<!-- None. This change introduces no requirement changes to existing specs. -->

## Impact

- **New files**: `tools/data_export.tscn` + `tools/data_export.gd`,
  `tools/xiangke_checker/` (Rust binary crate: `Cargo.toml`, `src/main.rs`).
- **Modified files**: `extensions/Cargo.toml` (workspace member), `justfile`
  (`verify-data` recipe), `extensions/core/tests/integration.rs` (test fixture
  source).
- **Dependencies**: none new beyond the existing workspace (serde, serde_json
  already present in core).
- **Dev workflow**: `just verify-data` becomes the one-command data health
  check.
- **Not affected**: game runtime, GDScript systems, CI, export targets.
