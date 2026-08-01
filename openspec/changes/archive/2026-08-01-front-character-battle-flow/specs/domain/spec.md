## ADDED Requirements

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
