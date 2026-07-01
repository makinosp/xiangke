# Logical Components — Unit 2: Game Foundation

## Overview

Logical component design for the game foundation layer, including state machine
architecture, save management, audio system, and scene transition components.

---

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Game Application                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐   │
│  │   Title Screen    │    │ Character Select  │    │   Battle Scene    │   │
│  │   (Unit 2)        │    │   (Unit 2)        │    │   (Unit 3)        │   │
│  └─────────┬─────────┘    └─────────┬─────────┘    └─────────┬─────────┘   │
│            │                        │                        │               │
│            ▼                        ▼                        ▼               │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                    GameManager (Autoload)                         │ │
│  │  ┌─────────────────────────────────────────────────────────────┐   │ │
│  │  │ State Machine                                               │   │ │
│  │  │ - current_state: GameState                                  │   │ │
│  │  │ - transition_to_state(target: GameState)                    │   │ │
│  │  │ - _is_valid_transition(from, to) -> bool                    │   │ │
│  │  └─────────────────────────────────────────────────────────────┘   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐   │ │
│  │  │ CorpsRoster                                               │   │ │
│  │  │ - corps_characters: Array[String] (6 chars)                 │   │ │
│  │  │ - battle_characters: Array[String] (3 chars)                │   │ │
│  │  │ - set_corps_selection(chars: Array)                         │   │ │
│  │  │ - set_battle_selection(chars: Array)                      │   │ │
│  │  └─────────────────────────────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│            ▲                        ▲                        ▲               │
│            │                        │                        │               │
│  ┌─────────┴─────────┐ ┌──────────┴──────────┐ ┌──────────┴──────────┐   │
│  │   SaveManager       │ │   AudioManager        │ │   SceneTransition     │   │
│  │   (Autoload)        │ │   (Autoload)          │ │   (Node)              │   │
│  │                     │ │                       │ │                       │   │
│  │ - load_save()       │ │ - play_bgm(track)     │ │ - transition_to()     │   │
│  │ - save_game(data)   │ │ - play_sfx(sound)     │ │ - configure()         │   │
│  │ - _calculate_checksum()│ │ - set_volume(bus, vol)│ │ - _on_finished()      │   │
│  └─────────────────────┘ └───────────────────────┘ └───────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                   DataRegistry (Autoload)                           │ │
│  │  (Provided by Unit 1: Resources)                                    │ │
│  │  - characters: Dictionary                                           │ │
│  │  - moves: Dictionary                                                │ │
│  │  - get_character(id) -> CharacterData                               │ │
│  │  - get_move(id) -> MoveData                                         │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## LC-1: GameManager State Machine Component

**Design**: Central state machine managing the game lifecycle with strict
transition validation.

### GameManager (Autoload)

```gdscript
# game_manager.gd
class_name GameManager
extends Node

enum GameState {
    TITLE,
    CHARACTER_SELECT,
    BATTLE,
    RESULT
}

signal game_state_changed(new_state: GameState)
signal transition_requested(from_state: GameState, to_state: GameState)

var current_state: GameState = GameState.TITLE
var corps_roster: CorpsRoster

func transition_to_state(target_state: GameState) -> bool:
    """Transition to a new game state with validation."""
    if not _is_valid_transition(current_state, target_state):
        if OS.is_debug_build():
            push_error("Invalid state transition: %s → %s" % [
                current_state, target_state
            ])
        return false
    
    current_state = target_state
    emit_signal("game_state_changed", target_state)
    return true

func _is_valid_transition(from: GameState, to: GameState) -> bool:
    """Validate state transition is allowed."""
    match from:
        GameState.TITLE:
            return to == GameState.CHARACTER_SELECT
        GameState.CHARACTER_SELECT:
            return to == GameState.BATTLE
        GameState.BATTLE:
            return to == GameState.RESULT
        GameState.RESULT:
            return to == GameState.TITLE
    return false
```

**Rationale**: Implements RE-2.1 and RE-2.2 requirements with different behavior
for debug/release builds.

---

## LC-2: SaveManager Component

**Design**: Handles save file persistence with checksum validation and graceful
recovery.

### SaveManager (Autoload)

```gdscript
# save_manager.gd
class_name SaveManager
extends Node

const SAVE_PATH: String = "user://save.cfg"
const SAVE_VERSION: int = 1

func load_save() -> SaveData:
    """Load save data with checksum validation."""
    var config = ConfigFile.new()
    var err = config.load(SAVE_PATH)
    
    if err != OK:
        return _create_default_save()
    
    var stored_checksum = config.get_value("meta", "checksum", "")
    var calculated_checksum = _calculate_checksum(config)
    
    if stored_checksum != calculated_checksum:
        push_warning("Save file corrupted or tampered")
        return _create_default_save()
    
    return _parse_save_data(config)

func save_game(data: SaveData) -> void:
    """Save game data with checksum."""
    var config = ConfigFile.new()
    # ... populate config ...
    config.set_value("meta", "checksum", _calculate_checksum(config))
    config.save(SAVE_PATH)
```

**Rationale**: Implements SE-1.1 (checksum validation) and RE-1.1 (reset with
warning).

---

## LC-3: AudioManager Component

**Design**: Centralized audio playback with bus separation and Web Audio API
initialization.

### AudioManager (Autoload)

```gdscript
# audio_manager.gd
class_name AudioManager
extends Node

# Audio Track Registry
const AUDIO_REGISTRY: Dictionary = {
    "bgm_main": {"path": "res://audio/bgm/main_theme.ogg", "bus": "bgm"},
    "bgm_battle": {"path": "res://audio/bgm/battle_theme.ogg", "bus": "bgm"},
    "sfx_click": {"path": "res://audio/sfx/click.ogg", "bus": "sfx"},
    "sfx_hover": {"path": "res://audio/sfx/hover.ogg", "bus": "sfx"},
}

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var audio_initialized: bool = false

func initialize_audio() -> void:
    """Initialize audio system (required for Web autoplay policy)."""
    if audio_initialized:
        return
    
    # Play silent sound to unlock Web Audio API
    var silent = AudioStreamGenerator.new()
    bgm_player.stream = silent
    bgm_player.play()
    bgm_player.stop()
    
    audio_initialized = true

func play_bgm(track_name: String) -> void:
    """Play background music with crossfade support."""
    if not audio_initialized:
        return
    
    var track = AUDIO_REGISTRY.get(track_name)
    if track:
        bgm_player.stream = load(track.path)
        bgm_player.play()
```

**Rationale**: Implements PF-2.1 (low latency), US-1.1 (Web audio
initialization), and MA-2.1 (inline documentation).

---

## LC-4: SceneTransition Component

**Design**: Custom scene transition with configurable animation and exported
variables.

### SceneTransition (Node)

```gdscript
# scene_transition.gd
class_name SceneTransition
extends Node

@export var transition_duration: float = 0.5
@export var fade_color: Color = Color(0, 0, 0, 1)
@export var animation_player: AnimationPlayer

func transition_to(scene_path: String, config: TransitionConfig = null) -> void:
    """Execute scene transition with animation."""
    if config:
        transition_duration = config.duration
        fade_color = config.fade_color
    
    # Play fade-out animation
    animation_player.play("fade_out")
    await get_tree().create_timer(transition_duration / 2).timeout
    
    # Change scene
    get_tree().change_scene_to_file(scene_path)
    
    # Play fade-in animation
    animation_player.play("fade_in")
```

**Rationale**: Implements PF-1.1 (500ms transitions) and MA-1.1 (configurable
via exported variables).

---

## LC-5: UIFocusManager Component

**Design**: Custom focus management for keyboard navigation with visual
feedback.

### UIFocusManager (Autoload)

```gdscript
# ui_focus_manager.gd
class_name UIFocusManager
extends Node

var focus_group: Array[Control] = []
var focused_index: int = 0

func focus_next() -> void:
    """Move focus to next control in group."""
    focused_index = (focused_index + 1) % focus_group.size()
    _update_focus_visual(focus_group[focused_index])

func _update_focus_visual(control: Control) -> void:
    """Apply visual highlighting to focused control."""
    for c in focus_group:
        c.modulate = Color(1, 1, 1)
    control.modulate = Color(1.2, 1.2, 1)  # Highlight
```

**Rationale**: Implements US-2.1 and US-2.2 (custom focus management with visual
highlighting).

---

## Component Interaction Flow

```
Game Start
    ↓
StartScreen (Click to Start)
    ↓
AudioManager.initialize_audio()
    ↓
SaveManager.load_save()
    ↓
GameManager.transition_to_state(TITLE)
    ↓
SceneTransition.transition_to(title_screen.tscn)
    ↓
Title Screen → Character Select
    ↓
UIFocusManager handles keyboard navigation
    ↓
CorpsRoster manages 6→3 character selection
    ↓
GameManager.transition_to_state(BATTLE)
    ↓
SceneTransition.transition_to(battle.tscn)
```
