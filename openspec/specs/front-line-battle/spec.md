# Front-line Battle Specification

## Purpose

Defines the front-line + bench battle model where only the leading character of
each team is active, attacks always target the opponent's front character, and
characters can switch with benched teammates.

## Requirements

### Requirement: Front-line Fielding

The system SHALL field only the front character of each team as the active
participant; all other characters of the team are benched and do not take turns.

#### Scenario: Battle start fielding

- **WHEN** a battle starts
- **THEN** exactly one character per team is the front character
- **AND** all other characters are benched

#### Scenario: Benched characters skip turns

- **WHEN** the turn queue is calculated
- **THEN** only non-defeated front characters are included
- **AND** benched characters never act

### Requirement: Front-targeted Attacks

The system SHALL always target the opponent's front character when a damaging
action is performed; players and AI cannot choose a target.

#### Scenario: Player action targets front

- **WHEN** the player selects a move
- **THEN** the move is applied to the opponent's current front character

#### Scenario: AI action targets front

- **WHEN** the AI selects a move
- **THEN** the move is applied to the player's current front character

#### Scenario: Non-damaging move stat modification target

- **WHEN** a non-damaging move (`power = 0`) with `stat_mod_stat` is executed
- **THEN** the stat modification applies to the user (SELF) or target (TARGET)
  based on `stat_mod_target`
- **AND** the move still targets the opponent's front character for accuracy
  checks
- **AND** if `stat_mod_target = SELF`, the attacker's stat stage is modified
- **AND** if `stat_mod_target = TARGET`, the defender's stat stage is modified

### Requirement: Non-Damaging Move Effects

The system SHALL apply effects (stat modification, healing, status effect) for
non-damaging moves regardless of whether damage is dealt.

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
- **THEN** the target may be afflicted with the status effect based on
  `effect_chance`
- **AND** a log message describing the effect is generated

### Requirement: Switch Action

The system SHALL allow a team to switch its front character with a living
benched character on its turn. Switching consumes the team's action for that
round, and the newly entered character acts starting the next round.

#### Scenario: Successful switch

- **WHEN** a team switches its front character to a living benched character
- **THEN** the benched character becomes the front character
- **AND** the former front character becomes benched
- **AND** the team's turn for the round is consumed

#### Scenario: Switch to defeated character rejected

- **WHEN** a team attempts to switch to a defeated benched character
- **THEN** the switch is rejected

#### Scenario: Switch to already-front character rejected

- **WHEN** a team attempts to switch to the current front character
- **THEN** the switch is rejected

### Requirement: Automatic Bench Replacement

The system SHALL automatically bring the first living benched character to the
front when the front character is defeated. The entering character cannot act
during the round it enters.

#### Scenario: Front defeated with living bench

- **WHEN** the front character is defeated
- **THEN** the first living benched character becomes the front character
- **AND** the entering character does not act that round

#### Scenario: Front defeated with empty bench

- **WHEN** the front character is defeated and no living benched characters
  exist
- **THEN** the team has no front character and the battle proceeds to win/loss
  evaluation

### Requirement: State Preservation on Switch

The system SHALL preserve stat stage modifiers and active status effects when a
character switches to the bench and back.

#### Scenario: Stat stages preserved

- **WHEN** a character with stat stage modifiers switches to the bench
- **THEN** the modifiers remain when the character returns to the front

#### Scenario: Status effects preserved

- **WHEN** a character with active status effects switches to the bench
- **THEN** the status effects remain when the character returns to the front
