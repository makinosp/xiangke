# Domain Entities — Unit 3: Battle System

This document defines the core domain entities for the Battle System.

## Entities

### 1. BattleState

The central state object representing the current status of a battle.

- **Properties**:
  - `battle_id`: Unique identifier for the battle.
  - `turn_count`: Current turn number (1-indexed).
  - `round_count`: Current round number.
  - `participants`: List of `BattleParticipant` objects.
  - `active_participant`: The `BattleParticipant` whose turn it is.
  - `field_effect`: Current active field effect (e.g., "Burning", "Rainy").
  - `battle_status`: Current state of the battle (`ACTIVE`, `VICTORY`, `DEFEAT`,
    `DRAW`).
  - `turn_queue`: Ordered list of participants for the current round.

### 2. BattleParticipant

Represents a character involved in the battle.

- **Properties**:
  - `character_data`: Reference to the `CharacterData` resource.
  - `current_hp`: Current health points.
  - `max_hp`: Maximum health points.
  - `current_mp`: Current mana/energy points.
  - `max_mp`: Maximum mana/energy points.
  - `stat_stages`: Dictionary mapping stats (ATK, DEF, SPD, etc.) to their
    current stage modifiers (e.g., -6 to +6).
  - `active_status_effects`: List of `StatusEffect` instances currently
    affecting the participant.
  - `team`: Team affiliation (`PLAYER` or `ENEMY`).
  - `is_defeated`: Boolean indicating if the participant is out of combat.

### 3. Action

Represents a specific move or command executed by a participant.

- **Properties**:
  - `move_data`: Reference to the `MoveData` resource.
  - `source`: The `BattleParticipant` performing the action.
  - `target`: The `BattleParticipant` (or participants) receiving the action.
  - `action_type`: Type of action (`ATTACK`, `BUFF`, `DEBUFF`, `HEAL`, `ITEM`,
    `FLEE`).
  - `calculated_value`: The final value (damage, healing, etc.) after all
    modifiers.

### 4. TurnManager

Logic entity responsible for managing the sequence of turns.

- **Responsibilities**:
  - Recalculating the `turn_queue` at the start of each round based on
    `BattleParticipant` speed.
  - Advancing the `active_participant`.
  - Triggering round-start and round-end events.

### 5. BattleFlowService

The coordinator that manages the high-level battle loop.

- **Responsibilities**:
  - Orchestrating the transition between different battle phases.
  - Requesting actions from the `PlayerUI` or `AIController`.
  - Passing the selected `Action` to the `ActionSystem` for execution.
  - Evaluating win/loss conditions after every action.

## Relationships

- `BattleState` contains multiple `BattleParticipant`s.
- `BattleParticipant` has multiple `StatusEffect`s.
- `Action` links a `BattleParticipant` (source) to another `BattleParticipant`
  (target) using `MoveData`.
- `BattleFlowService` uses `TurnManager` to update `BattleState`.
