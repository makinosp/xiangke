# Rust Bridge Specification

## Purpose

Define the Rust GDExtension bridge layer that exposes core battle logic to
GDScript via three crates in a Cargo workspace.

## Requirements

### Requirement: Crate Architecture

The system SHALL organize Rust code into three crates: `xiangke-core` (shared
domain types), `xiangke-battle` (battle mechanics), and `xiangke-godot-bridge`
(GDExtension entry point).

#### Scenario: Workspace compilation

- **WHEN** `cargo build --workspace` is run
- **THEN** all three crates compile successfully
- **AND** `xiangke-godot-bridge` produces a shared library
  (`.dylib`/`.so`/`.dll`)

### Requirement: Core Types

The `xiangke-core` crate SHALL define TypeElement enum (7 types), EffectType
enum (6 effects), DamageCategory enum (2 categories), Stat enum (5 stats),
TypeChart struct (7×7 matrix), CharacterData, MoveData, StatusEffectData, damage
calculation functions, and validation functions.

#### Scenario: Type enum roundtrip

- **WHEN** a TypeElement value is converted to `u8` and back
- **THEN** the original value is preserved

#### Scenario: Type chart lookup

- **WHEN** `TypeChart::effectiveness(attack, defense)` is called
- **THEN** the correct multiplier from the 7×7 matrix is returned
- **AND** row index = defender, column index = attacker

#### Scenario: Damage calculation

- **WHEN** `calculate_raw_damage(power, offense, defense, type_mult, variance)`
  is called
- **THEN** the result is `power × (offense / defense) × type_mult × variance`

### Requirement: Battle Mechanics

The `xiangke-battle` crate SHALL implement BattleParticipant with runtime state,
BattleState with turn management, ActionSystem with damage formula,
BattleManager with turn queue, and AiStrategy trait with BasicAi implementation.

#### Scenario: Battle participant creation

- **WHEN** a BattleParticipant is created from valid CharacterData
- **THEN** current_hp equals max_hp
- **AND** is_defeated is false
- **AND** stat_stages are all 0

#### Scenario: Turn queue ordering

- **WHEN** turn queue is calculated
- **THEN** participants are ordered by speed descending
- **AND** defeated participants are excluded

#### Scenario: Battle end detection

- **WHEN** all enemy participants have current_hp = 0
- **THEN** battle_status is Victory
- **WHEN** all player participants have current_hp = 0
- **THEN** battle_status is Defeat

### Requirement: GDExtension Bridge

The `xiangke-godot-bridge` crate SHALL expose a RustBattleSystem Node with
`#[func]` methods for battle initialization, action execution, state
serialization, and battle log access.

#### Scenario: Bridge method registration

- **WHEN** the GDExtension library is loaded by Godot
- **THEN** RustBattleSystem appears as a valid Node type
- **AND** all `#[func]` methods are callable from GDScript

#### Scenario: Data conversion

- **WHEN** GDScript Dictionaries are passed to RustBattleSystem
- **THEN** they are converted to Rust types via dict_to_character/dict_to_move
- **AND** Rust types are serialized back via participant_to_dict/result_to_dict

### Requirement: Test Coverage

The Rust crates SHALL maintain comprehensive test coverage: 55+ tests for core,
45+ tests for battle, 3+ tests for bridge.

#### Scenario: Test execution

- **WHEN** `cargo test --workspace` is run
- **THEN** all 103+ tests pass
- **AND** there are 0 failures
