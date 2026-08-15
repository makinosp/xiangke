# Improve Move Selection UI

## Why

The player's move selection UI is currently a dynamic vertical button list
packed into a 72px-high container, so the four move buttons plus the switch
option overflow the screen and the bottom options are unreachable. The buttons
only show name/power/accuracy in one line: effect information (status chances,
stat stage changes, healing, recoil, multi-hit), type effectiveness against the
opponent's front character, and flavor text are all invisible even though the
data exists. Battle is also the only screen that does not register keyboard
navigation with `UIFocusManager`, making it inconsistent with the other screens.

## What Changes

- Replace the vertical move list with a 2×2 grid of move buttons plus a separate
  switch option row
- Expand the move selection panel layout so all options fit within the viewport
- Each move button displays:
  - Type name in type color, move name, power, accuracy, and damage category
  - Effect badges: status effect (with trigger chance), stat stage changes,
    healing, recoil, and multi-hit count
  - Type effectiveness multiplier against the opponent's current front character
    (e.g. ×2.0, ×1.25, ×0.5, ×0)
  - Flavor description as a tooltip on hover/focus
- Switch (Bench) remains available as a separate full-width option below the
  move grid
- Keyboard navigation for the move grid and switch option works consistently
  with the rest of the game (arrow keys move within the grid, Enter confirms)

## Capabilities

### New Capabilities

- `move-selection-ui`: presentation and interaction rules for the player's move
  selection during battle — layout, per-move information display, type
  effectiveness hints, and keyboard navigation

### Modified Capabilities

(none — battle mechanics, targeting, turn logic, and AI behavior are unchanged;
this is a presentation-layer change only)

## Impact

- **Files modified**:
  - `scenes/battle_scene.tscn` — move selection panel layout (position, size,
    `GridContainer` for the 2×2 grid)
  - `scripts/foundation/battle_scene.gd` — move button creation and rendering
    (replaces the single-line buttons in `_show_move_selection()`)
  - `scripts/foundation/type_colors.gd` — may gain small display helpers (e.g.
    effectiveness multiplier formatting) if needed
- **New files**: none expected; the move button UI can be built with existing
  Godot Control nodes, or a small helper script if the button grows complex
- **Rust bridge**: no API changes; all displayed data comes from `MoveData`
  resources and `TypeChart`, both already available in GDScript
- **No breaking changes**: battle mechanics, save/load, and opponent visibility
  are unaffected
