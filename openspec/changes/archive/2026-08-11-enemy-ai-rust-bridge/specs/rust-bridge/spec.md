## ADDED Requirements

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
