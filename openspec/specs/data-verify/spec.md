# Data Verify Specification

## Purpose

Development-only verification that game data resources conform to the
authoritative Rust core schema and validation rules, so schema drift is caught
before runtime.

## Requirements

### Requirement: Export resources to JSON

The system SHALL produce a JSON representation of all character and move
resources by loading them through the same code path the game uses at runtime.

#### Scenario: All resources export successfully

- **WHEN** the verify command runs in a project with valid resource files
- **THEN** a JSON file containing every character and move from the resource
  directories is produced

#### Scenario: Corrupted resource is detected

- **WHEN** a resource file cannot be loaded normally and a fallback placeholder
  would otherwise be substituted
- **THEN** the export reports an error instead of silently exporting placeholder
  data

### Requirement: Validate exported data against core schema and rules

The system SHALL check every exported entity against the authoritative core data
schema and validation rules.

#### Scenario: Valid data passes

- **WHEN** all exported data conforms to the core schema and validation rules
- **THEN** no errors are reported

#### Scenario: Field drift is detected

- **WHEN** a resource contains a field name or type that no longer matches the
  core schema
- **THEN** an error is reported identifying the affected entity and the
  mismatched field

#### Scenario: Rule violation is reported

- **WHEN** an entity violates a core validation rule (for example, stat budget
  or required move count)
- **THEN** an error is reported including the rule code and affected entity

### Requirement: Command exit status

The verify command SHALL exit with a non-zero status when any validation error
is found, and with zero when validation passes.

#### Scenario: Failure exit code

- **WHEN** validation finds one or more errors
- **THEN** the command exits non-zero
- **AND** prints a summary of errors and warnings

#### Scenario: Success exit code

- **WHEN** validation finds no errors
- **THEN** the command exits zero

### Requirement: Single-command workflow

The project SHALL expose a single command that performs export and validation in
sequence.

#### Scenario: One invocation validates everything

- **WHEN** a developer runs the verify command
- **THEN** resources are exported and validated without additional steps
