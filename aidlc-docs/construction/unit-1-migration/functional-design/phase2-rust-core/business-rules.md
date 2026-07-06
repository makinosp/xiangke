# Business Rules — Phase 2: Core Data Types

## Overview

Validation rules and constraints for the Rust core data types. These ensure data
integrity and consistent behavior across all downstream systems.

---

## Character Data Rules (CR)

### CR-1: Character Identity

- Each character MUST have a unique `id` (lowercase snake_case, e.g.
  "zhuge_liang").
- Each character MUST have a non-empty `name` (1–20 characters).
- Character `id` MUST NOT change after creation (used as lookup key).

### CR-2: Character Stats

- All stats (hp, attack, defense, speed, intelligence, spirit) MUST be u32
  values in range [1, 999].
- Stats are unique per character (no shared templates).
- The sum of all six base stats MUST NOT exceed 3000 (balance constraint).
- No single stat MAY exceed 500 (prevent extreme specialization).

### CR-3: Character Type Assignment

- Each character MUST have exactly one primary type (element).
- Primary type MUST be one of the 7 valid types.
- A character MAY have an optional secondary type (`Option<TypeElement>`).
- If secondary type is set, it MUST differ from the primary type.

### CR-4: Character Move Assignment

- Each character MUST have exactly 4 moves (`moves.len() == 4`).
- All 4 moves MUST reference valid move IDs that exist in the move data
  (validated at the application level, not in core).
- A character's moves MUST include at least one damaging move (validated by
  reference to MoveData).

---

## Move Data Rules (MR)

### MR-1: Move Identity

- Each move MUST have a unique `id` (lowercase snake_case).
- Each move MUST have a non-empty `name` (1–20 characters).
- Move `id` MUST NOT change after creation.

### MR-2: Move Power and Accuracy

- `power` MUST be in range [0, 255].
- `accuracy` MUST be in range [1, 100].
- If `power` is 0, the move is non-damaging (status/heal only).

### MR-3: Move Effect

- `effect` MUST be one of: None, Burn, Poison, Confusion, Chain, Charm.
- If `effect` is `None`, `effect_chance` MUST be 0.
- If `effect` is not `None`, `effect_chance` MUST be in range [1, 100].

### MR-4: Move Stat Modification

- If `stat_mod_stat` is `Some(stat)`, `stat_mod_stage` MUST be in [-3, +3].
- If `stat_mod_stat` is `None`, `stat_mod_stage` MUST be 0.
- Multiple stat modifications are cumulative but clamped to [-6, +6] (battle
  level).

### MR-5: Move Multi-Hit

- `hit_count` MUST be in [1, 5].
- If `hit_count` > 1, each hit uses the same `power` and `element`.

### MR-6: Move Recoil

- `recoil` MUST be in [0, 100].
- If `recoil` > 0, `power` MUST be > 0 (recoil requires damage).

### MR-7: Move Healing

- `healing` MUST be in [0, 100].
- If `healing` > 0, the move restores HP to the user (not target).

---

## Status Effect Data Rules (SR)

### SR-1: Status Effect Identity

- Each status effect MUST have a unique `status_type`.
- Each status effect MUST have a non-empty `name`.

### SR-2: Status Effect Damage

- `damage_per_turn` MUST be in [0.0, 1.0] (fraction of max HP).
- `max_damage_cap` MUST be in [0.0, 1.0] (fraction of max HP).
- If `damage_per_turn` is 0.0, `escalating` SHOULD be false.

### SR-3: Status Effect Stat Modification

- If `stat_mod_stat` is `Some(stat)`, `stat_mod_multiplier` MUST not be 1.0.
- `stat_mod_multiplier` MUST be > 0.0.

---

## Validation Architecture

### Error Model

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationError {
    pub field: String,         // e.g. "base_stats.hp"
    pub rule: String,          // e.g. "CR-2"
    pub message: String,       // human-readable description
    pub value: Option<String>, // the invalid value (for debugging)
}

pub type ValidationResult = Result<(), Vec<ValidationError>>;
```

### Validator Interface

```rust
pub fn validate_character(data: &CharacterData) -> ValidationResult
pub fn validate_move(data: &MoveData) -> ValidationResult
pub fn validate_status(data: &StatusEffectData) -> ValidationResult
```

### Validation Strategy

- Collect ALL errors before returning (don't short-circuit on first error).
- Each validation function returns `Ok(())` or `Err(vec![...])` with all
  violations.
- Input-level validation (range checks) belongs in core.
- Cross-record validation (e.g., "all referenced move IDs exist") belongs in the
  database layer.
