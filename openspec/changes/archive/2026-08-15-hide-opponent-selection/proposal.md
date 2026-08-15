# Hide Opponent Selection

## Why

The battle UI currently reveals the opponent's full fielded team (front + all
benched participants) as soon as the battle starts. This gives the player
complete knowledge of the opponent's selection, eliminating scouting and
counter-play: the player can see exactly which characters the opponent fielded
and plan switches accordingly with zero uncertainty.

## What Changes

- Hide the opponent's selection at battle start: which characters were selected
  from the opponent's 6-character corps is not revealed to the player
- Fully display only the opponent's front character when the battle starts,
  since it is on the field
- Gray out opponent bench characters that have never appeared on the field; the
  opponent panel shows their identity (name and type) but no battle state
- Display the opponent's team as up to 6 slots (1 front + up to 5 grayed-out
  bench/corps slots), so the player sees which characters are present but never
  learns whether they were selected for the battle
- Once an opponent character appears on the field (initial front, switch, or
  automatic bench replacement), it becomes revealed and stays revealed even
  after returning to the bench
- Player team display is unaffected: the player always sees their own full team

## Capabilities

### New Capabilities

- `opponent-roster-visibility`: information disclosure rules for the opponent's
  team during battle — the opponent's selection is hidden at battle start, only
  fielded characters are fully displayed, and all other slots are grayed out (up
  to 5) showing identity but no battle state

### Modified Capabilities

(none — battle mechanics themselves are unchanged; this is a display/information
layer on top of the existing front-line battle model)

## Impact

- **Files modified**: `scripts/foundation/battle_scene.gd` (opponent panel
  rendering with hidden slots, reveal-state tracking),
  `scripts/battle_unit_panel.gd` / `scenes/battle_unit_panel.tscn` (hidden
  placeholder rendering, if any), `scenes/battle_scene.tscn` (opponent panel
  layout for up to 6 slots)
- **Rust bridge**: no API changes expected; reveal state is tracked in GDScript
  against the fielded participants exposed by `BattleFlowService`
- **No breaking changes**: battle mechanics, turn logic, AI, and save/load are
  unaffected
