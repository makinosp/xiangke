## ADDED Requirements

### Requirement: Type Match Bonus

The system SHALL apply a 1.5× damage multiplier when the attacker's element
matches the move's element (type match). This bonus is applied after base damage
calculation and before type effectiveness.

#### Scenario: Type match bonus applied

- **WHEN** the attacker's element matches the move's element
- **THEN** the damage is multiplied by 1.5×
- **AND** the `is_type_matched` flag is set to `true` in the action result

#### Scenario: No type match bonus for different types

- **WHEN** the attacker's element differs from the move's element
- **THEN** no type match bonus is applied
- **AND** the `is_type_matched` flag is set to `false` in the action result

#### Scenario: Type match bonus in damage pipeline

- **WHEN** a damaging move is executed
- **THEN** the damage pipeline applies: base damage → type match bonus → type
  effectiveness → variance → critical hit
- **AND** the type match bonus is applied before type effectiveness
