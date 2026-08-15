## Purpose

Defines how character portraits are displayed in the battle UI, the slanted
(diagonal) layout that fits large front panels alongside the move list, and the
size modes that switch panels between front (LARGE) and bench (SMALL) display.

## ADDED Requirements

### Requirement: Character Portraits

The system SHALL display a 2:3 aspect-ratio portrait in each battle character
panel, loaded from the character's `portrait_path` when available and falling
back to a placeholder image otherwise.

#### Scenario: Portrait with character image

- **WHEN** a battle participant has a valid `portrait_path`
- **THEN** the panel displays the character's portrait image
- **AND** the portrait maintains a 2:3 aspect ratio (e.g. 120x180, 160x240,
  40x60) via keep-aspect-centered scaling

#### Scenario: Portrait fallback to placeholder

- **WHEN** a participant's `portrait_path` is empty or the file cannot be loaded
- **THEN** the panel displays `res://assets/portraits/placeholder.png`
- **AND** no error interrupts the battle

#### Scenario: Hidden enemy slot placeholder

- **WHEN** an enemy slot has never been revealed
- **THEN** the panel displays the placeholder grayed out (modulate = gray)

#### Scenario: Defeated revealed slot placeholder

- **WHEN** a revealed enemy slot is defeated
- **THEN** the panel displays the placeholder grayed out with a defeat marker

### Requirement: Slanted Battle Layout

The system SHALL arrange battle panels diagonally so the front characters
display large (bottom-left for the player, top-right for the enemy) while the
move list and bench rows remain fully visible within the 1280x720 viewport.

#### Scenario: Front panels positioned diagonally

- **WHEN** the battle scene is shown
- **THEN** the player's front panel is placed in the bottom-left area
- **AND** the enemy's front panel is placed in the top-right area
- **AND** no panel overlaps the move list or the battle log

#### Scenario: Bench rows at top-left

- **WHEN** either team has more characters than the front slot
- **THEN** the player bench characters are shown as a small row below the status
  label
- **AND** the enemy bench characters are shown as a small row beneath the player
  bench row
- **AND** bench rows do not overlap the large front panels

#### Scenario: Move list and battle log placement

- **WHEN** the player's turn starts
- **THEN** the move list panel occupies the bottom-right area
- **AND** the battle log occupies the bottom-left area
- **AND** all elements fit within the 1280x720 viewport without clipping

### Requirement: Panel Size Modes

The system SHALL support three size presets on battle character panels:
STANDARD (default), LARGE (front characters), and SMALL (bench characters),
switchable at runtime.

#### Scenario: LARGE mode for front characters

- **WHEN** a panel is set to LARGE
- **THEN** the portrait is 160x240 and the status and stat rows are visible
- **AND** the panel minimum size is approximately 176x321

#### Scenario: SMALL mode for bench characters

- **WHEN** a panel is set to SMALL
- **THEN** the portrait is 40x60 and the status and stat rows are hidden
- **AND** the panel minimum size is approximately 80x109

#### Scenario: Standard mode default

- **WHEN** a panel is created without a size preset
- **THEN** the portrait is 120x180 and all rows are visible
- **AND** the portrait rect uses ignore-size expansion so presets control the
  size instead of the texture's pixel dimensions
