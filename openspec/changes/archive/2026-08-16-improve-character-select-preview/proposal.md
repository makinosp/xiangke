# Improve Character Select Preview

## Why

The character overview window (`StatsPreview`) on the character select screen is
built from fixed pixel offsets inside a panel that is too short for its content
at 1280×720. The description label reaches y=370 while the panel is only 324px
tall, so the flavor text collides with the panel's bottom edge, and the fourth
move row (80px container vs ~92px needed for 4 rows) overflows into the
description label, making part of the move list unreadable. The labels are also
fixed at 190px wide even though the panel is ~512px wide, so text wraps
unnecessarily and increases vertical pressure.

Separately, the opponent corps is rendered as plain read-only labels with no
hover handling at all: hovering an enemy character shows no overview window,
even though the same `CharacterData` is available for all opponent IDs.

## What Changes

- Rebuild the `StatsPreview` layout so every element (name, type, stats, move
  list, description) fits inside the panel with no clipping or overlap
- Let the description label fill the remaining panel space below the move list,
  wrapping its text within the full panel width
- Widen the stat and move labels to use the panel's full width instead of a
  fixed 190px
- Show the overview window when hovering an opponent corps character, reusing
  the same preview population and hide logic already used for player characters
- Apply the same layout fix to the identical `StatsPreview` structure on the
  corps creation screen, which shares the same bug

## Capabilities

### New Capabilities

- `character-select-preview`: presentation rules for the character overview
  window on the corps creation and character select screens — panel layout that
  never clips or overlaps, and hover preview behavior for both player and
  opponent characters

### Modified Capabilities

(none — battle mechanics, targeting, roster data, and opponent visibility in
battle are unchanged; this is a presentation-layer change only)

## Impact

- **Files modified**:
  - `scenes/character_select.tscn` — `StatsPreview` layout (container-based,
    full-width labels, description anchored to the panel bottom)
  - `scripts/foundation/character_select.gd` — opponent label hover wiring in
    `_load_opponent_display()`
  - `scenes/corps_creation.tscn` — same `StatsPreview` layout fix
- **New files**: none expected; the layout can be built with existing Godot
  Control nodes
- **Rust bridge**: no API changes; all displayed data comes from existing
  `CharacterData` / `MoveData` resources
- **No breaking changes**: selection rules, deploy logic, and save/load are
  unaffected
