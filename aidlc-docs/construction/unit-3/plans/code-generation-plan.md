# Code Generation Plan — Unit 3: Battle System

## Unit Context

- **Unit**: Unit 3: Battle System
- **Purpose**: Core battle logic and turn management.
- **Dependencies**: Resources (Unit 1), Game Foundation (Unit 2)
- **Target Platform**: Web (HTML5), Desktop for dev/testing
- **Engine**: Godot 4.x, GDScript

---

## Code Generation Strategy

**Core Principle**: Maximize type safety using GDScript's static typing, enums,
and class-based structures.

### 1. Data Structures & State Management

- [x] Create `systems/battle/battle_participant.gd`
  - Define `BattleParticipant` class (wraps `CharacterData`, tracks current
    HP/stat stages).
  - Use strict typing for all properties.
- [x] Create `systems/battle/battle_state.gd`
  - Define `BattleState` class (tracks current turn, participant list, combat
    log, win/loss evaluation).
- [x] Create `systems/battle/battle_manager.gd`
  - Implement initiative calculation (Speed-based).
  - Manage the turn loop (Start Turn -> Action -> End Turn).
  - Handle win/loss conditions.

### 2. Core Logic - Action & Damage

- [x] Create `systems/battle/action_system.gd`
  - Implement
    `calculate_damage(attacker: BattleParticipant, defender: BattleParticipant, move: MoveData) -> ActionResult`.
  - Implement type effectiveness logic (using `TypeEnums` and `TypeChart`).
  - Implement stat stage application logic.
  - Implement `execute_move(...)` to handle the sequence of damage, effects, and
    recoil.

### 3. Core Logic - Turn & Flow Control

- [x] Create `systems/battle/battle_manager.gd`
  - Implement initiative calculation (Speed-based).
  - Manage the turn loop (Start Turn -> Action -> End Turn).
  - Handle win/loss conditions.
- [x] Create `systems/battle/battle_flow_service.gd`
  - Orchestrate the interaction between `BattleManager` and `ActionSystem`.
  - Provide signals for UI updates (e.g., `signal turn_started(participant)`,
    `signal damage_dealt(amount)`).
  - AI action selection (target weakest enemy, use best move).

### 4. Integration & UI

- [x] Update `scenes/battle_scene.tscn`
  - Replace placeholder nodes with actual UI components (HUD, Action Menu,
    Battle Log, Move Container).
- [x] Create `scripts/foundation/battle_scene.gd`
  - Connect the scene to `BattleFlowService`.
  - Handle input for player action selection and targeting.
  - Display HP status and battle log.

---

## Verification Plan

- [x] **Static Analysis**: Ensure no type errors in GDScript.
- [ ] **Unit Tests**: Verify damage calculation and turn order logic.
- [ ] **Integration Test**: Verify a full battle loop from start to win/loss.
