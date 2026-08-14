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

- **WHEN** the AI takes its turn and selects a damaging move
- **THEN** the move is applied to the player's current front character
- **AND** the AI's own front character is never selected as the target

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

### Requirement: AI Action Selection

The system SHALL select an AI action (a damaging move or a bench switch) through
the battle engine's AI strategy when an enemy participant takes its turn. The AI
SHALL evaluate type effectiveness correctly for both single-type and dual-type
defenders, SHALL never select a healing move as an attack, SHALL switch when its
moves are ineffective (0x) or at a type disadvantage, SHALL prefer the living
benched participant with the best type effectiveness when switching, and SHALL
compare attacking against switching so it attacks when it can defeat the
opponent's front.

#### Scenario: AI chooses a damaging move

- **WHEN** the enemy front's turn begins and a damaging move is available
- **THEN** the AI selects the move with the highest heuristic score
- **AND** the move is executed against the player's front character

#### Scenario: AI evaluates single-type effectiveness correctly

- **WHEN** the player's front character has no secondary element
- **THEN** the AI computes type effectiveness using the single-type lookup
- **AND** the effectiveness is not squared by applying the primary element twice

#### Scenario: AI never selects a healing move as an attack

- **WHEN** the enemy front has no usable damaging move and only healing moves
  remain
- **THEN** the AI does not select a healing move as an attack
- **AND** the AI performs no action or switches instead

#### Scenario: AI switches at low HP

- **WHEN** the enemy front's HP ratio is below 0.3 and a living benched enemy
  exists
- **THEN** the AI switches with a living benched enemy
- **AND** the switch consumes the enemy's turn for the round

#### Scenario: AI switches on type disadvantage

- **WHEN** the enemy front's best effectiveness against the player's front is at
  most 0.5 (including 0x) and a living benched enemy is not worse off
- **THEN** the AI switches with that benched enemy

#### Scenario: AI switches to the best benched participant

- **WHEN** the AI decides to switch and multiple living benched enemies exist
- **THEN** the AI switches with the benched enemy having the best type
  effectiveness against the player's front

#### Scenario: AI attacks when it can defeat the front

- **WHEN** the enemy front is at low HP but a damaging move would defeat the
  player's front
- **THEN** the AI attacks instead of switching

#### Scenario: AI turn without valid action

- **WHEN** the AI has no living benched participants and no usable move
- **THEN** the AI performs no action and its turn ends
