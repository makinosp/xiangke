# Foundation Layer Code Summary — Unit 2: Game Foundation

## Overview

This document summarizes the generated code for the game foundation layer (Unit
2). This layer provides core application lifecycle management, scene
transitions, persistence, audio, and UI navigation.

---

## Generated Files

### Autoloads

| File                            | Type               | Description                                                                 |
| ------------------------------- | ------------------ | --------------------------------------------------------------------------- |
| `autoloads/game_manager.gd`     | Autoload singleton | Central state machine: `TITLE → CHARACTER_SELECT → BATTLE → RESULT → TITLE` |
| `autoloads/save_manager.gd`     | Autoload singleton | Local persistence using `ConfigFile` with MD5 checksum validation           |
| `autoloads/audio_manager.gd`    | Autoload singleton | Audio playback, bus management, Web Audio API autoplay handling, crossfade  |
| `autoloads/ui_focus_manager.gd` | Autoload singleton | Custom keyboard navigation with visual focus highlighting                   |

### Foundation Scripts

| File                                             | Type                          | Description                                                             |
| ------------------------------------------------ | ----------------------------- | ----------------------------------------------------------------------- |
| `scripts/foundation/scene_transition.gd`         | Node (`SceneTransition`)      | Animated scene transitions with CanvasLayer overlay and fade effects    |
| `scripts/foundation/transition_config.gd`        | Resource (`TransitionConfig`) | Configuration for transition duration, color, and animation type        |
| `scripts/foundation/corps_roster.gd`             | RefCounted (`CorpsRoster`)    | Two-phase character selection: corps (6) and battle party (3)           |
| `scripts/foundation/title_screen.gd`             | Control script                | Title screen with Start button, version label, and audio initialization |
| `scripts/foundation/character_select.gd`         | Control script                | Two-phase character selection UI with stats preview                     |
| `scripts/foundation/result_screen.gd`            | Control script                | Battle result display (Win/Loss) and return to title                    |
| `scripts/foundation/battle_scene_placeholder.gd` | Control script                | Placeholder for Unit 3 (Battle System); simulates battle completion     |

### Scenes

| File                                 | Description                                                                           |
| ------------------------------------ | ------------------------------------------------------------------------------------- |
| `scenes/title_screen.tscn`           | Title screen with centered title, Start button, version label                         |
| `scenes/character_select.tscn`       | Character selection with grid, phase indicator, stats preview, confirm/deploy buttons |
| `scenes/result_screen.tscn`          | Result screen with Win/Loss display and "Return to Title" button                      |
| `scenes/battle_scene.tscn`           | Placeholder battle scene for game loop testing                                        |
| `scenes/scene_transition_layer.tscn` | Transition overlay with ColorRect for fade effects                                    |

---

## Architecture Overview

```
Autoloads (always available)
├── DataRegistry (Unit 1)   → Character, Move data lookup
├── GameManager             → State machine + CorpsRoster
├── SaveManager             → ConfigFile persistence + checksum
├── AudioManager            → BGM/SFX playback, Web unlock
└── UIFocusManager          → Keyboard navigation

Scene Flow
├── title_screen.tscn       → Entry point
├── character_select.tscn   → Phase 1 (6 corps) → Phase 2 (3 battle)
├── battle_scene.tscn       → Placeholder (Unit 3)
└── result_screen.tscn      → Win/Loss → return to title
```

---

## Business Rule Coverage

| Rule          | Coverage                 | Implementation                                                          |
| ------------- | ------------------------ | ----------------------------------------------------------------------- |
| GR-1          | State machine validity   | `game_manager.gd` — `_is_valid_transition()`                            |
| GR-2          | Transition preconditions | `game_manager.gd` — `transition_to_state()`                             |
| SR-1          | Transition exclusivity   | `scene_transition.gd` — `_is_transitioning` flag                        |
| SR-2          | Transition animation     | `scene_transition.gd` — `_play_fade_out()` / `_play_fade_in()`          |
| SR-3          | Scene loading error      | `scene_transition.gd` — checks return value of `change_scene_to_file()` |
| CSR-1/2/3     | Character selection flow | `corps_roster.gd` — `set_corps_selection()`, `set_battle_selection()`   |
| SDR-1/2/3/4/5 | Save data handling       | `save_manager.gd` — `load_save()`, `save_game()`, `_parse_save_data()`  |
| AR-1/2/3/4    | Audio system             | `audio_manager.gd` — bus management, crossfade, SFX one-shot            |
| US-1.1        | Web audio autoplay       | `audio_manager.gd` — `initialize_audio()`, `title_screen.gd`            |
| US-2.1        | Focus management         | `ui_focus_manager.gd` — `register_focus_group()`, `_set_focus()`        |

---

## Dependencies

- **Unit 1 (Resources)**: `DataRegistry`, `CharacterData`, `MoveData`
- **Godot 4.x**: `ConfigFile`, `AudioStreamPlayer`, `AnimationPlayer`,
  `CanvasLayer`
- **No external dependencies**
