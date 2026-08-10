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
- **AND** is_front is false

#### Scenario: Turn queue ordering

- **WHEN** turn queue is calculated
- **THEN** only front-line participants are ordered by speed descending
- **AND** benched and defeated participants are excluded

#### Scenario: Front-line assignment at battle start

- **WHEN** a battle starts
- **THEN** the first participant of each team is marked as the front character
- **AND** all other participants remain benched

#### Scenario: Battle end detection

- **WHEN** all enemy participants have current_hp = 0
- **THEN** battle_status is Victory
- **WHEN** all player participants have current_hp = 0
- **THEN** battle_status is Defeat

#### Scenario: Switch action

- **WHEN** a team executes a switch to a living benched participant
- **THEN** the benched participant becomes the front character
- **AND** the former front character becomes benched
- **AND** stat stages and status effects are preserved

#### Scenario: Switch validation

- **WHEN** a switch targets a defeated participant or the current front
  participant
- **THEN** the switch is rejected with an invalid-target error

#### Scenario: Automatic bench replacement

- **WHEN** the front participant becomes defeated
- **THEN** the first living benched participant becomes the front character
- **AND** the replacement is excluded from acting until the next round

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
- **AND** participant dictionaries include the is_front flag

#### Scenario: Move data conversion with stat_mod_target

- **WHEN** GDScript passes a move Dictionary containing `stat_mod_target`
- **THEN** the value is converted to `StatModTarget` enum (0 = SELF, 1 = TARGET)
- **AND** the default value is SELF if the field is missing

#### Scenario: Stat modification result serialization

- **WHEN** a move applies a stat modification
- **THEN** the result dictionary includes `stat_mod_applied` with the affected
  stat index
- **AND** the result dictionary includes `stat_mod_stage` with the stage change
  amount

### Requirement: StatModTarget Enum

The `xiangke-godot-bridge` crate SHALL define `StatModTarget` enum with values
`Self_ = 0` and `Target = 1` for representing stat modification targets.

#### Scenario: StatModTarget enum definition

- **WHEN** the bridge module is compiled
- **THEN** `StatModTarget` is available with `Self_ = 0` and `Target = 1`

### Requirement: Stat Modification Application

The system SHALL apply stat modifications during `execute_player_action` for
moves with `stat_mod_stat` set.

#### Scenario: Self-targeted stat buff application

- **WHEN** `execute_player_action` is called with a move having
  `stat_mod_target = SELF`
- **THEN** the attacker's stat stage is modified by `stat_mod_stage`
- **AND** the participant's `stat_stages` array is updated

#### Scenario: Target-targeted stat debuff application

- **WHEN** `execute_player_action` is called with a move having
  `stat_mod_target = TARGET`
- **THEN** the defender's stat stage is modified by `stat_mod_stage`
- **AND** the participant's `stat_stages` array is updated

#### Scenario: Target-less player action

- **WHEN** GDScript calls execute_player_action with move data only
- **THEN** the action resolves the opponent's front participant as the target
- **AND** the target index is not required as an argument

#### Scenario: Automatic replacement on defeat

- **WHEN** an action defeats the opponent's front participant
- **THEN** the bridge automatically brings the first living benched enemy to the
  front

#### Scenario: Switch bridge method

- **WHEN** GDScript calls execute_switch with a bench index
- **THEN** the switch is applied and a result dictionary is returned

#### Scenario: Front and bench queries

- **WHEN** GDScript calls get_front_participant/get_bench_participants
- **THEN** the front participant and living benched participants are returned

### Requirement: AI Turn Execution

The GDExtension bridge SHALL expose a method that executes the AI strategy's
chosen action for the battle's active participant.

#### Scenario: AI turn executes attack

- **WHEN** GDScript invokes the AI turn method and the AI strategy selects a
  damaging move
- **THEN** the move is applied to the player's front character
- **AND** the result dictionary reports the action type and damage details

#### Scenario: AI turn executes switch

- **WHEN** the AI strategy selects a switch to a living benched participant
- **THEN** the team's front is swapped with the benched participant
- **AND** the result dictionary reports the switch

#### Scenario: AI attack defeats player front

- **WHEN** the AI's action defeats the player's front participant
- **THEN** the first living benched player automatically replaces the front

### Requirement: Test Coverage

The Rust crates SHALL maintain comprehensive test coverage: 55+ tests for core,
45+ tests for battle, 3+ tests for bridge.

#### Scenario: Test execution

- **WHEN** `cargo test --workspace` is run
- **THEN** all 103+ tests pass
- **AND** there are 0 failures
