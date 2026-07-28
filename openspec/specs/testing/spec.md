# Testing Specification

## Purpose

Define the two-tier testing strategy: Rust unit tests (primary) and GDScript
integration tests (secondary).

## Requirements

### Requirement: Rust Test Framework

The system SHALL use Rust's built-in `#[cfg(test)]` with `#[test]` attribute for
all Rust tests.

#### Scenario: Running all tests

- **WHEN** `cargo test --workspace` is run
- **THEN** all tests across all three crates execute
- **AND** results are reported with pass/fail per test

### Requirement: Rust Test Coverage

The system SHALL maintain 55+ tests in `xiangke-core` (types, character, moves,
status, calc, validator), 45+ tests in `xiangke-battle` (participant, state,
action, manager, flow), and 3+ tests in `xiangke-godot-bridge`.

#### Scenario: Core crate tests

- **WHEN** `cargo test -p xiangke-core` is run
- **THEN** 55+ tests pass covering types, character, moves, status, calc, and
  validator modules

#### Scenario: Battle crate tests

- **WHEN** `cargo test -p xiangke-battle` is run
- **THEN** 45+ tests pass covering participant, state, action, manager, and flow
  modules

### Requirement: GDScript Test Runner

The system SHALL provide a GDScript test runner at `tests/test_runner.gd` that
discovers and runs test scripts with optional `--test-pattern` filtering.

#### Scenario: Running GDScript tests

- **WHEN** `godot --headless -s res://tests/test_runner.gd` is run
- **THEN** all registered test scripts execute
- **AND** results are printed with pass/fail counts

#### Scenario: Filtered test execution

- **WHEN**
  `godot --headless -s res://tests/test_runner.gd -- --test-pattern=type` is run
- **THEN** only test scripts matching "type" in their path are executed

### Requirement: GDScript Test Scripts

The system SHALL provide GDScript test scripts for GameManager, SaveManager,
UIFocusManager, type enums, and type chart.

#### Scenario: Test script registration

- **WHEN** the test runner loads
- **THEN** it discovers test scripts from the TEST_SCRIPTS constant array
- **AND** each script is executed in sequence

### Requirement: Integration Tests

The system SHALL verify the GDScript ↔ Rust bridge by building the Rust library,
loading it in Godot, and running a battle flow.

#### Scenario: Build verification

- **WHEN** `cargo build --workspace` succeeds
- **THEN** a `.dylib`/`.so`/`.dll` bridge library is produced in `target/debug/`

#### Scenario: Godot runtime verification

- **WHEN** the Godot project is opened with the compiled bridge library
- **THEN** RustBattleSystem appears as a valid Node type
- **AND** no GDExtension errors appear in the Output panel

### Requirement: CI Pipeline

The system SHALL run `cargo fmt --check`, `cargo clippy`, `cargo build`
(native + WASM), and `cargo test` on every push via GitHub Actions.

#### Scenario: CI execution

- **WHEN** code is pushed to the repository
- **THEN** GitHub Actions runs the rust-ci.yml workflow
- **AND** all steps must pass for the workflow to succeed
