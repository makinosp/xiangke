## MODIFIED Requirements

### Requirement: Type System

The system SHALL define 7 element types (Wood, Fire, Earth, Metal, Water, Yang,
Yin), 6 effect types (None, Burn, Poison, Confusion, Chain, Charm), 2 damage
categories (Physical, Arts), and 6 stats (HP, Attack, Defense, Speed,
Intelligence, Spirit).

#### Scenario: Type enum values

- **WHEN** a type enum is accessed
- **THEN** it contains exactly 7 TypeElement variants
- **AND** each variant maps to a unique `u8` discriminant
