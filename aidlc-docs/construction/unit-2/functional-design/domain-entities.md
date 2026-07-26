# Domain Entities — Unit 2: Game Foundation

## Overview

Domain entities for the game foundation layer. These define the core objects
that govern application lifecycle, scene management, persistence, and audio
playback.

---

## Entity: GameState (Enum)

Represents the active game state within the GameManager's finite state machine.

### Values

| State              | Description                                                           |
| ------------------ | --------------------------------------------------------------------- |
| `TITLE`            | Title screen is active. Entry point of the game loop.                 |
| `CORPS_CREATION`   | Corps creation screen is active. Player selects 6 characters.         |
| `CHARACTER_SELECT` | Battle selection screen is active. Player picks 3 from their corps.   |
| `BATTLE`           | Battle scene is active. Managed by BattleManager (Unit 3).            |
| `RESULT`           | Battle result screen is active following a battle conclusion.         |

### Constraints

- The state machine has 5 states:
  `TITLE → CORPS_CREATION → CHARACTER_SELECT → BATTLE → RESULT → TITLE`.
- No pause, settings, or game-over sub-states exist in v1.
- Transitions are unidirectional along the defined loop (no arbitrary jumps).
- `CHARACTER_SELECT` state is only reachable from `CORPS_CREATION`.
- `BATTLE` state is only reachable from `CHARACTER_SELECT`.
- `RESULT` state is only reachable from `BATTLE`.

---

## Entity: CharacterSelectPhase (Enum)

Represents the current phase within the two-screen character selection flow.
Phase 1 is handled by the CorpsCreation screen; Phase 2 by CharacterSelect.

### Values

| Phase              | Description                                                             |
| ------------------ | ----------------------------------------------------------------------- |
| `CORPS_SELECTION`  | CorpsCreation screen: Player selects 6 characters to form their corps.  |
| `BATTLE_SELECTION` | CharacterSelect screen: Player selects 3 out of their 6 to deploy.      |

### Constraints

- `CORPS_SELECTION` is completed on the CorpsCreation screen (separate scene).
- `BATTLE_SELECTION` is completed on the CharacterSelect screen (separate scene).
- The opponent's 6-character corps is generated during the transition between screens.
- Exactly 6 characters must be selected in `CORPS_SELECTION`.
- Exactly 3 characters must be selected in `BATTLE_SELECTION` from the 6 chosen.
- `BATTLE_SELECTION` order determines battle deployment order.

---

## Entity: SaveData

Represents the persisted game state stored in a single `save.cfg` file via
Godot's `ConfigFile` API.

### Sections and Keys

| Section    | Key                  | Type   | Description                                           |
| ---------- | -------------------- | ------ | ----------------------------------------------------- |
| `settings` | `master_volume`      | Float  | Master volume level (0.0–1.0).                        |
| `settings` | `bgm_volume`         | Float  | BGM volume level (0.0–1.0).                           |
| `settings` | `sfx_volume`         | Float  | SFX volume level (0.0–1.0).                           |
| `settings` | `master_muted`       | Bool   | Whether master output is muted.                       |
| `progress` | `selected_character` | String   | ID of the last selected character (for quick resume). |
| `progress` | `last_battle_won`    | Bool     | Whether the last completed battle was a victory.      |
| `progress` | `last_battle_time`   | String   | ISO 8601 timestamp of the last completed battle.      |
| `progress` | `corps_characters`   | String[] | JSON-serialized list of 6 character IDs (saved corps).|
| `meta`     | `save_version`       | Int    | Save file format version (for migration).             |

### Constraints

- All data is stored in a single file: `user://save.cfg`.
- The `save_version` key MUST be present and MUST match the current format
  version (`1`). Mismatched versions trigger a reset to defaults.
- Missing keys are treated as their default values (graceful degradation).
- No sensitive data (PII, credentials) is stored.

---

## Entity: CorpsRoster

Represents the player's character roster for battle preparation, managing both
the corps (6 characters) and the selected battle party (3 characters).

### Properties

| Property            | Type          | Description                                         |
| ------------------- | ------------- | --------------------------------------------------- |
| `corps_characters`  | Array[String] | List of 6 unique character IDs forming the corps.   |
| `battle_characters` | Array[String] | List of 3 unique character IDs selected for battle. |

### Constraints

- `corps_characters` MUST contain exactly 6 unique character IDs.
- `battle_characters` MUST contain exactly 3 unique character IDs.
- All IDs in `battle_characters` MUST exist in `corps_characters`.
- Selection order in `battle_characters` determines battle deployment order.

---

## Entity: AudioTrack

Represents a registered audio track (BGM or SFX) managed by AudioController.

### Properties

| Property | Type        | Description                                               |
| -------- | ----------- | --------------------------------------------------------- |
| `id`     | String      | Unique identifier (e.g., "bgm_title", "sfx_confirm").     |
| `stream` | AudioStream | The Godot AudioStream resource to play.                   |
| `bus`    | String      | Target audio bus name (e.g., "Master", "BGM", "SFX").     |
| `loop`   | Bool        | Whether the track loops (BGM typically true, SFX false).  |
| `layer`  | Int         | Dynamic music layer index (0 = base, higher = intensity). |

### Constraints

- Track IDs MUST be unique within the AudioController registry.
- BGM tracks MUST have `loop = true`.
- SFX tracks MUST have `loop = false`.
- Layer indices are used for dynamic music intensity (battle intensity scaling).

---

## Entity: TransitionConfig

Represents configuration for a scene transition animation.

### Properties

| Property     | Type  | Description                                                       |
| ------------ | ----- | ----------------------------------------------------------------- |
| `duration`   | Float | Total transition duration in seconds.                             |
| `fade_color` | Color | Color of the fade overlay (default: black).                       |
| `animation`  | Enum  | Transition animation type: `FADE`, `FADE_TO_BLACK`, `SLIDE_LEFT`. |
| `wait_time`  | Float | Hold time at full fade before loading the next scene.             |

### Constraints

- `duration` MUST be > 0.0.
- `wait_time` MUST be >= 0.0.
- Default transition is `FADE_TO_BLACK` with 0.5s duration and 0.1s wait.

---

## Entity: CorpsRoster

Represents the player's selected corps during the two-phase character selection.

### Properties

| Property            | Type          | Description                                         |
| ------------------- | ------------- | --------------------------------------------------- |
| `corps_characters`  | Array[String] | 6 character IDs selected in Phase 1.                |
| `battle_characters` | Array[String] | 3 character IDs selected in Phase 2 (subset of 6).  |
| `opponent_corps`    | Array[String] | 6 character IDs of the opponent's corps (revealed). |

### Constraints

- `corps_characters` MUST contain exactly 6 unique character IDs.
- `battle_characters` MUST contain exactly 3 unique IDs, all of which MUST be
  present in `corps_characters`.
- `opponent_corps` is populated by the AI/system between Phase 1 and Phase 2.
- The order of `battle_characters` determines deployment order in battle.
