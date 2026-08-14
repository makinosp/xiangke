## Why

The battle scene currently displays HP as plain text labels (e.g., "Name:
120/150") with no visual progress indicators. Status effects, stat stages, and
character type attributes are completely invisible during battle. This makes the
battle experience feel bare and forces players to mentally parse raw numbers to
assess team state. With 38 characters and 5 status effects already implemented,
the UI needs to convey richer information to support meaningful tactical
decisions.

## What Changes

- Replace text-only HP labels with `ProgressBar` widgets showing visual fill and
  color coding (green → yellow → red)
- Display active status effects (Burn, Poison, Confusion, etc.) as labeled
  badges on each character panel
- Show stat stage changes (ATK↑2, DEF↓1, etc.) as indicators on each character
  panel
- Add character type attributes (element icons/labels) next to character names
  with type-specific coloring
- Introduce `BattleUnitPanel` scene as a reusable component for character
  display in the battle UI
- Add `TypeColors` utility for consistent type-to-color mapping across the UI
- Improve move selection buttons with type color indicators
- Enhance switch selection UI to show HP bars and status for benched characters

## Capabilities

### New Capabilities

(none — purely visual enhancement, no spec-level behavior change)

### Modified Capabilities

(none — existing battle mechanics remain unchanged)

## Impact

- **Files created**: `scripts/foundation/type_colors.gd`,
  `scenes/battle_unit_panel.tscn`, `scripts/battle_unit_panel.gd`
- **Files modified**: `scripts/foundation/battle_scene.gd`,
  `scenes/battle_scene.tscn` (minor container adjustments)
- **No Rust changes**: All modifications are in GDScript and scene files
- **No API changes**: Rust bridge, battle flow service, and data models are
  unaffected
- **No breaking changes**: Battle mechanics, turn logic, and save/load remain
  identical
