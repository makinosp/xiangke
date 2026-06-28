# Unit of Work

## Overview

Decomposition of the turn-based command battle game into units of work for
development.

---

## Units

### Unit 1: Resources (Shared Data)

**Purpose**: Define all shared game data used across systems.

**Responsibilities**:

- Character definitions (name, stats, type, move list)
- Move data (name, power, type, accuracy, effects)
- Type effectiveness charts (fire > grass, water > fire, etc.)
- Status effect definitions (poison, sleep, paralysis, etc.)

**Artifacts**:

- `resources/characters/` — Character resource files (.tres)
- `resources/moves/` — Move resource files (.tres)
- `resources/type_chart.gd` — Type effectiveness lookup table
- `resources/status_effects.gd` — Status effect definitions

**Dependencies**: None (base unit)

---

### Unit 2: Game Foundation

**Purpose**: Core infrastructure and application lifecycle management.

**Responsibilities**:

- GameManager autoload (state machine, scene transitions)
- SaveManager autoload (local persistence via ConfigFile)
- AudioController autoload (BGM/SFX playback)
- Scene transition logic
- Project settings configuration

**Artifacts**:

- `autoloads/game_manager.gd`
- `autoloads/save_manager.gd`
- `autoloads/audio_controller.gd`
- `scenes/title_screen.tscn`
- `scenes/character_select.tscn`
- `scenes/result_screen.tscn`

**Dependencies**: Resources (Unit 1)

---

### Unit 3: Battle System

**Purpose**: Core battle logic and turn management.

**Responsibilities**:

- Turn flow management (player → enemy → resolve)
- Action selection and execution
- Damage calculation with type effectiveness
- Win/loss condition checking
- Battle scene and node setup

**Artifacts**:

- `systems/battle/battle_manager.gd`
- `systems/battle/action_system.gd`
- `systems/battle/battle_flow_service.gd`
- `scenes/battle_scene.tscn`

**Dependencies**: Resources (Unit 1), Game Foundation (Unit 2)

---

### Unit 4: AI System

**Purpose**: Enemy NPC decision-making for battle actions.

**Responsibilities**:

- Evaluate battle state (HP, type advantage, status)
- Select moves based on moderate difficulty logic
- Consider recovery when HP is low
- Avoid purely random or purely optimal play

**Artifacts**:

- `systems/ai/ai_controller.gd`
- `systems/ai/ai_state_machine.gd`

**Dependencies**: Resources (Unit 1), Battle System (Unit 3)

---

### Unit 5: UI System

**Purpose**: All user interface elements and HUD.

**Responsibilities**:

- HP bars and status indicators
- Action menu during player turn
- Battle log messages
- Menu navigation (title, character select, result)
- Responsive layout for Web viewport

**Artifacts**:

- `systems/ui/ui_controller.gd`
- `systems/ui/hud.tscn`
- `systems/ui/action_menu.tscn`
- `systems/ui/battle_log.tscn`

**Dependencies**: Resources (Unit 1), Game Foundation (Unit 2), Battle System
(Unit 3)

---

### Unit 6: Audio System

**Purpose**: Background music and sound effects management.

**Responsibilities**:

- BGM playback per scene (title, battle, result)
- SFX for actions (attack, hit, victory, defeat)
- Web platform autoplay policy compliance
- Volume settings persistence

**Artifacts**:

- `systems/audio/audio_service.gd`
- `assets/audio/bgm/` — Background music files
- `assets/audio/sfx/` — Sound effect files

**Dependencies**: Game Foundation (Unit 2)

---

## Development Sequence

| Order | Unit                     | Rationale                            |
| ----- | ------------------------ | ------------------------------------ |
| 1     | Resources (Unit 1)       | Base data, no dependencies           |
| 2     | Game Foundation (Unit 2) | Core infrastructure                  |
| 3     | Battle System (Unit 3)   | Core gameplay, highest priority      |
| 4     | AI System (Unit 4)       | Depends on Battle System             |
| 5     | UI System (Unit 5)       | Depends on Battle System             |
| 6     | Audio System (Unit 6)    | Can be developed in parallel with UI |

---

## Code Organization Strategy

```
xiangke/
├── project.godot              # Godot project file
├── autoloads/
│   ├── game_manager.gd
│   ├── save_manager.gd
│   └── audio_controller.gd
├── resources/
│   ├── characters/
│   │   ├── character_base.gd
│   │   └── *.tres
│   ├── moves/
│   │   ├── move_base.gd
│   │   └── *.tres
│   ├── type_chart.gd
│   └── status_effects.gd
├── systems/
│   ├── battle/
│   │   ├── battle_manager.gd
│   │   ├── action_system.gd
│   │   └── battle_flow_service.gd
│   ├── ai/
│   │   ├── ai_controller.gd
│   │   └── ai_state_machine.gd
│   ├── ui/
│   │   ├── ui_controller.gd
│   │   ├── hud.tscn
│   │   ├── action_menu.tscn
│   │   └── battle_log.tscn
│   └── audio/
│       └── audio_service.gd
├── scenes/
│   ├── title_screen.tscn
│   ├── character_select.tscn
│   ├── battle_scene.tscn
│   └── result_screen.tscn
└── assets/
    ├── audio/
    │   ├── bgm/
    │   └── sfx/
    ├── sprites/
    └── fonts/
```
