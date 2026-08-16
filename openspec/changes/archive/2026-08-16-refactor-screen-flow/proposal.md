## Why

The current screen flow tightly couples corps creation with battle preparation:
the player must select 6 corps characters every time before choosing 3 for
deployment. This makes the flow feel like a single long sequence rather than
distinct preparation and battle-ready phases. Separating corps management into
its own dedicated screen gives players a clear "set up your team" step that
persists, and a separate "pick who fights" step. Adding back buttons to all
sub-screens also improves navigation clarity.

## What Changes

- **Separate corps management from battle preparation**: The existing
  `corps_creation` screen becomes a standalone "Corps Settings" screen
  accessible directly from the title, where the player configures and saves
  their 6-character corps roster.
- **Title screen becomes a hub**: The title screen gains a "Corps Settings"
  button alongside the existing "Start" and "Settings" buttons. The "Start"
  button transitions directly to `character_select` using the saved corps.
- **Battle preparation uses saved corps**: `character_select` reads the saved
  corps from `CorpsRoster` (populated by the corps settings screen) and lets the
  player pick 3 for deployment. It no longer depends on a preceding
  `corps_creation` step in the same session.
- **Back buttons on sub-screens**: Both the corps settings screen and the
  character select screen gain a "Back" button that returns to the title screen.
- **Disabled state for Start**: The "Start" button on the title screen is
  disabled when no corps has been saved yet, guiding the player to configure
  their corps first.

## Capabilities

### New Capabilities

- `screen-flow`: Defines the overall screen navigation model, including all
  valid transitions, back-button behavior, and the role of each screen.

### Modified Capabilities

- `system`: The "Scene Flow" requirement describes a linear Title →
  CorpsCreation → CharacterSelect → Battle → Result flow. This needs updating to
  reflect the new hub-and-spoke topology with back buttons.

## Impact

- `autoloads/game_manager.gd`: `GameState` enum, `_is_valid_transition()`,
  `get_scene_for_state()` — new states and transition rules.
- `scripts/foundation/title_screen.gd`: New button, disabled-state logic.
- `scripts/foundation/corps_creation.gd`: Back button, save-and-return behavior.
- `scripts/foundation/character_select.gd`: Back button, load from saved corps
  instead of in-session selection.
- `scenes/title_screen.tscn`, `scenes/corps_creation.tscn`,
  `scenes/character_select.tscn`: UI node changes (new buttons).
- `translations/*.csv`: New UI string keys for back button and button labels.
