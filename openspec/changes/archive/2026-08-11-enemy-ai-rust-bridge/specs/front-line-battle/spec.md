## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: AI Action Selection

The system SHALL select an AI action (a damaging move or a bench switch) through
the battle engine's AI strategy when an enemy participant takes its turn.

#### Scenario: AI chooses a damaging move

- **WHEN** the enemy front's turn begins and a damaging move is available
- **THEN** the AI selects the move with the highest heuristic score
- **AND** the move is executed against the player's front character

#### Scenario: AI switches at low HP

- **WHEN** the enemy front's HP ratio is below 0.3 and a living benched enemy
  exists
- **THEN** the AI switches with a living benched enemy
- **AND** the switch consumes the enemy's turn for the round

#### Scenario: AI switches on type disadvantage

- **WHEN** the enemy front's best effectiveness against the player's front is at
  most 0.5 and a living benched enemy is not worse off
- **THEN** the AI switches with that benched enemy

#### Scenario: AI turn without valid action

- **WHEN** the AI has no living benched participants and no usable move
- **THEN** the AI performs no action and its turn ends
