# Specification: Character Portraits in Battle UI

## Requirements

### Functional Requirements

**FR-1: CharacterData Portrait Field**

- CharacterData resource MUST have optional `portrait_path: String` field
- Default value: empty string ("")
- When empty or file not found, fallback to placeholder

**FR-2: BattleUnitPanel Portrait Display**

- BattleUnitPanel MUST display a TextureRect at top of panel
- Portrait MUST maintain 2:3 aspect ratio (minimum 120x180px)
- Portrait MUST scale to fit while preserving aspect ratio
  (KEEP_ASPECT_CENTERED)

**FR-3: Placeholder System**

- Placeholder image at `res://assets/portraits/placeholder.png`
- Used when: portrait_path empty, file missing, or load fails
- Placeholder MUST be 2:3 aspect ratio

**FR-4: Player Team Portraits**

- All player characters (front + bench) show their portraits
- Portraits update when battle participants change

**FR-5: Enemy Team Portraits**

- Revealed enemy slots show character portrait
- Hidden enemy slots show grayed-out placeholder
- Defeated revealed slots show grayed-out placeholder

**FR-6: Per-Character Configuration**

- Each character .tres file CAN specify `portrait_path`
- Path format: `res://assets/portraits/{character_id}.png`
- Empty string = use placeholder

**FR-7: Slanted Battle Layout**

- Battle scene uses a slanted (diagonal) arrangement to fit large front
  panels and the move list within the 1280x720 viewport:
  - Player front character: bottom-left, LARGE size
  - Enemy front character: top-right, LARGE size
  - Player bench: top-left, SMALL row (below status label)
  - Enemy bench: under the player bench, SMALL row
  - Move list: bottom-right
  - Battle log: bottom-left

**FR-8: Size Modes**

- BattleUnitPanel MUST support three size presets:
  - STANDARD: 120x180 portrait (default, unused in battle scene)
  - LARGE: 160x240 portrait, full status/stat rows, panel min 176x321
  - SMALL: 40x60 portrait, name + HP only, status/stat rows hidden
- `set_size_mode()` MUST switch presets and apply immediately
- Portrait rect MUST use EXPAND_IGNORE_SIZE so presets control the size
  instead of the texture's pixel dimensions

**FR-9: Bench Display**

- Player bench shows non-front player characters as SMALL panels
- Enemy bench shows non-front enemy corps characters as SMALL panels
- Enemy bench slots follow visibility rules: hidden = grayed placeholder,
  revealed = portrait, revealed+defeated = grayed placeholder

### Non-Functional Requirements

**NFR-1: Performance**

- Portrait loading MUST NOT cause visible frame drops
- Textures SHOULD be cached after first load

**NFR-2: Backward Compatibility**

- Existing character resources without portrait_path MUST work (use placeholder)
- No breaking changes to save data or battle logic

**NFR-3: Asset Organization**

- All portraits in `assets/portraits/` folder
- Consistent naming: `{character_id}.png`

## Acceptance Criteria

### AC-1: Basic Display

- [ ] BattleUnitPanel shows portrait area above name/type
- [ ] Portrait maintains 2:3 aspect ratio
- [ ] Placeholder displays when no character portrait set

### AC-2: Player Team

- [ ] Front character shows portrait
- [ ] Bench characters show portraits
- [ ] Portraits update on character switch

### AC-3: Enemy Team

- [ ] Revealed enemy shows character portrait
- [ ] Hidden enemy shows grayed-out placeholder
- [ ] Defeated enemy shows grayed-out placeholder

### AC-3: Character Data

- [ ] CharacterData has portrait_path field
- [ ] .tres files can specify custom path
- [ ] Empty path falls back to placeholder

### AC-4: Regression

- [ ] All existing tests pass
- [ ] Battle UI layout unchanged except portrait addition
- [ ] No errors in console during battle

### AC-5: Slanted Layout

- [ ] Front characters display at LARGE size (160x240 portrait)
- [ ] Bench characters display at SMALL size (40x60 portrait)
- [ ] Player front bottom-left, enemy front top-right
- [ ] Move list bottom-right, battle log bottom-left
- [ ] All panels fit within the 1280x720 viewport

### AC-6: Size Modes

- [ ] LARGE shows status and stat rows
- [ ] SMALL hides status and stat rows
- [ ] Portrait size changes with the preset

## Test Scenarios

### TS-1: Placeholder Only

1. Start battle with characters having empty portrait_path
2. Verify all panels show placeholder
3. Verify aspect ratio correct

### TS-2: Custom Portraits

1. Set portrait_path for one character
2. Start battle with that character
3. Verify custom portrait loads
4. Verify others still show placeholder

### TS-3: Enemy Visibility

1. Start battle
2. Verify hidden enemies show grayed placeholder
3. Reveal enemy (swap or defeat front)
4. Verify portrait updates to character image

### TS-4: Defeated State

1. Defeat enemy character
2. Verify defeated placeholder shows (grayed, not hidden style)

### TS-5: Switch Character

1. Switch player front character
2. Verify new front shows correct portrait
3. Verify moved-to-bench shows correct portrait

### TS-6: Size Modes

1. Set panel to LARGE mode
2. Verify portrait is 160x240 and status/stat rows visible
3. Set panel to SMALL mode
4. Verify portrait is 40x60 and status/stat rows hidden

### TS-7: Slanted Layout

1. Start battle with 3 front + 3 bench characters per side
2. Verify front panels are LARGE
3. Verify bench rows show SMALL panels
4. Verify enemy hidden bench slots show grayed placeholders
