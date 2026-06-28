# Unit of Work Dependency

## Dependency Matrix

| Unit                        | Depends On             | Depended By                    |
| --------------------------- | ---------------------- | ------------------------------ |
| **Unit 1: Resources**       | —                      | Unit 2, Unit 3, Unit 4, Unit 5 |
| **Unit 2: Game Foundation** | Unit 1                 | Unit 3, Unit 5, Unit 6         |
| **Unit 3: Battle System**   | Unit 1, Unit 2         | Unit 4, Unit 5                 |
| **Unit 4: AI System**       | Unit 1, Unit 3         | —                              |
| **Unit 5: UI System**       | Unit 1, Unit 2, Unit 3 | —                              |
| **Unit 6: Audio System**    | Unit 2                 | —                              |

## Dependency Graph

```
               ┌─────────────────┐
               │  Unit 1:        │
               │  Resources      │
               │  (Shared Data)  │
               └────────┬────────┘
                        │
         ┌──────────────┼──────────────┐
         │              │              │
         ▼              ▼              ▼
┌────────────┐  ┌────────────┐  ┌────────────┐
│ Unit 2:    │  │ Unit 3:    │  │ Unit 5:    │
│ Game       │  │ Battle     │  │ UI System  │
│ Foundation │──│ System     │──│            │
└─────┬──────┘  └─────┬──────┘  └────────────┘
      │               │
      │               ▼
      │        ┌────────────┐
      │        │ Unit 4:    │
      │        │ AI System  │
      │        └────────────┘
      │
      ▼
┌────────────┐
│ Unit 6:    │
│ Audio      │
│ System     │
└────────────┘
```

## Communication Interfaces

### Unit 1 → All Units (Data Access)

```gdscript
# Resources are accessed as Godot Resources
var char_data = preload("res://resources/characters/player_01.tres")
var move_data = preload("res://resources/moves/fire_blast.tres")
var effectiveness = TypeChart.get_effectiveness(FIRE, GRASS)
```

### Unit 2 → Unit 3 (Battle Lifecycle)

```gdscript
# GameManager signals
signal scene_change_requested(scene_name)
signal game_state_changed(new_state)

# BattleManager calls
GameManager.set_game_state(GameState.BATTLE)
GameManager.change_scene("result_screen")
```

### Unit 3 → Unit 4 (AI Decision Request)

```gdscript
# BattleManager requests AI decision
var ai_action = AIController.decide_action(enemy, player)
BattleManager.execute_action(ai_action)
```

### Unit 3 → Unit 5 (UI Updates)

```gdscript
# BattleManager signals
signal turn_started(character)
signal action_executed(action, result)
signal battle_ended(winner)

# UIController connects to signals
BattleManager.action_executed.connect(_on_action_executed)
```

### Unit 2 → Unit 6 (Audio Playback)

```gdscript
# AudioController autoload methods
AudioController.play_bgm("battle_theme")
AudioController.play_sfx("attack_hit")
```

## Parallel Development Opportunities

| Phase   | Parallel Units           | Reason                            |
| ------- | ------------------------ | --------------------------------- |
| Phase 1 | Unit 1 only              | Base dependency                   |
| Phase 2 | Unit 2 only              | Depends on Unit 1                 |
| Phase 3 | Unit 3 only              | Core system, others depend on it  |
| Phase 4 | Unit 4 + Unit 5 + Unit 6 | Independent after Unit 3 complete |

## Critical Path

```
Unit 1 (Resources) → Unit 2 (Foundation) → Unit 3 (Battle) → Unit 4 (AI)
                                              ↓
                                           Unit 5 (UI)
```

Unit 6 (Audio) can be developed in parallel with Unit 4 and Unit 5.
