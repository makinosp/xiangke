# Code Generation Plan — Unit 2: Game Foundation

## Objective

Generate all GDScript code, scene files, and supporting artifacts for the game
foundation layer (Unit 2) of the Three Kingdoms turn-based command battle game.

## Context Summary

- **Project Type**: Greenfield — Godot 4.x 2D game
- **Primary Export**: Web (HTML5/WebAssembly)
- **Foundation Layer**: Core application lifecycle, scene management,
  persistence, and audio.
- **Workspace Root**: `.`
- **Dependencies**: Unit 1 (Resources) — uses `DataRegistry` for character and
  move data.

---

## Unit Context

### Stories Implemented by This Unit

Unit 2 implements the essential "glue" and foundation systems:

- Game state management (Title → Character Select → Battle → Result)
- Scene transition system with animated fades
- Local save system using `ConfigFile` with checksum validation
- Audio system with bus management and Web Audio API autoplay handling
- Two-phase character selection (Corps selection → Battle party selection)
- Basic UI screens (Title, Character Select, Result)

### Expected Interfaces and Contracts

| Interface         | Type               | Purpose                                                             |
| ----------------- | ------------------ | ------------------------------------------------------------------- |
| `GameManager`     | Autoload singleton | State machine and global game flow control                          |
| `SaveManager`     | Autoload singleton | Local persistence (save/load) with integrity checks                 |
| `AudioManager`    | Autoload singleton | Audio playback, bus control, and Web Audio API unlock               |
| `UIFocusManager`  | Autoload singleton | Custom keyboard navigation and visual focus highlighting            |
| `SceneTransition` | Node / Service     | Animated scene transitions (fade-out/in)                            |
| `GameState`       | Enum               | Application states: `TITLE`, `CHARACTER_SELECT`, `BATTLE`, `RESULT` |
| `SaveData`        | Resource/Object    | Container for persisted settings and progress                       |

### File Locations

- `autoloads/{name}.gd` — Global singleton scripts
- `scripts/foundation/{name}.gd` — Scene-specific or utility scripts
- `scenes/{name}.tscn` — Godot scene files
- `resources/` — (Unit 1) Shared data resources

### Key Design Decisions

1. **Minimal State Machine**: Strict unidirectional loop for game flow.
2. **Atomic Save Files**: Single `save.cfg` using `ConfigFile` for simplicity
   and readability.
3. **Web-First Audio**: Explicit "Click to Start" screen to satisfy browser
   autoplay policies.
4. **Two-Phase Selection**: Decoupled corps formation (6) from battle deployment
   (3).
5. **Responsive UI**: Use of Godot anchors and containers for multiple aspect
   ratios.

---

## Plan Steps

### Project Structure Setup

- [ ] **Step 1**: Create project directory structure (`scenes/`,
      `scripts/foundation/`)

### Core Autoloads Implementation

- [ ] **Step 2**: Create `autoloads/game_manager.gd` — State machine with
      transition validation and `GameState` enum.
- [ ] **Step 3**: Create `autoloads/save_manager.gd` — Local persistence using
      `ConfigFile` with checksum validation.
- [ ] **Step 4**: Create `autoloads/audio_manager.gd` — Audio playback, bus
      management, and `initialize_audio()` for Web.
- [ ] **Step 5**: Create `autoloads/ui_focus_manager.gd` — Custom focus tracking
      and visual highlighting for keyboard navigation.

### Scene Transition System

- [ ] **Step 6**: Create `scripts/foundation/scene_transition.gd` — Logic for
      animated fades and scene swapping.
- [ ] **Step 7**: Create `scenes/scene_transition.tscn` — Transition overlay
      with `AnimationPlayer` and `ColorRect`.

### Title Screen Implementation

- [ ] **Step 8**: Create `scenes/title_screen.tscn` — UI layout with "Start"
      button and version label.
- [ ] **Step 9**: Create `scripts/foundation/title_screen.gd` — Logic for
      starting the game and initializing audio.

### Character Selection Screen Implementation

- [ ] **Step 10**: Create `scenes/character_select.tscn` — UI for two-phase
      selection (Corps and Battle party).
- [ ] **Step 11**: Create `scripts/foundation/character_select.gd` — Logic for
      Phase 1 (6 chars), Phase 2 (3 chars), and stats preview.

### Result Screen Implementation

- [ ] **Step 12**: Create `scenes/result_screen.tscn` — UI for Win/Loss display.
- [ ] **Step 13**: Create `scripts/foundation/result_screen.gd` — Logic for
      displaying results and returning to title.

### Godot Project Configuration

- [ ] **Step 14**: Update `project.godot` — Register autoloads, set window size
      (1280x720), and configure input map.

### Code Summaries (Documentation)

- [ ] **Step 15**: Create
      `aidlc-docs/construction/unit-2/code/foundation-summary.md` — Markdown
      summary of generated code.

---

## Story Traceability

| Step       | Story Coverage                                                     |
| ---------- | ------------------------------------------------------------------ |
| Step 1     | Project foundation                                                 |
| Step 2     | Game state machine (GR-1, GR-2)                                    |
| Step 3     | Save data persistence and integrity (SDR-1 through SDR-5)          |
| Step 4     | Audio system and Web autoplay handling (AR-1 through AR-4, US-1.1) |
| Step 5     | Keyboard navigation and focus (US-2.1, US-2.2)                     |
| Step 6-7   | Scene transition effects and error handling (SR-1 through SR-3)    |
| Step 8-9   | Title screen and game entry                                        |
| Step 10-11 | Two-phase character selection (CSR-1 through CSR-4)                |
| Step 12-13 | Battle result display and loop closure                             |
| Step 14    | Godot project integration                                          |
| Step 15    | Documentation                                                      |

---

## Generation Notes

- All code comments and documentation in English (per project convention).
- GDScript follows Godot 4.x conventions (typed signals, `@onready`, `@export`).
- UI uses Godot's built-in theme system with custom overrides.
- Save data uses `user://save.cfg` for sandboxed local storage.
- Scene transitions are handled via a dedicated overlay to ensure visual
  consistency.
