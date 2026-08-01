## ADDED Requirements

### Requirement: Front-line Battle Test Coverage

The Rust crates SHALL include tests covering switch mechanics, automatic bench
replacement, and front-targeted actions.

#### Scenario: Switch tests

- **WHEN** `cargo test -p xiangke-battle` is run
- **THEN** tests verify a successful switch swaps front flags
- **AND** tests verify switch to a defeated or already-front participant fails

#### Scenario: Bench replacement tests

- **WHEN** `cargo test -p xiangke-battle` is run
- **THEN** tests verify the first living benched participant replaces a defeated
  front participant

#### Scenario: Front-targeted action tests

- **WHEN** `cargo test -p xiangke-battle` is run
- **THEN** tests verify actions resolve the opponent's front participant as the
  target

### Requirement: GDScript Battle Flow Tests

The system SHALL provide GDScript tests covering the front-line battle flow
including turn advancement with a benched team and battle end conditions.

#### Scenario: GDScript test execution

- **WHEN** `godot --headless res://tests/test_runner.tscn` is run
- **THEN** front-line battle flow tests execute without errors
