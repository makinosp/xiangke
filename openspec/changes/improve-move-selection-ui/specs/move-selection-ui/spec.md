## Purpose

Defines how the player's move selection is presented during battle: the move
grid layout, per-move information shown, type effectiveness hints, and keyboard
interaction.

## ADDED Requirements

### Requirement: Move Grid Layout

The system SHALL present the active player character's moves in a 2×2 grid
during the player's turn, with all move options and the switch option fully
visible within the viewport.

#### Scenario: Player turn shows move grid

- **WHEN** the player's turn starts with a living front character
- **THEN** exactly the front character's known moves are displayed in a 2×2 grid
- **AND** the switch option is displayed as a separate full-width option
- **AND** no move option is clipped or overlaps the screen edges

#### Scenario: Character with fewer than four moves

- **WHEN** the front character has fewer than four moves
- **THEN** only the known moves are displayed
- **AND** the grid contains no empty slots

### Requirement: Move Information Display

The system SHALL display for each move its type name, move name, power,
accuracy, damage category, and effect information derived from the move's data.

#### Scenario: Damaging move with status effect

- **WHEN** a move has power greater than zero and a status effect with a trigger
  chance
- **THEN** the move option shows the type name, move name, power, accuracy, and
  damage category
- **AND** a badge identifies the status effect and its trigger chance

#### Scenario: Non-damaging move with stat stage change

- **WHEN** a move has zero power and modifies a stat stage
- **THEN** the move option shows the affected stat and the stage change
- **AND** the display indicates whether the effect applies to the user or the
  target

#### Scenario: Move with healing, recoil, or multi-hit

- **WHEN** a move has healing, recoil, or a hit count greater than one
- **THEN** the move option shows the corresponding healing amount, recoil
  percentage, or multi-hit count

### Requirement: Type Effectiveness Hint

The system SHALL show each move's type effectiveness multiplier against the
opponent's current front character on the move option, using the game's type
effectiveness rules.

#### Scenario: Effectiveness shown for each move

- **WHEN** the player's turn starts
- **THEN** each move option displays its effectiveness multiplier (e.g. ×2.0,
  ×1.25, ×1.0, ×0.5, ×0) against the opponent's front character

#### Scenario: Effectiveness updates after front change

- **WHEN** the opponent's front character changes
- **THEN** the displayed effectiveness multipliers are recomputed for the new
  front character

### Requirement: Flavor Description Tooltip

The system SHALL show the move's flavor description when the player hovers or
focuses the move option.

#### Scenario: Hover or focus shows description

- **WHEN** the player hovers the pointer over a move option or moves keyboard
  focus to it
- **THEN** the move's flavor description is displayed

### Requirement: Switch Option

The system SHALL keep the switch action available from the move selection
screen; selecting it opens the bench character selection.

#### Scenario: Switch option opens bench selection

- **WHEN** the player activates the switch option during their turn
- **THEN** the bench character selection is shown instead of the move grid

#### Scenario: Cancel returns to move grid

- **WHEN** the player cancels the bench character selection
- **THEN** the move grid for the active character is shown again

### Requirement: Keyboard Navigation

The system SHALL support keyboard-only operation of the move selection: arrow
keys move between move options, the confirm key activates the focused option,
and the cancel key closes the bench selection when open.

#### Scenario: Arrow keys move within grid

- **WHEN** the player presses an arrow key while a move option is focused
- **THEN** focus moves to the neighboring move option in the pressed direction,
  wrapping within the grid

#### Scenario: Confirm activates focused option

- **WHEN** the player presses the confirm key while a move option is focused
- **THEN** that move is executed

#### Scenario: Cancel exits bench selection

- **WHEN** the player presses the cancel key while the bench selection is shown
- **THEN** the bench selection closes and the move grid is shown again
