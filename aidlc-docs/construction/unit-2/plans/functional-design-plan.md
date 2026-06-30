# Functional Design Plan — Unit 2: Game Foundation

## Status: COMPLETE ✅

## Unit Context

- **Unit**: Unit 2: Game Foundation
- **Purpose**: Core infrastructure and application lifecycle management.
- **Dependencies**: Resources (Unit 1)
- **Artifacts**:
  - `autoloads/game_manager.gd`
  - `autoloads/save_manager.gd`
  - `autoloads/audio_controller.gd`
  - `scenes/title_screen.tscn`
  - `scenes/character_select.tscn`
  - `scenes/result_screen.tscn`

---

## Design Questions

Please answer the following questions to clarify the functional design for the
Game Foundation unit.

### Question 1: Game State Machine

What game states should the GameManager manage, and what transitions are needed?

A) Minimal: Title → Character Select → Battle → Result → Title (loop)

B) Extended: Title → Character Select → Battle → Result → Title, plus Pause,
Game Over, Settings

C) Full: All of B plus: Battle Preparation (pre-battle buffs), Battle End
(rewards), Continue/Restart options

D) Other (please describe after [Answer]: tag below)

[Answer]: A

### Question 2: Scene Transition Approach

How should scene transitions be handled in Godot?

A) `change_scene_to_file()` — simple, synchronous

B) `change_scene_to_packed()` with preloaded scenes — faster transitions

C) Custom transition system with fade/animation (AnimationPlayer +
SceneTreeTimer)

D) Other (please describe after [Answer]: tag below)

[Answer]: C

### Question 3: Save System Scope

What data should the SaveManager persist locally (ConfigFile)?

A) Minimal: Selected character, volume settings, last completed battle

B) Standard: A + battle statistics (wins/losses), unlocked characters, play time

C) Extended: B + full battle replay data, character progression (XP/levels),
achievement flags

D) Other (please describe after [Answer]: tag below)

[Answer]: A

### Question 4: Save File Structure

How should save data be organized?

A) Single `save.cfg` file with all data in sections

B) Multiple files: `settings.cfg`, `progress.cfg`, `stats.cfg`

C) JSON-based save files for readability and potential external tools

D) Other (please describe after [Answer]: tag below)

[Answer]: A

### Question 5: Audio Controller Responsibilities

What should the AudioController autoload manage?

A) Basic: BGM playback per scene, SFX playback on demand

B) Standard: A + volume controls (master/BGM/SFX), mute toggle, crossfade
between BGM tracks

C) Full: B + audio bus configuration, dynamic music layers (battle intensity),
Web autoplay policy handling

D) Other (please describe after [Answer]: tag below)

[Answer]: C

### Question 6: Title Screen Features

What should the title screen include?

A) Minimal: Game title, "Start" button, version number

B) Standard: A + "Continue" (if save exists), "Settings", "Credits"

C) Full: B + animated background, "Gallery/Records", "Options" submenu (audio,
display, controls)

D) Other (please describe after [Answer]: tag below)

[Answer]: A

### Question 7: Character Select Screen

What should the character select screen support?

A) Minimal: Display 3 characters, select one, confirm

B) Standard: A + show stats preview, character description, keyboard/gamepad
navigation

C) Full: B + multiple character slots (party of 3), character unlock indicators,
random select

D) Other (please describe after [Answer]: tag below)

[Answer]: D — Two-phase selection: Phase 1: Select 6 characters to form a
corps/legion. Phase 2 (after seeing opponent's 6 characters): Select 3 out of
the 6 to actually participate in battle. Must show stats preview, character
description for all 6 during both phases.

### Question 8: Result Screen

What should the battle result screen display?

A) Minimal: Win/Loss, "Return to Title" button

B) Standard: A + battle statistics (turns, damage dealt/taken), experience
gained (if progression), rewards

C) Full: B + detailed breakdown, "Rematch" option, "Continue" to next battle (if
campaign), replay save

D) Other (please describe after [Answer]: tag below)

[Answer]: A

### Question 9: Project Settings Configuration

What project.godot settings should be configured?

A) Minimal: Display/window settings, input map, autoload registration

B) Standard: A + rendering settings (2D, canvas), physics settings, export
templates

C) Full: B + i18n settings, feature tags, custom build configurations, plugin
settings

D) Other (please describe after [Answer]: tag below)

[Answer]: A

### Question 10: Input Map

What input actions should be defined in the Input Map?

A) Minimal: `ui_accept`, `ui_cancel`, `ui_up`, `ui_down`, `ui_left`, `ui_right`
(Godot defaults)

B) Standard: A + `battle_confirm`, `battle_cancel`, `battle_up`, `battle_down`,
`battle_left`, `battle_right`

C) Full: B + `menu_start`, `menu_select`, `debug_toggle`, gamepad-specific
mappings

D) Other (please describe after [Answer]: tag below)

[Answer]: A
