## MODIFIED Requirements

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
