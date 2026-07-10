# Business Logic Model — Phase 2: Core Data Types

## Overview

Business logic models for the Rust core data types layer. These define the core
calculations and algorithms used by downstream systems.

---

## Logic Model: Type Effectiveness Resolution

### Purpose

Determine the damage multiplier when an attacking move's type hits a defender,
accounting for single-type and dual-type defenders.

### Input

- `attacker_type`: TypeElement enum (one of 7 types)
- `defender_primary`: TypeElement enum (one of 7 types)
- `defender_secondary`: Option<TypeElement> (optional second type)

### Process

```
1. Look up TypeChart.chart[defender_primary][attacker_type] → primary_multiplier
2. If defender_secondary is None:
     → return primary_multiplier
3. Look up TypeChart.chart[defender_secondary][attacker_type] → secondary_multiplier
4. final_multiplier = primary_multiplier × secondary_multiplier
5. Clamp final_multiplier to [MIN_MULTIPLIER=0.25, MAX_MULTIPLIER=4.0]
6. Return final_multiplier
```

### Output

- `multiplier`: f64 in range [0.25, 4.0]

### Key Values (Single-Type)

| Attacker | Defender | Multiplier | Cycle                    |
| -------- | -------- | ---------- | ------------------------ |
| Wood     | Fire     | 1.25       | 相生 (generate)          |
| Wood     | Metal    | 2.0        | 相克 (overcome)          |
| Wood     | Water    | 0.5        | 被相克 (overcome-by)     |
| Fire     | Earth    | 1.25       | 相生                    |
| Fire     | Water    | 2.0        | 相克                    |
| Yang     | Yin      | 2.0        | 陰陽                    |
| Yin      | Yang     | 2.0        | 陰陽                    |

---

## Logic Model: Stat Stage Multiplier Calculation

### Purpose

Calculate the effective stat multiplier from a stat stage value (-6 to +6).

### Input

- `stage`: i32 in range [-6, +6]

### Process

```
1. Validate: stage must be in [-6, +6]
2. If stage == 0: return 1.0
3. If stage > 0: return (2.0 + stage) / 2.0
4. If stage < 0: return 2.0 / (2.0 - stage)
```

### Examples

| Stage | Formula    | Result      |
| ----- | ---------- | ----------- |
| 0     | (2+0)/2    | 1.0         |
| +1    | (2+1)/2    | 1.5         |
| +2    | (2+2)/2    | 2.0         |
| +6    | (2+6)/2    | 4.0         |
| -1    | 2/(2-(-1)) | 0.667 (2/3) |
| -2    | 2/(2-(-2)) | 0.5         |
| -6    | 2/(2-(-6)) | 0.25        |

### Constraints

- Input stage MUST be clamped to [-6, +6] by the caller.
- The formula is asymptotic at stage = +∞ (defense can never reach zero).

---

## Logic Model: Raw Damage Calculation

### Purpose

Calculate the raw damage before type effectiveness, STAB, and variance
modifiers.

### Input

- `effective_attack`: f64 (base_stat × stat_stage_multiplier)
- `power`: u32 (move power, 0-255)
- `effective_defense`: f64 (base_stat × stat_stage_multiplier)

### Process

```
1. Clamp effective_defense to minimum of 1.0 (prevent division by zero)
2. raw_damage = (effective_attack × power × 0.8) / effective_defense
3. Round up and clamp to minimum of 1
4. Return raw_damage as u32
```

### Output

- `raw_damage`: u32 (minimum 1)

### Examples

| Attack | Power | Defense | Formula              | Result |
| ------ | ----- | ------- | -------------------- | ------ |
| 135    | 80    | 95      | (135×80×0.8)/95      | 91     |
| 135    | 80    | 1       | (135×80×0.8)/1       | 8640   |
| 10     | 10    | 200     | (10×10×0.8)/200=0→ 1 | 1      |

---

## Logic Model: Stat Stage Application

### Purpose

Modify a participant's stat stage, clamped to the valid range.

### Input

- `current_stage`: i32 in [-6, +6]
- `change`: i32 (delta to apply, typically -3 to +3)

### Process

```
1. new_stage = current_stage + change
2. Clamp new_stage to [-6, +6]
3. Return new_stage
```

### Constraints

- Multiple moves can stack stage modifiers cumulatively.
- The maximum possible stage is +6 (×4.0 effective stat).
- The minimum possible stage is -6 (×0.25 effective stat).
