## MODIFIED Requirements

### Requirement: Character Data

The system SHALL define characters with unique ID, display name translation key,
primary type, optional secondary type, 6 stats (HP, attack, defense, speed,
intelligence, spirit), exactly 4 moves, and flavor description translation key.

#### Scenario: Character validation

- **WHEN** a character is validated
- **THEN** its ID is unique lowercase snake_case
- **AND** its name translation key is non-empty and resolves in all 4 catalogs
- **AND** all stats are integers in [1, 999]
- **AND** stat sum ≤ 3000
- **AND** no single stat > 500
- **AND** it has exactly 4 moves
- **AND** at least one move has power > 0

#### Scenario: Localized character display

- **WHEN** a character's name or description is displayed
- **THEN** it is resolved via the character's translation keys for the active
  locale
- **AND** matches the catalog entry for that locale

### Requirement: Move Data

The system SHALL define moves with unique ID, display name translation key,
element type, damage category, power, accuracy, optional secondary effect,
optional stat modification, optional multi-hit, optional recoil, and optional
healing.

#### Scenario: Move validation

- **WHEN** a move is validated
- **THEN** its ID is unique lowercase snake_case
- **AND** its name translation key is non-empty and resolves in all 4 catalogs
- **AND** power is in [0, 255] (0 = status move)
- **AND** accuracy is in [0.0, 1.0]
- **AND** stat_mod_stage is in [-6, +6]
- **AND** stat_mod_target is in [0, 1] (0 = SELF, 1 = TARGET)
- **AND** hit_count is in [1, 5]
- **AND** recoil and healing are in [0.0, 1.0]

#### Scenario: Localized move display

- **WHEN** a move's name or description is displayed
- **THEN** it is resolved via the move's translation keys for the active locale
- **AND** matches the catalog entry for that locale

### Requirement: Status Effect Data

The system SHALL define status effects with unique ID, display name translation
key, effect type, damage per turn, escalation flag, max damage cap, and optional
stat modification.

#### Scenario: Status effect validation

- **WHEN** a status effect is validated
- **THEN** its ID is unique lowercase snake_case
- **AND** its name translation key is non-empty and resolves in all 4 catalogs

#### Scenario: Status effect application

- **WHEN** a status effect is applied to a character
- **THEN** its display name is resolved via the effect's translation key for the
  active locale
- **AND** matches the catalog entry for that locale
- **AND** damage per turn is applied according to the effect's configuration
- **AND** escalation and damage cap rules are enforced

#### Scenario: Localized status effect display

- **WHEN** a status effect's name or description is displayed
- **THEN** it is resolved via the effect's translation keys for the active
  locale
- **AND** matches the catalog entry for that locale
