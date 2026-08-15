## Purpose

Defines how much of the opponent's team is disclosed to the player during
battle: the opponent's selection stays hidden, and characters are revealed only
when they appear on the field.

## ADDED Requirements

### Requirement: Opponent Selection Hidden

The system SHALL keep the opponent's battle selection hidden from the player at
battle start. The opponent team panel SHALL fully display only the opponent's
front character and SHALL display every other slot as a grayed-out slot showing
the character's identity but no battle state, up to 5 slots.

#### Scenario: Battle start reveals only the front

- **WHEN** a battle starts
- **THEN** the opponent's front character is fully displayed in the opponent
  panel
- **AND** up to 5 remaining opponent slots are displayed as grayed-out slots
  showing the character's name and type but no HP, status, or stat-stage
  information

#### Scenario: Player team fully visible

- **WHEN** a battle starts
- **THEN** all player team characters are revealed in the player panel

### Requirement: Reveal on Field Appearance

The system SHALL reveal an opponent character when it appears on the field as
the initial front character, via a switch, or via automatic bench replacement,
and SHALL keep it revealed for the rest of the battle even after it returns to
the bench.

#### Scenario: Switch reveals a benched character

- **WHEN** the opponent switches a hidden benched character to the front
- **THEN** that character becomes revealed

#### Scenario: Automatic replacement reveals a benched character

- **WHEN** the opponent's front character is defeated and a hidden benched
  character replaces it
- **THEN** the replacing character becomes revealed

#### Scenario: Revealed character stays revealed on the bench

- **WHEN** a revealed opponent character switches back to the bench
- **THEN** the character remains revealed

### Requirement: Defeated Opponent Display

The system SHALL render an opponent character that appeared on the field and was
defeated in a state clearly distinct from a slot that never appeared: the slot
SHALL stay revealed and show the character's identity plus a defeat marker, and
SHALL NOT resemble an unselected slot.

#### Scenario: Defeated slot shows a defeat marker

- **WHEN** an opponent character that appeared on the field is defeated
- **THEN** the character's slot stays revealed and shows the character's name
  and type
- **AND** the slot shows a clear defeat marker (e.g., "DEFEATED") and no HP,
  status, or stat-stage information

#### Scenario: Defeated state distinguishable from unselected

- **WHEN** the opponent panel displays both a defeated slot and slots whose
  characters never appeared on the field
- **THEN** the defeated slot is visually distinct from the never-appeared slots
- **AND** no never-appeared slot shows the defeat marker

### Requirement: Hidden Slot Placeholders

The system SHALL render opponent slots whose characters have never appeared on
the field as grayed-out slots that show the character's identity and type but no
HP, status, or stat-stage information, and SHALL NOT disclose whether the
character was selected for the battle.

#### Scenario: Grayed-out slot shows identity

- **WHEN** an opponent slot has not appeared on the field
- **THEN** the slot is grayed out but shows the character's name and type
- **AND** the slot shows no HP, status, or stat-stage information

#### Scenario: Selection status not disclosed

- **WHEN** the opponent panel shows grayed-out slots
- **THEN** no grayed-out slot indicates whether its character was selected for
  the battle or left benched in the corps
