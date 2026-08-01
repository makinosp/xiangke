## 1. Godot export scene

- [x] 1.1 Create `tools/data_export.gd` tool scene script that reads
      `--export-path=<abs>` from `OS.get_cmdline_user_args()`
- [x] 1.2 Export all characters and moves via `DataLoader.load_all()`,
      serializing each resource's fields explicitly to dictionaries
- [x] 1.3 Detect placeholder substitution (name "Unknown" / "Data missing or
      corrupted" description) and treat it as an export error
- [x] 1.4 Write JSON to the export path and quit with exit code 0 on success, 1
      on failure
- [x] 1.5 Create `tools/data_export.tscn` scene and verify it runs headless:
      `godot --headless res://tools/data_export.tscn -- --export-path=/tmp/xiangke_data.json`

## 2. Rust checker crate

- [x] 2.1 Create `tools/xiangke_checker/` binary crate (`Cargo.toml`,
      `src/main.rs`) depending on `xiangke-core` and `serde_json`
- [x] 2.2 Add `tools/xiangke_checker` to the workspace members in
      `extensions/Cargo.toml`
- [x] 2.3 Implement `validate <path>` subcommand: read export JSON, deserialize
      into core `CharacterData` / `MoveData` structs
- [x] 2.4 Implement strict field check: compare JSON keys against expected field
      sets to report unknown/missing fields
- [x] 2.5 Run `validate_move` / `validate_character` per entity, collect into
      one `ValidationResult`, print summary
- [x] 2.6 Exit non-zero when `!is_valid()`, zero otherwise
- [x] 2.7 Build and smoke-test against a sample export:
      `cargo run -p xiangke_checker -- validate /tmp/xiangke_data.json`

## 3. Integration fixture

- [x] 3.1 Add `extensions/core/tests/fixtures/resources.json` generated from the
      export output
- [x] 3.2 Replace the hand-written inline JSON in
      `extensions/core/tests/integration.rs` with the fixture file
- [x] 3.3 Verify `cargo test -p xiangke-core` passes with the fixture

## 4. justfile workflow

- [x] 4.1 Add `just verify-data` recipe: export to a temp path, run checker,
      report result
- [x] 4.2 Add `just verify-data UPDATE_FIXTURE=1` variant that regenerates the
      committed fixture
- [x] 4.3 Run `just verify-data` against the real resources and confirm zero
      errors with current data

## 5. Documentation and validation

- [x] 5.1 Document `just verify-data` in README (dev tooling section)
- [x] 5.2 Run `openspec validate --all --no-interactive` and fix any issues
