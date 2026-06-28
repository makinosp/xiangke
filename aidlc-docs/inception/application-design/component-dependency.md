# Component Dependency

## Overview

Dependency matrix and communication patterns between components.

---

## Dependency Matrix

| Component                  | Depends On                                              | Depended By                                             |
| -------------------------- | ------------------------------------------------------- | ------------------------------------------------------- |
| **GameManager**            | SaveManager                                             | BattleManager, UIController, SceneTransitionService     |
| **BattleManager**          | ActionSystem, Character                                 | BattleFlowService, GameManager, UIController            |
| **AIController**           | Character, ActionSystem                                 | BattleFlowService                                       |
| **ActionSystem**           | Character                                               | BattleManager, AIController                             |
| **Character**              | —                                                       | BattleManager, AIController, ActionSystem, UIController |
| **UIController**           | GameManager, BattleManager                              | BattleFlowService                                       |
| **AudioController**        | SaveManager                                             | AudioService, All Scenes                                |
| **SaveManager**            | —                                                       | GameManager, AudioController, PersistenceService        |
| **SceneTransitionService** | GameManager                                             | UIController, BattleFlowService                         |
| **BattleFlowService**      | BattleManager, AIController, ActionSystem, UIController | GameManager, SceneTransitionService                     |
| **AudioService**           | AudioController, SaveManager                            | All Scenes, BattleManager                               |
| **PersistenceService**     | SaveManager                                             | GameManager, UIController                               |

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        AUTLOADS                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ GameManager  │  │AudioController│  │ SaveManager  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │               │
└─────────┼─────────────────┼──────────────────┼───────────────┘
          │                 │                  │
          ▼                 ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                      BATTLE FLOW                             │
│                                                              │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │ BattleFlowService│────────▶│  BattleManager    │          │
│  └────────┬─────────┘         └────────┬─────────┘          │
│           │                            │                     │
│           │                            ▼                     │
│           │         ┌──────────────────┴──────────┐         │
│           │         │                             │         │
│           ▼         ▼                             ▼         │
│  ┌──────────────┐  ┌──────────────┐    ┌──────────────┐    │
│  │ AIController │  │ ActionSystem │    │ UIController │    │
│  └──────┬───────┘  └──────┬───────┘    └──────────────┘    │
│         │                 │                                  │
│         └────────┬────────┘                                  │
│                  ▼                                           │
│         ┌──────────────┐                                    │
│         │  Character   │                                    │
│         └──────────────┘                                    │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                      PERSISTENCE                             │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │PersistenceService│────────▶│  SaveManager     │          │
│  └──────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                       AUDIO                                  │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  AudioService    │────────▶│ AudioController  │          │
│  └──────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

---

## Communication Patterns

### 1. Signal-Based (Decoupled)

- `BattleManager.action_executed` → `UIController.update_hp_bar()`
- `Character.hp_changed` → `UIController.update_hp_bar()`
- `BattleManager.battle_ended` → `GameManager.set_state(RESULT)`
- `GameManager.game_state_changed` → `SceneTransitionService.change_scene()`

### 2. Direct Call (Tightly Coupled)

- `BattleFlowService` → `BattleManager.start_battle()`
- `BattleManager` → `ActionSystem.calculate_damage()`
- `UIController` → `GameManager.get_player_character()`

### 3. Autoload Access (Global)

- Any node → `/root/GameManager`
- Any node → `/root/AudioController`
- Any node → `/root/SaveManager`

---

## Scene-Specific Dependencies

### TitleScene

- Uses: GameManager, AudioController, UIController
- Transitions to: CharacterSelect

### CharacterSelect

- Uses: GameManager, UIController, AudioController
- Transitions to: BattleScene

### BattleScene

- Uses: BattleManager, BattleFlowService, AIController, ActionSystem,
  UIController, AudioController
- Transitions to: ResultScene

### ResultScene

- Uses: GameManager, UIController, AudioController, SaveManager
- Transitions to: TitleScene or CharacterSelect
