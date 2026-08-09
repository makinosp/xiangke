## Purpose

Extends the front-line battle specification to clarify that non-damaging moves (power = 0) with stat modifications apply to the attacker (SELF) or defender (TARGET) based on the `stat_mod_target` field, and do not target the opponent's front character.

## MODIFIED Requirements

### Requirement: Front-targeted Attacks

The system SHALL always target the opponent's front character when a damaging action is performed; players and AI cannot choose a target.

#### Scenario: Player action targets front

- **WHEN** the player selects a move
- **THEN** the move is applied to the opponent's current front character

#### Scenario: AI action targets front

- **WHEN** the AI selects a move
- **THEN** the move is applied to the player's current front character

#### Scenario: Non-damaging move stat modification target

- **WHEN** a non-damaging move (`power = 0`) with `stat_mod_stat` is executed
- **THEN** the stat modification applies to the user (SELF) or target (TARGET) based on `stat_mod_target`
- **AND** the move still targets the opponent's front character for accuracy checks
- **AND** if `stat_mod_target = SELF`, the attacker's stat stage is modified
- **AND** if `stat_mod_target = TARGET`, the defender's stat stage is modified

## ADDED Requirements

### Requirement: Non-Damaging Move Effects

The system SHALL apply effects (stat modification, healing, status effect) for non-damaging moves regardless of whether damage is dealt.

#### Scenario: Stat modification on non-damaging move

- **WHEN** a move with `power = 0` and `stat_mod_stat` set is executed
- **THEN** the stat modification is applied to the appropriate participant
- **AND** a log message describing the effect is generated

#### Scenario: Healing on non-damaging move

- **WHEN** a move with `power = 0` and `healing > 0` is executed
- **THEN** the attacker's HP is restored by `healing%` of max HP
- **AND** a log message describing the healing is generated

#### Scenario: Status effect on non-damaging move

- **WHEN** a move with `power = 0` and `effect` set is executed
- **THEN** the target may be afflicted with the status effect based on `effect_chance`
- **AND** a log message describing the effect is generated