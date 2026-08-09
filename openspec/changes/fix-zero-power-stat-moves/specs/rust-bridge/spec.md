## Purpose

Extends the GDExtension bridge to handle the new `stat_mod_target` field and stat modification effects for non-damaging moves.

## MODIFIED Requirements

### Requirement: Data conversion

The system SHALL convert GDScript Dictionaries to Rust types via dict_to_character/dict_to_move and serialize Rust types back via participant_to_dict/result_to_dict.

#### Scenario: Move data conversion with stat_mod_target

- **WHEN** GDScript passes a move Dictionary containing `stat_mod_target`
- **THEN** the value is converted to `StatModTarget` enum (0 = SELF, 1 = TARGET)
- **AND** the default value is SELF if the field is missing

#### Scenario: Stat modification result serialization

- **WHEN** a move applies a stat modification
- **THEN** the result dictionary includes `stat_mod_applied` with the affected stat index
- **AND** the result dictionary includes `stat_mod_stage` with the stage change amount

## ADDED Requirements

### Requirement: StatModTarget Enum

The `xiangke-godot-bridge` crate SHALL define `StatModTarget` enum with values `Self_ = 0` and `Target = 1` for representing stat modification targets.

#### Scenario: StatModTarget enum definition

- **WHEN** the bridge module is compiled
- **THEN** `StatModTarget` is available with `Self_ = 0` and `Target = 1`

### Requirement: Stat Modification Application

The system SHALL apply stat modifications during `execute_player_action` for moves with `stat_mod_stat` set.

#### Scenario: Self-targeted stat buff application

- **WHEN** `execute_player_action` is called with a move having `stat_mod_target = SELF`
- **THEN** the attacker's stat stage is modified by `stat_mod_stage`
- **AND** the participant's `stat_stages` array is updated

#### Scenario: Target-targeted stat debuff application

- **WHEN** `execute_player_action` is called with a move having `stat_mod_target = TARGET`
- **THEN** the defender's stat stage is modified by `stat_mod_stage`
- **AND** the participant's `stat_stages` array is updated