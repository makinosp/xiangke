# Proposal: Add Character Portraits to Battle Scene

## Summary

Add character portrait images (standing illustrations) to the battle UI. Each
character will have a 2:3 aspect ratio portrait displayed in their
BattleUnitPanel. Start with a placeholder image, replaceable per-character
later.

## Motivation

- Visual identity for characters during battle
- Polish and immersion for the battle system
- Foundation for future character customization/skins

## Scope

**In scope:**

- Add `portrait_path` field to CharacterData resource
- Add TextureRect to BattleUnitPanel for portrait display
- Create placeholder portrait image
- Configure per-character portrait paths in .tres files
- Display portraits for both player and enemy teams (revealed slots only for
  enemies)

**Out of scope:**

- Animated portraits
- Portrait transitions/effects
- Different portraits per form/skin
- Portrait selection UI

## Design Approach

**Option A: Portrait in BattleUnitPanel** (selected)

- Add TextureRect at top of each panel
- 2:3 aspect ratio (e.g., 120x180px minimum)
- Maintains self-contained panel design
- Works for both player (HBox) and enemy (Grid) layouts

## Acceptance Criteria

1. BattleUnitPanel shows portrait area above name/type row
2. Placeholder image displays when no character-specific portrait exists
3. CharacterData has optional `portrait_path` field
4. Enemy portraits show for revealed slots; hidden slots show placeholder or
   grayed-out
5. All existing tests pass
6. No regression in battle UI layout
