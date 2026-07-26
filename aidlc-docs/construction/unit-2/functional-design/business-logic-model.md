# Business Logic Model — Unit 2: Game Foundation

## Overview

Business logic models for the game foundation layer. These define how the
GameManager state machine transitions, how scenes are loaded with animated
transitions, how data is persisted locally, and how audio is managed with
dynamic layers and crossfading.

---

## Logic Model: Game State Transition

### Purpose

Manage transitions between the five game states in the state machine
loop.

### Input

- `current_state`: GameState enum value
- `requested_state`: GameState enum value

### Process

```
1. Validate transition: is_transition_valid(current_state, requested_state)
   - TITLE → CORPS_CREATION: valid
   - CORPS_CREATION → CHARACTER_SELECT: valid (requires CorpsRoster.corps = 6)
   - CHARACTER_SELECT → BATTLE: valid (requires CorpsRoster complete)
   - BATTLE → RESULT: valid (requires battle ended)
   - RESULT → TITLE: valid
   - All other transitions: INVALID → log error, abort
2. If invalid → push_error("Invalid state transition"), return
3. Set GameManager.current_state = requested_state
4. Emit signal: game_state_changed(requested_state)
5. Determine target scene for requested_state:
   - TITLE → scenes/title_screen.tscn
   - CORPS_CREATION → scenes/corps_creation.tscn
   - CHARACTER_SELECT → scenes/character_select.tscn
   - BATTLE → scenes/battle_scene.tscn (loaded by BattleManager, Unit 3)
   - RESULT → scenes/result_screen.tscn
6. Trigger SceneTransitionService.change_scene(target_scene, config)
```

### Output

- `success`: Boolean (whether transition was valid and initiated)
- `new_state`: GameState (the active state after transition)

### Rules

- State transitions are synchronous in logic but asynchronous in visual
  execution (the transition animation plays before the scene swap completes).
- The GameManager MUST NOT allow re-entry into the same state (no-op).
- Transition to CHARACTER_SELECT requires `corps_characters` (6) on
  CorpsRoster.
- Transition to BATTLE requires both `corps_characters` (6) and
  `battle_characters` (3) to be set on CorpsRoster.

---

## Logic Model: Scene Transition with Animation

### Purpose

Execute a custom scene transition using AnimationPlayer and SceneTreeTimer,
providing fade/animation effects between scenes.

### Input

- `target_scene_path`: String (res:// path to the .tscn file)
- `config`: TransitionConfig (duration, fade_color, animation type, wait_time)

### Process

```
1. Show transition overlay (CanvasLayer with ColorRect at top z-index)
2. Play fade-out animation (AnimationPlayer):
   a. Animate ColorRect alpha from 0.0 → 1.0 over config.duration / 2
   b. At alpha = 1.0, hold for config.wait_time
3. During hold:
   a. Call get_tree().change_scene_to_file(target_scene_path)
   b. Wait one frame for the new scene to initialize
4. Play fade-in animation:
   a. Animate ColorRect alpha from 1.0 → 0.0 over config.duration / 2
5. Remove transition overlay
6. Emit signal: transition_complete(target_scene_path)
```

### Output

- `success`: Boolean
- `loaded_scene`: Node (root node of the newly loaded scene)

### Rules

- The transition overlay MUST be a CanvasLayer with a high `layer` value to
  render above all scene content.
- Scene loading is synchronous (`change_scene_to_file`) but wrapped in the
  animation timeline so the player perceives a smooth fade.
- If the target scene path is invalid or loading fails, the transition MUST log
  an error and remain on the current scene.
- Only one transition can be active at a time. Concurrent transition requests
  are rejected.

---

## Logic Model: SceneTransitionService

### Purpose

Provide a centralized service for executing scene transitions with configurable
animation effects.

### Interface

```gdscript
# SceneTransitionService (autoload singleton)
func change_scene(target_scene_path: String, config: TransitionConfig) -> void
func is_transition_active() -> bool
func cancel_transition() -> void
```

### Parameters

- `target_scene_path`: String (res:// path to the .tscn file)
- `config`: TransitionConfig
  - `duration`: float (animation duration in seconds, > 0.0)
  - `fade_color`: Color (default: black)
  - `wait_time`: float (hold time between fade-out and fade-in)

### Behavior

- Wraps the scene transition logic defined in Logic Model: Scene Transition with
  Animation.
- Maintains an internal flag to prevent concurrent transitions.
- Emits `transition_started` and `transition_complete` signals for external
  listeners.

---

## Logic Model: Two-Screen Character Selection

### Purpose

Manage the two-screen character selection flow: corps creation (6 characters)
on the CorpsCreation screen, followed by battle selection (3 characters) on the
CharacterSelect screen, with opponent reveal between screens.

### Input

- `screen`: `CORPS_CREATION` or `CHARACTER_SELECT`
- `available_characters`: Dictionary of CharacterData (from DataRegistry)
- `player_selection`: Array[String] (selected character IDs)

### Process

```
SCREEN 1 — CORPS_CREATION (CorpsCreation scene):
1. Display all available characters in a grid
2. Player selects characters one at a time (max 6)
3. Each selection toggles selected/unselected state
4. When 6 characters are selected → enable "Confirm" button
5. On confirm:
   a. Store corps_characters (6 IDs) in CorpsRoster
   b. Generate opponent_corps (6 random/curated IDs)
   c. Persist corps_characters to SaveManager
   d. Trigger state transition: CORPS_CREATION → CHARACTER_SELECT

SCREEN 2 — CHARACTER_SELECT (CharacterSelect scene):
1. Display player's 6 corps characters
2. Display opponent's 6 corps characters (read-only)
3. Player selects 3 out of their 6 characters
4. Selection order is tracked (determines deployment order)
5. When 3 characters are selected → enable "Deploy" button
6. On deploy:
   a. Store battle_characters (3 IDs) in CorpsRoster
   b. Trigger state transition: CHARACTER_SELECT → BATTLE
```

### Output

- `corps_roster`: CorpsRoster entity with all fields populated

### Rules

- During corps creation, the player can deselect and reselect characters freely
  until confirmation.
- During battle selection, the player can deselect and reselect from their 6,
  but cannot return to corps creation without restarting.
- The opponent's corps is generated by the system during the transition from
  CorpsCreation to CharacterSelect (AI selection logic in Unit 4).
- Stats preview and character description MUST be visible during both screens.
- If the available character count is less than 6, corps creation cannot
  complete (error condition).
- Saved corps data is restored on game launch to pre-populate the selection.

---

## Logic Model: Save Data Persistence

### Purpose

Save and load game data to/from a single `user://save.cfg` file using Godot's
ConfigFile API.

### Input

- `action`: `SAVE` or `LOAD`
- `data`: SaveData entity (for SAVE action)

### Process

```
SAVE:
1. Create ConfigFile instance
2. For each section in SaveData:
   a. For each key in section:
      config.set_value(section, key, value)
3. Set meta.save_version = CURRENT_SAVE_VERSION (1)
4. config.save(user://save.cfg)
5. If error → push_warning("Save failed"), return false
6. Return true

LOAD:
1. Create ConfigFile instance
2. err = config.load(user://save.cfg)
3. If err != OK:
   a. If file not found → return default SaveData (first launch)
   b. If parse error → push_warning("Corrupted save"), return default SaveData
4. Check meta.save_version:
   a. If missing or mismatched → return default SaveData (version migration
      not supported in v1; reset to defaults)
5. For each section and key:
   a. Read value with fallback default
   b. Populate SaveData entity
6. Return populated SaveData
```

### Output

- `success`: Boolean
- `save_data`: SaveData entity (for LOAD action)

### Rules

- Save data is minimal: selected character, volume settings, last battle result,
  and corps character IDs.
- The save file is stored at `user://save.cfg` (Godot's user data directory,
  sandboxed by the browser on Web).
- Missing keys default to their standard default values (graceful degradation).
- Save version mismatch results in a reset to defaults (no migration logic in
  v1).
- Save operations are synchronous and should complete within one frame.
- `corps_characters` is serialized as a JSON string for storage in ConfigFile
  (which does not natively support arrays).

---

## Logic Model: Audio Playback Management

### Purpose

Manage BGM and SFX playback, including per-scene BGM, crossfading between
tracks, dynamic music layers, and Web autoplay policy compliance.

### Input

- `action`: `PLAY_BGM`, `STOP_BGM`, `PLAY_SFX`, `SET_VOLUME`, `CROSSFADE`
- `track_id`: String (for PLAY_BGM, PLAY_SFX)
- `volume`: Float (for SET_VOLUME)
- `bus`: String ("Master", "BGM", "SFX")

### Process

```
PLAY_BGM:
1. Look up AudioTrack by track_id
2. If already playing the same track → no-op
3. If another BGM is playing → trigger CROSSFADE instead
4. Set AudioStreamPlayer.stream = track.stream
5. Set bus = track.bus
6. Call AudioStreamPlayer.play()
7. If Web platform and AudioContext suspended → resume on next user input

CROSSFADE:
1. Animate current BGM volume → 0.0 over crossfade_duration (default 1.0s)
2. At midpoint, swap stream to new track
3. Animate new BGM volume 0.0 → target_volume over crossfade_duration
4. Stop old player

PLAY_SFX:
1. Look up AudioTrack by track_id
2. Create one-shot AudioStreamPlayer (or use pool)
3. Set stream and bus
4. Play and auto-free on finished signal

SET_VOLUME:
1. Set AudioServer.set_bus_volume_db(bus, linear_to_db(volume))
2. Persist to SaveManager (settings section)
3. If volume == 0.0 → set bus muted

DYNAMIC LAYER:
1. During battle, monitor intensity level (from BattleManager)
2. Adjust active BGM layers:
   - Layer 0: base melody (always on during battle)
   - Layer 1: percussion (intensity >= 1)
   - Layer 2: full ensemble (intensity >= 2)
3. Fade layers in/out based on intensity changes
```

### Output

- `success`: Boolean
- `playing_track`: String (currently active BGM track ID)

### Rules

- BGM tracks loop continuously until replaced or stopped.
- SFX are one-shot: play once, auto-free on completion.
- Crossfade duration is configurable (default 1.0 second).
- Volume settings persist to SaveManager immediately on change.
- On Web platform, audio context starts suspended; AudioController MUST resume
  on the first user input gesture (click, keypress).
- Dynamic music layers are only active during BATTLE state.
- Audio bus layout: Master → BGM, SFX (configured in project.godot or
  default_bus_layout.tres).

---

## Logic Model: Audio Bus Configuration

### Purpose

Configure the audio bus hierarchy for master/BGM/SFX volume control and muting.

### Process

```
1. Define bus hierarchy:
   Master (index 0)
   ├── BGM (index 1)
   └── SFX (index 2)
2. On AudioController._ready():
   a. Load volume settings from SaveManager
   b. Apply volumes: set_bus_volume_db() for each bus
   c. Apply mute state: set_bus_mute(Master, master_muted)
3. On volume change:
   a. AudioServer.set_bus_volume_db(bus, linear_to_db(volume))
   b. SaveManager.save_setting("settings", key, volume)
```

### Rules

- The Master bus controls overall output; BGM and SFX are children.
- Muting Master mutes all audio.
- Individual BGM/SFX volumes are relative to Master.
- Bus layout is created at runtime if not present (ensures default buses exist).
