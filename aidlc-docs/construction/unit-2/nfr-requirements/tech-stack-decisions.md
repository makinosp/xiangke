# Tech Stack Decisions — Unit 2: Game Foundation

## Overview

Technology choices for the game foundation layer, based on project requirements
and NFR assessment.

---

## Scene Management

| Decision               | Choice                                     | Rationale                                                             |
| ---------------------- | ------------------------------------------ | --------------------------------------------------------------------- |
| **State Machine**      | Minimal finite state machine (FSM)         | Q1=A — Simple 4-state loop: Title → CharacterSelect → Battle → Result |
| **Scene Organization** | Modular scenes with dedicated root nodes   | Q2=A — Each scene is a separate .tscn file with clear boundaries      |
| **Transition System**  | Custom transition node with fade/animation | Q2=C — SceneTransition node with configurable animation player        |

### State Machine Implementation

```
Title Screen (GameState.TITLE)
    ↓ (Start button)
Character Select (GameState.CHARACTER_SELECT)
    ↓ (6 chars selected → 3 chars selected)
Battle Scene (GameState.BATTLE)
    ↓ (Battle ends)
Result Screen (GameState.RESULT)
    ↓ (Return to title)
Title Screen (loop back)
```

---

## Save System

| Decision           | Choice                                | Rationale                                               |
| ------------------ | ------------------------------------- | ------------------------------------------------------- |
| **Storage Method** | Godot ConfigFile API                  | Q3=A — Single save.cfg file with sections               |
| **Save Location**  | user://save.cfg (sandboxed user data) | Q4=A — Single file with settings/progress/meta sections |
| **Data Format**    | Key-value pairs in INI-style format   | Native Godot format; human-readable; easy to debug      |

### Save File Structure

```ini
[settings]
master_volume=1.0
bgm_volume=1.0
sfx_volume=1.0
master_muted=false

[progress]
selected_character=guan_yu
last_battle_won=true
last_battle_time=2026-06-30T12:00:00Z

[meta]
save_version=1
```

---

## Audio System

| Decision              | Choice                                    | Rationale                                                         |
| --------------------- | ----------------------------------------- | ----------------------------------------------------------------- |
| **Audio Players**     | AudioStreamPlayer nodes                   | Q5=A — Full audio system with BGM/SFX, volume controls, crossfade |
| **Bus Configuration** | Master → BGM / SFX buses                  | Separate volume control for music and sound effects               |
| **Crossfade**         | Manual fade via tween or animation        | Smooth transitions between BGM tracks                             |
| **Dynamic Layers**    | Multiple AudioStreamPlayer nodes          | Layered audio for battle intensity changes                        |
| **Web Audio**         | Click-to-start screen for autoplay unlock | Q1=A — Required for Web browser audio policy compliance           |

### Audio Bus Hierarchy

```
Master (Volume Control)
├── BGM Bus (Music)
│   ├── Track 1 (Main theme)
│   └── Track 2 (Battle theme)
└── SFX Bus (Sound Effects)
    ├── UI Sounds
    ├── Battle Sounds
    └── Status Effect Sounds
```

---

## UI System

| Decision             | Choice                                     | Rationale                                                         |
| -------------------- | ------------------------------------------ | ----------------------------------------------------------------- |
| **Theme System**     | Godot built-in theme with custom overrides | T2=B — Use built-in theme with custom styling                     |
| **Focus Management** | Custom focus with visual highlighting      | U2=B — Custom focus management for better UX                      |
| **Input Handling**   | Godot default UI input actions             | Q10=A — Standard UI input map (ui_accept, ui_cancel, ui_up, etc.) |

---

## Project Configuration

| Decision             | Choice                                  | Rationale                              |
| -------------------- | --------------------------------------- | -------------------------------------- |
| **Display Settings** | Window size 1280×720 (16:9 base)        | Q9=A — Minimal project settings        |
| **Stretch Mode**     | 2d                                      | Standard 2D game scaling               |
| **Aspect Handling**  | Keep aspect ratio with black bars       | COM1=B — Responsive layout support     |
| **Autoloads**        | GameManager, DataRegistry, AudioManager | Core systems accessible from any scene |

---

## Character Selection

| Decision            | Choice                        | Rationale                                                        |
| ------------------- | ----------------------------- | ---------------------------------------------------------------- |
| **Selection Flow**  | Two-phase selection           | Q7=D — Phase 1: Select 6 for corps, Phase 2: Select 3 for battle |
| **Preview Display** | Stats preview on hover/select | Character stats shown during selection process                   |
| **Opponent Reveal** | After Phase 1 completion      | Opponent's 6-character corps revealed between phases             |

---

## File Organization

```
scenes/
├── title_screen.tscn
├── character_select.tscn
├── battle.tscn
└── result_screen.tscn

scripts/
├── game_manager.gd          # Main state machine
├── scene_transition.gd      # Transition effects
├── save_manager.gd          # Save/load operations
├── audio_manager.gd           # Audio playback control
└── ui_focus_manager.gd      # Custom focus handling

autoloads/
├── game_manager.gd          # Registered as autoload
├── save_manager.gd          # Registered as autoload
└── audio_manager.gd         # Registered as autoload
```
