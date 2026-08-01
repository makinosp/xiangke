# Domain Model Specification

## Purpose

Define the core domain entities, type system, business logic, and validation
rules for the turn-based command battle game.

## Requirements

### Requirement: Type System

The system SHALL define 7 element types (Wood, Fire, Earth, Metal, Water, Yang,
Yin), 6 effect types (None, Burn, Poison, Confusion, Chain, Charm), 2 damage
categories (Physical, Arts), and 5 stats (Attack, Defense, Speed, Intelligence,
Spirit).

#### Scenario: Type enum values

- **WHEN** a type enum is accessed
- **THEN** it contains exactly 7 TypeElement variants
- **AND** each variant maps to a unique `u8` discriminant

### Requirement: Type Effectiveness

The system SHALL implement the 五行 (Five Elements) and 陰陽 (Yin-Yang) type
effectiveness system with generating (1.25×), overcoming (2.0×), and overcome
(0.5×) multipliers.

#### Scenario: Generating cycle

- **WHEN** attacker's type generates defender's type (e.g., Wood → Fire)
- **THEN** the effectiveness multiplier is 1.25×

#### Scenario: Overcoming cycle

- **WHEN** attacker's type overcomes defender's type (e.g., Wood → Earth)
- **THEN** the effectiveness multiplier is 2.0×

#### Scenario: Overcome cycle

- **WHEN** attacker's type is overcome by defender's type (e.g., Earth → Wood)
- **THEN** the effectiveness multiplier is 0.5×

#### Scenario: Dual-type calculation

- **WHEN** the defender has a secondary type
- **THEN** the final multiplier is primary_mult × secondary_mult
- **AND** the result is clamped to [0.25, 4.0]

### Requirement: Character Data

The system SHALL define characters with unique ID, display name, primary type,
optional secondary type, 6 stats (HP, attack, defense, speed, intelligence,
spirit), exactly 4 moves, and flavor description.

#### Scenario: Character validation

- **WHEN** a character is validated
- **THEN** its ID is unique lowercase snake_case
- **AND** its name is 1-20 characters
- **AND** all stats are integers in [1, 999]
- **AND** stat sum ≤ 3000
- **AND** no single stat > 500
- **AND** it has exactly 4 moves
- **AND** at least one move has power > 0

### Requirement: Move Data

The system SHALL define moves with unique ID, display name, element type, damage
category, power, accuracy, optional secondary effect, optional stat
modification, optional multi-hit, optional recoil, and optional healing.

#### Scenario: Move validation

- **WHEN** a move is validated
- **THEN** its ID is unique lowercase snake_case
- **AND** power is in [0, 255] (0 = status move)
- **AND** accuracy is in [0.0, 1.0]
- **AND** stat_mod_stage is in [-6, +6]
- **AND** hit_count is in [1, 5]
- **AND** recoil and healing are in [0.0, 1.0]

### Requirement: Status Effect Data

The system SHALL define status effects with unique ID, display name, effect
type, damage per turn, escalation flag, max damage cap, and optional stat
modification.

#### Scenario: Status effect application

- **WHEN** a status effect is applied to a participant
- **THEN** the effect's damage_per_turn is applied each turn
- **AND** if escalating, damage increases each turn up to max_damage_cap
- **AND** if stat_mod_stat is set, the participant's stat is modified

### Requirement: Damage Calculation

The system SHALL calculate raw damage as
`power × (offense / defense) × type_mult × variance` with variance in [0.85,
1.0].

#### Scenario: Physical damage

- **WHEN** a Physical move is used
- **THEN** offense = attacker's Attack stat
- **AND** defense = defender's Defense stat

#### Scenario: Arts damage

- **WHEN** an Arts move is used
- **THEN** offense = attacker's Intelligence stat
- **AND** defense = defender's Spirit stat

### Requirement: Stat Stage Multipliers

The system SHALL apply stat stage multipliers from -6 (0.25×) to +6 (4.0×) with
neutral at 0 (1.0×).

#### Scenario: Stage calculation

- **WHEN** a stat stage is applied
- **THEN** the effective stat = base stat × stage multiplier
- **AND** stage is clamped to [-6, +6]

### Requirement: Battle Team Composition

The system SHALL field 3 characters per team in battle, selected from the
6-character corps. The first selected character is the initial front character.

#### Scenario: Player team fielding

- **WHEN** the player deploys 3 characters from their 6-character corps
- **THEN** the battle fields exactly those 3 player characters
- **AND** the first deployed character starts as the player's front character

#### Scenario: Enemy team fielding

- **WHEN** an enemy corps of 6 characters exists
- **THEN** the battle fields 3 enemy characters selected from that corps
- **AND** the first selected enemy character starts as the enemy's front
  character

#### Scenario: Enemy team selection

- **WHEN** the enemy team is selected for battle
- **THEN** the 3 enemy characters are chosen deterministically from the enemy
  corps by highest combined stats

### Requirement: No Target Selection

The system SHALL NOT allow the player to select an attack target. All actions
automatically target the opponent's front character.

#### Scenario: Move selection without target step

- **WHEN** the player selects a move
- **THEN** the action is executed immediately against the opponent's front
  character
- **AND** no target-selection step is presented

### Requirement: Front-line Turn Order

The system SHALL order turns by speed among the front characters of both teams
only. Benched characters never enter the turn queue.

#### Scenario: Front characters only in queue

- **WHEN** the turn queue is calculated
- **THEN** it contains exactly the non-defeated front character of each team
- **AND** benched characters are excluded

#### Scenario: Replacement enters next round

- **WHEN** a benched character replaces a defeated front character
- **THEN** the replacement does not act until the following round
