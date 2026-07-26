# Requirements — Fix Unimplemented Features

**Project**: Xiangke (fix/run-project branch) **Date**: 2026-07-26 **Type**:
Enhancement — Complete partially implemented features

## Intent

The GDScript-to-Rust migration is technically complete (100/100 tests pass), but
several features remain unimplemented or incomplete, preventing the game from
running end-to-end. This work completes all outstanding features to make the
game fully playable.

## Functional Requirements

### FR-1: Character Content Expansion

- Add 10 new characters (total 13)
- Each character must have: unique ID, name, type (possibly dual), balanced
  stats (HP 70-140, ATK 40-140, DEF 40-120, SPD 50-120, INT 40-130, SPR 40-120),
  exactly 4 moves
- Characters must cover all 7 element types across the roster
- Create corresponding `.tres` resource files

### FR-2: Enemy Corps Generation Fix

- Current implementation requires 6 player characters + at least 1 enemy
- With 13 total characters, enemy generation will always have enough pool
- No code changes needed to `_generate_opponent_corps()`

### FR-3: BGM/SFX Placeholder Audio

- Create placeholder `.ogg` files for all 10 audio tracks referenced in
  AudioManager
- Each file must be a valid, playable OGG (short silent/ambient track)
- Directory structure: `audio/bgm/` and `audio/sfx/`

### FR-4: StatusEffectData Resource Files

- Create `.tres` files for all 5 status effects: Burn, Poison, Confusion, Chain,
  Charm
- Use `StatusEffectData` class with appropriate values

### FR-5: Battle UI Animation (`_tween_damage`)

- Implement HP bar tween animation when damage is dealt
- Flash red on damage, flash green on healing

### FR-6: Confirm/Deploy Button Layout Fix

- Ensure buttons don't overlap in `character_select.tscn`
- Proper positioning for both Phase 1 (ConfirmCorps) and Phase 2 (Deploy)
  buttons

## Non-Functional Requirements

### NFR-1: Backward Compatibility

- All existing `.gd` and `.rs` files must remain unchanged unless specified
- Rust tests must continue to pass (100/100)
- Godot project must load without parse errors

### NFR-2: Data Consistency

- All character IDs must match the format `lowercase_snake_case`
- All move references in character `.tres` files must exist in
  `resources/moves/`

### NFR-3: Content Balance

- Stats should be balanced: no character should be strictly better than another
- Type distribution should cover all 7 element types
- No duplicate characters

## Implementation Units

1. **Unit A: Character Content** — Create 10 new `.tres` character files
2. **Unit B: Audio Files** — Create placeholder BGM/SFX `.ogg` files
3. **Unit C: Status Effect Resources** — Create 5 `.tres` StatusEffectData files
4. **Unit D: UI Fixes** — Fix button layout, implement `_tween_damage`
