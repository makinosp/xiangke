# Tech Stack Decisions — Unit 3: Battle System

## Overview

This document details the technology and architectural decisions for the Battle
System unit.

---

## 1. Core Technologies

| Decision        | Choice                   | Justification                                               |
| --------------- | ------------------------ | ----------------------------------------------------------- |
| **Language**    | GDScript                 | Godot 4.x standard scripting language; type-safe, idiomatic |
| **Engine**      | Godot 4.x                | Project standard; provides all needed features              |
| **Data Format** | `.tres` (Resource files) | Native Godot format; efficient loading, type-safe           |

---

## 2. Architecture Pattern

### 2.1 Overall Pattern

**Node-based architecture with Service pattern**

The Battle System follows Godot's node-based architecture with service classes
for complex logic:

- **battle_manager.gd**: Main battle orchestrator (Node)
- **action_system.gd**: Action execution logic (Node or autoload)
- **battle_flow_service.gd**: Turn coordination (Node or autoload)

### 2.2 Component Organization

```
systems/battle/
├── battle_manager.gd      # Main battle state and coordination
├── action_system.gd       # Action execution and damage calculation
├── battle_flow_service.gd # Turn flow and phase management
└── battle_state.gd        # Data class for battle state (optional)
```

---

## 3. Data Management

### 3.1 Battle State Storage

- **In-memory object**: `BattleState` class holds all mutable battle data
- **No persistence**: Battles complete in one session (per NFR-4.1)

### 3.2 Data Loading

- **Preloaded resources**: Character and move data loaded via `preload()`
- **Runtime validation**: Data validated on load (per NFR-3.1)

---

## 4. Communication Patterns

### 4.1 Internal Communication

- **Godot Signals**: Used for event-driven communication between components
  - `action_executed(action)`
  - `turn_changed(participant)`
  - `battle_ended(result)`

### 4.2 External Integration

- **PlayerUI**: Callback-based action request
- **AIController**: Method call `get_action(battle_state)`

---

## 5. Performance Considerations

### 5.1 Optimization Targets

- Damage calculation: < 10ms
- Turn processing: < 100ms
- Animation: Fast-paced (0.5-1s per action)

### 5.2 Memory Management

- Single `BattleState` instance per battle
- Estimated memory: < 10MB (per NFR-2.2)

---

## 6. Error Handling Strategy

### 6.1 Development Mode

- **Fail-fast**: Errors crash with clear messages
- **Validation**: All inputs validated before processing
- **Debug logging**: Full calculation breakdown available

### 6.2 Production Considerations

- Error messages should be user-friendly
- Graceful degradation for edge cases

---

## 7. Testing Strategy

### 7.1 Unit Tests

- Damage calculation formula
- Type effectiveness resolution
- Status effect application/removal
- Turn order calculation

### 7.2 Integration Tests

- Full battle flow (player vs enemy)
- Action execution pipeline
- Win/loss condition detection

---

## 8. Future Extensibility

### 8.1 Planned Extensions

- Turn timer (currently disabled per NFR-7.2)
- Battle state persistence (currently not needed per NFR-4.1)
- Larger battle sizes (currently 1v1 per NFR-2.1)

### 8.2 Extension Points

- `BattleParticipant` can be extended for different entity types
- `Action` system supports new move types
- `StatusEffect` system supports new effects
