# Services

## Overview

Service definitions and orchestration patterns for the turn-based command battle
game.

---

## Service: SceneTransitionService

**Purpose**: Manages smooth transitions between game scenes.

**Responsibilities**:

- Handle scene loading and unloading
- Provide transition animations (fade, slide)
- Pass data between scenes via GameManager

**Interactions**:

- Uses: GameManager (to read current state)
- Called by: UIController (on menu selections), BattleManager (on battle end)

**Orchestration Pattern**:

```
User Action → UIController → GameManager.set_state() → SceneTransitionService.change_scene()
```

---

## Service: BattleFlowService

**Purpose**: Orchestrates the complete battle flow from start to finish.

**Responsibilities**:

- Initialize battle with selected characters
- Manage turn cycle (player → enemy → resolve)
- Coordinate between BattleManager, AIController, and UIController
- Handle battle end and transition to result screen

**Interactions**:

- Uses: BattleManager, AIController, ActionSystem, UIController
- Called by: GameManager (when entering battle state)

**Orchestration Pattern**:

```
GameManager → BattleFlowService.start_battle()
  → BattleManager.start_battle(player, enemy)
  → Loop:
    → UIController.show_action_menu() → player selects action
    → BattleManager.execute_action(player_action)
    → AIController.decide_action() → enemy action
    → BattleManager.execute_action(enemy_action)
    → ActionSystem.resolve()
  → BattleManager.check_battle_end()
  → GameManager.set_state(RESULT)
```

---

## Service: AudioService

**Purpose**: Centralizes audio playback across all scenes.

**Responsibilities**:

- Manage BGM playback per scene context
- Trigger SFX for game events
- Handle Web platform autoplay restrictions (resume on user gesture)
- Persist volume settings via SaveManager

**Interactions**:

- Uses: AudioController (Autoload), SaveManager (for volume settings)
- Called by: All scenes (on enter/exit), BattleManager (on action events)

**Orchestration Pattern**:

```
Scene Enter → AudioService.play_bgm_for_scene(scene_name)
Battle Action → AudioService.play_sfx(action_name)
Settings Change → AudioService.set_volume() → SaveManager.save_settings()
```

---

## Service: PersistenceService

**Purpose**: Handles all local data persistence operations.

**Responsibilities**:

- Save/load game progress
- Manage leaderboard data
- Store game settings
- Handle data migration between game versions

**Interactions**:

- Uses: SaveManager (Autoload)
- Called by: GameManager (on state changes), UIController (on settings changes)

**Orchestration Pattern**:

```
Game State Change → PersistenceService.save_state() → SaveManager.save_game()
Load Game → PersistenceService.load_state() → SaveManager.load_game()
New Score → PersistenceService.submit_score() → SaveManager.save_score()
```

---

## Communication Patterns

### Signal-Based Communication (Primary)

```
BattleManager.action_executed → UIController.update_hp_bar()
Character.hp_changed → UIController.update_hp_bar()
BattleManager.battle_ended → GameManager.set_state(RESULT)
```

### Direct Call Communication

```
GameManager.change_scene() → SceneTransitionService
BattleFlowService.start_battle() → BattleManager, AIController
```

### Autoload Access Pattern

```
Any node: get_node("/root/GameManager").set_state(BATTLE)
Any node: get_node("/root/AudioController").play_sfx("hit")
Any node: get_node("/root/SaveManager").save_game(data)
```
