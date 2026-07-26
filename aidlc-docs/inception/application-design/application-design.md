# Application Design

## Project

Turn-based command battle game built with Godot Engine 4.x / GDScript Primary
target: Web (HTML5/WebAssembly)

---

## Architecture Summary

### Pattern: Node Inheritance + Signals (Hybrid)

The project uses Godot's native node/component architecture with signal-based
communication for loose coupling between systems.

### Autoloads (Singletons)

| Autoload          | Purpose                                              |
| ----------------- | ---------------------------------------------------- |
| `GameManager`     | Global game state, scene transitions, character data |
| `AudioController` | BGM/SFX playback, volume management                  |
| `SaveManager`     | Local persistence via ConfigFile (user:// directory) |

### Scenes

| Scene             | Purpose                                   |
| ----------------- | ----------------------------------------- |
| `TitleScreen`     | Game title, start button, settings        |
| `CorpsCreation`   | Corps roster creation, 6-character select |
| `CharacterSelect` | Battle party selection, 3-from-corps      |
| `BattleScene`     | Main battle view, action menu, HP bars    |
| `ResultScreen`    | Battle outcome, score, replay option      |

---

## Components

### GameManager

- Central state machine (TITLE, CORPS_CREATION, CHARACTER_SELECT, BATTLE, RESULT)
- Stores selected player/enemy characters
- Coordinates scene transitions

### BattleManager

- Turn flow management (player → enemy → resolve)
- Action execution and damage calculation
- Win/loss condition checking

### AIController

- Enemy decision-making (moderate complexity)
- State machine with type advantage evaluation
- Considers HP thresholds for recovery moves

### ActionSystem

- Damage calculation with type effectiveness
- Move execution and effect resolution
- Speed-based action ordering

### Character

- Stats: HP, attack, defense, speed
- Move set with properties (power, type, effects)
- Status effects management

### UIController

- HP bars, status indicators
- Action menu display
- Battle log messages
- Menu navigation

### AudioController

- BGM per scene context
- SFX for actions and events
- Web autoplay policy compliance

### SaveManager

- Local storage via ConfigFile
- Player progress persistence
- Leaderboard data (high scores)
- Game settings storage

---

## Services

### BattleFlowService

Orchestrates complete battle flow:

1. Initialize with selected characters
2. Player turn → show action menu → execute action
3. Enemy turn → AIController decides → execute action
4. Resolve and check for battle end
5. Transition to result screen

### SceneTransitionService

Manages scene changes with data passing via GameManager.

### AudioService

Centralizes audio playback across scenes, handles autoplay restrictions.

### PersistenceService

Coordinates SaveManager for game state persistence.

---

## Data Flow

```
User Input → UIController → GameManager
                ↓
         BattleFlowService
                ↓
    ┌───────────┼───────────┐
    ↓           ↓           ↓
BattleManager → AIController → ActionSystem
    ↓                       ↓
    └──────→ Character ←────┘
                ↓
         UIController (update display)
                ↓
         AudioController (play SFX)
```

---

## Communication Patterns

1. **Signals** (primary): Decoupled event communication
   - `BattleManager.action_executed` → UI updates
   - `Character.hp_changed` → HP bar update
   - `BattleManager.battle_ended` → scene transition

2. **Direct calls**: Within same system
   - `BattleManager` → `ActionSystem.calculate_damage()`

3. **Autoload access**: Global singletons
   - `/root/GameManager`, `/root/AudioController`, `/root/SaveManager`

---

## Key Design Decisions

| Decision        | Choice                         | Rationale                                    |
| --------------- | ------------------------------ | -------------------------------------------- |
| Architecture    | Node + Signals                 | Best fit for Godot, practical                |
| AI Complexity   | Moderate (state machine)       | Balanced difficulty without over-engineering |
| Storage         | Local only (ConfigFile)        | Simpler, no server needed                    |
| Audio           | AudioStreamPlayer nodes        | Simple, sufficient for needs                 |
| Scene Structure | Modular (separate scenes)      | Clean separation of concerns                 |
| Battle System   | Turn-based with speed priority | Classic command battle style                 |

---

## Detailed Documentation

- [components.md](components.md) — Component definitions and responsibilities
- [component-methods.md](component-methods.md) — Method signatures
- [services.md](services.md) — Service orchestration patterns
- [component-dependency.md](component-dependency.md) — Dependency matrix and
  data flow
