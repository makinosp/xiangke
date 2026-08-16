# Character Select Preview Specification

## Purpose

Defines how the character overview window (`StatsPreview`) is presented on the
corps creation and character select screens: a panel layout that keeps every
element fully visible without clipping or overlap, and hover preview behavior
for both the player's corps and the opponent's corps.

## ADDED Requirements

### Requirement: Preview Panel Layout

The system SHALL lay out the character overview panel so that all of its
elements — character name, type, six stats, up to four moves, and flavor
description — are fully contained within the panel, with no element overlapping
another and no text clipped by the panel boundary.

#### Scenario: All preview content fits the panel

- **WHEN** the character overview panel is shown for a character with four moves
- **THEN** the name, type, all six stats, all four move rows, and the
  description are visible inside the panel
- **AND** no two elements overlap
- **AND** no element extends beyond the panel's bottom or right edge

#### Scenario: Fewer than four moves

- **WHEN** the character overview panel is shown for a character with fewer than
  four moves
- **THEN** only the known move rows are displayed
- **AND** the description occupies the space freed by the missing move rows

### Requirement: Description Display

The system SHALL display the character's flavor description inside the panel
below the move list, wrapping at the panel width, and SHALL NOT overlap the move
list regardless of description length.

#### Scenario: Long description wraps within the panel

- **WHEN** a character with a long description is hovered
- **THEN** the description text wraps within the panel width below the move list
- **AND** the description does not cover any move row

#### Scenario: Short description leaves no gap

- **WHEN** a character with a short description is hovered
- **THEN** the description is shown directly below the move list with no large
  empty gap
- **AND** the description ends within the panel boundary

### Requirement: Opponent Hover Preview

The system SHALL show the character overview panel when the pointer hovers an
opponent character on the character select screen, and SHALL hide it when the
pointer leaves that opponent character.

#### Scenario: Hovering an opponent shows the preview

- **WHEN** the pointer enters an opponent corps character label on the character
  select screen
- **THEN** the overview panel is shown populated with that opponent's name,
  type, stats, moves, and description

#### Scenario: Leaving an opponent hides the preview

- **WHEN** the pointer exits the opponent corps character label
- **THEN** the overview panel is hidden

#### Scenario: Opponent preview shows the hovered identity

- **WHEN** the pointer moves from one opponent character label to another
- **THEN** the overview panel updates to the newly hovered character's data
