# NFR Design Patterns — Unit 2: Game Foundation

## Overview

Design patterns and structural decisions for incorporating NFR requirements into
the game foundation layer. These patterns address performance, reliability,
maintainability, and logical component organization.

---

## Performance Patterns

### PP-1: Scene Transition Animation with Configurable Timing

**Pattern**: Custom scene transition using AnimationPlayer with exported
configuration variables for duration, fade color, and easing curve.

**Design**:

```
SceneTransition (Node)
├── Exported Variables
│   ├── transition_duration: float = 0.5
│   ├── fade_color: Color = Color(0, 0, 0, 1)
│   ├── easing_curve: Curve
│   └── animation_player: AnimationPlayer
├── Methods
│   ├── transition_to(scene_path: String, config: TransitionConfig)
│   └── _on_transition_finished()
└── Signals
    └── transition_complete(scene_path)
```

**Rationale**: Meets PF-1.1 requirement (500ms transitions) while allowing
designer customization via exported variables (MA-1.1).

---

### PP-2: Audio Bus Architecture for Low-Latency Playback

**Pattern**: Separate AudioStreamPlayer nodes for BGM and SFX buses with
preloaded audio streams to achieve <50ms latency.

**Design**:

```
AudioManager (Autoload)
├── BGM Bus
│   ├── main_theme: AudioStreamPlayer
│   ├── battle_theme: AudioStreamPlayer
│   └── crossfade_timer: Timer
├── SFX Bus
│   ├── ui_sounds: AudioStreamPlayer
│   ├── battle_sounds: AudioStreamPlayer
│   └── status_sounds: AudioStreamPlayer
└── Methods
    ├── play_bgm(track_name: String)
    ├── play_sfx(sound_name: String)
    ├── set_bgm_volume(volume: float)
    ├── set_sfx_volume(volume: float)
    └── initialize_audio() — unlocks Web Audio API
```

**Rationale**: Meets PF-2.1 requirement (<50ms audio latency) and US-1.1 (Web
autoplay handling) through dedicated initialization method.

---

## Reliability Patterns

### RP-1: Save Data Recovery with Warning Notification

**Pattern**: When save file is corrupted or missing, reset to defaults and show
a one-time warning message to the user.

**Design**:

```
SaveManager (Autoload)
├── Methods
│   ├── load_save() -> SaveData
│   │   ├── File exists + valid checksum → return loaded data
│   │   ├── File exists + invalid checksum → log warning, reset to defaults
│   │   └── File missing → return defaults (no warning)
│   ├── save_game(data: SaveData)
│   └── _show_corruption_warning()
└── Properties
    ├── save_path: String = "user://save.cfg"
    └── warning_shown: bool = false
```

**Rationale**: Meets RE-1.1 requirement (reset with warning) while preventing
repeated warnings through the `warning_shown` flag.

---

### RP-2: State Machine Guard Clauses

**Pattern**: Validate state transitions before execution, with different
behavior for development vs release builds.

**Design**:

```
GameManager (Autoload)
├── Methods
│   ├── transition_to_state(target_state: GameState)
│   │   ├── Validate transition is allowed
│   │   ├── If invalid:
│   │   │   ├── Development: push_error + show debug message
│   │   │   └── Release: log warning only
│   │   └── If valid: emit signal + change scene
│   └── _is_valid_transition(from: GameState, to: GameState) -> bool
└── Properties
    ├── current_state: GameState
    └── debug_mode: bool = false
```

**Rationale**: Meets RE-2.1 and RE-2.2 requirements (different handling for
dev/release builds).

---

## Maintainability Patterns

### MP-1: Configurable Transition System

**Pattern**: Scene transition parameters exposed as exported variables on the
transition node for easy modification.

**Design**:

```gdscript
# scene_transition.gd
@export var transition_duration: float = 0.5
@export var fade_color: Color = Color(0, 0, 0, 1)
@export var easing_curve: Curve
@export var animation_player: AnimationPlayer

func configure_transition(config: TransitionConfig) -> void:
    transition_duration = config.duration
    fade_color = config.fade_color
    easing_curve = config.easing_curve
```

**Rationale**: Meets MA-1.1 requirement (configurable via exported variables).

---

### MP-2: Audio Track Registry with Documentation

**Pattern**: Centralized audio track registry with inline documentation for
BGM/SFX file organization.

**Design**:

```gdscript
# audio_manager.gd
# Audio Track Registry
# Format: {track_id: {path: String, bus: String, volume: float}}
const AUDIO_REGISTRY: Dictionary = {
    # BGM Tracks
    "bgm_main": {"path": "res://audio/bgm/main_theme.ogg", "bus": "bgm", "volume": 1.0},
    "bgm_battle": {"path": "res://audio/bgm/battle_theme.ogg", "bus": "bgm", "volume": 1.0},
    # SFX Tracks
    "sfx_ui_click": {"path": "res://audio/sfx/click.ogg", "bus": "sfx", "volume": 0.8},
    "sfx_ui_hover": {"path": "res://audio/sfx/hover.ogg", "bus": "sfx", "volume": 0.6},
}
```

**Rationale**: Meets MA-2.1 and MA-2.2 requirements (inline comments + registry
documentation).

---

### MP-3: Global UI Theme System

**Pattern**: Centralized theme management using a single `.theme` resource
applied at the application root.

**Design**:

- **Global Theme**: A single `main_theme.tres` file defining base styles for all
  UI components.
- **Application**: Applied to the root node of the game to ensure consistent
  styling across all scenes.
- **Overrides**: Specific UI components can use `theme_override` properties for
  unique styling without affecting the global theme.

**Rationale**: Meets TS-2.1 and TS-2.2 requirements for a consistent UI theme
system.

---

## Usability Patterns

### UP-1: Web Audio Unlock Screen

**Pattern**: Initial "Click to Start" screen that initializes audio on first
user interaction to comply with Web Audio API autoplay policy.

**Design**:

```
StartScreen (Scene)
├── UI Elements
│   ├── title_label: Label
│   ├── click_to_start: Button
│   └── version_label: Label
├── Methods
│   ├── _ready() → show screen
│   ├── _on_click_to_start_pressed()
│   │   ├── AudioManager.initialize_audio()
│   │   ├── SaveManager.load_save()
│   │   └── GameManager.transition_to_state(GameState.TITLE)
└── Properties
    ├── audio_initialized: bool = false
```

**Rationale**: Meets US-1.1 requirement (Click to Start screen for Web
autoplay).

---

### UP-2: Custom Focus Management with Visual Feedback

**Pattern**: Custom focus system that highlights focused UI elements for better
keyboard navigation UX.

**Design**:

```
UIFocusManager (Autoload)
├── Methods
│   ├── focus_next()
│   ├── focus_previous()
│   ├── set_focus(control: Control)
│   └── _update_focus_visual(control: Control)
├── Properties
│   ├── focus_group: Array[Control]
│   └── focused_control: Control
└── Signals
    └── focus_changed(control: Control)
```

**Rationale**: Meets US-2.1 and US-2.2 requirements (custom focus management
with visual highlighting).

---

## Compatibility Patterns

### CP-1: Responsive UI Anchoring

**Pattern**: UI elements anchored to screen edges with flexible sizing to
support multiple aspect ratios.

**Design**:

```
UI Component Structure
├── Anchors
│   ├── top: 0.0–1.0 (relative to parent)
│   ├── bottom: 0.0–1.0
│   ├── left: 0.0–1.0
│   └── right: 0.0–1.0
├── Size Flags
│   ├── horizontal: FILL
│   └── vertical: FILL
└── Margin Calculation
    └── Based on anchor percentages
```

**Rationale**: Meets CP-1.1 requirement (responsive layout with flexible UI
anchoring).

---

## Security Patterns

### SP-1: Save File Checksum Validation

**Pattern**: Calculate and verify checksum on save file load to detect
corruption or tampering.

**Design**:

```gdscript
# save_manager.gd
func _calculate_checksum(data: Dictionary) -> String:
    var string_data = JSON.stringify(data)
    return string_data.md5_text()

func load_save() -> SaveData:
    var config = ConfigFile.new()
    var err = config.load(save_path)
    
    if err != OK:
        return _create_default_save()
    
    var stored_checksum = config.get_value("meta", "checksum", "")
    var calculated_checksum = _calculate_checksum(config)
    
    if stored_checksum != calculated_checksum:
        push_warning("Save file checksum mismatch")
        return _create_default_save()
    
    return _parse_save_data(config)
```

**Rationale**: Meets SE-1.1 requirement (basic checksum validation).

---

## Traceability

| Pattern ID | NFR Requirement | Purpose                                      |
| ---------- | --------------- | -------------------------------------------- |
| PP-1       | PF-1.1, MA-1.1  | Scene transitions within 500ms, configurable |
| PP-2       | PF-2.1, US-1.1  | Audio latency <50ms, Web autoplay handling   |
| RP-1       | RE-1.1          | Save corruption recovery with warning        |
| RP-2       | RE-2.1, RE-2.2  | State machine error handling                 |
| MP-1       | MA-1.1          | Configurable transition system               |
| MP-2       | MA-2.1, MA-2.2  | Audio documentation                          |
| MP-3       | TS-2.1, TS-2.2  | Global UI theme system                       |
| UP-1       | US-1.1          | Web audio initialization                     |
| UP-2       | US-2.1, US-2.2  | Custom focus management                      |
| CP-1       | CP-1.1          | Responsive UI layout                         |
| SP-1       | SE-1.1          | Save file integrity checking                 |
