## Purpose

Defines the stat modification target for moves with `stat_mod_stat` set,
enabling both self-buff and target-debuff effects for zero-power status moves.

## MODIFIED Requirements

### Requirement: Move Data

The system SHALL define moves with unique ID, display name, element type, damage
category, power, accuracy, optional secondary effect, optional stat
modification, optional multi-hit, optional recoil, and optional healing.

#### Scenario: Move validation

- **WHEN** a move is validated
- **THEN** its ID is unique lowercase snake_case
- **AND** power is in [0, 255] (0 = status move)
- **AND** accuracy is in [0.0, 1.0]
- **AND** stat_mod_stage is in [-6, +6]
- **AND** stat_mod_target is in [0, 1] (0 = SELF, 1 = TARGET)
- **AND** hit_count is in [1, 5]
- **AND** recoil and healing are in [0.0, 1.0]

### Requirement: Stat Modification Target

The system SHALL specify the target of stat modifications via `stat_mod_target`:

- `SELF` (0): The stat modification applies to the move's user (attacker).
- `TARGET` (1): The stat modification applies to the target (defender).

#### Scenario: Self-targeted stat buff

- **WHEN** a move with `power = 0`, `stat_mod_stat = Defense`,
  `stat_mod_stage = 2`, and `stat_mod_target = SELF` is executed
- **THEN** the attacker's Defense stat stage increases by 2
- **AND** the attacker's effective Defense is recalculated using the new stage

#### Scenario: Target-targeted stat debuff

- **WHEN** a move with `power = 0`, `stat_mod_stat = Attack`,
  `stat_mod_stage = -1`, and `stat_mod_target = TARGET` is executed
- **THEN** the defender's Attack stat stage decreases by 1
- **AND** the defender's effective Attack is recalculated using the new stage

#### Scenario: Non-damaging move with stat modification

- **WHEN** a non-damaging move (`power = 0`) with `stat_mod_stat` set is
  executed
- **THEN** the stat modification is applied regardless of whether damage is
  dealt
- **AND** a log message describing the stat change is generated

## ADDED Requirements

### Requirement: Non-Damaging Move Log Generation

The system SHALL generate a log message for non-damaging moves that apply
effects (stat modification, healing, or status effect).

#### Scenario: Stat modification log message

- **WHEN** a move applies a stat modification
- **THEN** a log message is generated in the format
  `"{name}'s {stat} {rose|fell}{sharply}!"`

#### Scenario: No effect move log message

- **WHEN** a move with `power = 0` has no stat modification, healing, or status
  effect
- **THEN** a log message is generated in the format `"{name} used {move}!"`
