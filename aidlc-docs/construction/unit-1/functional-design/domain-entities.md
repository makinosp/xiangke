# Domain Entities — Unit 1: Resources (Shared Data)

## Overview

Domain entities for the game's shared data layer. These define the core business
objects used across all systems.

---

## Entity: Character

Represents a playable character or enemy in the battle system.

### Properties

| Property      | Type    | Description                                                              |
| ------------- | ------- | ------------------------------------------------------------------------ |
| id            | String  | Unique identifier (e.g., "zhuge_liang")                                  |
| name          | String  | Display name (e.g., "諸葛亮")                                            |
| type          | Type    | Primary type (one of 7 types)                                            |
| secondaryType | Type    | Optional second type (one of 7 types, or null)                           |
| hp            | Integer | Base HP stat (1–999)                                                     |
| attack        | Integer | Base attack stat (1–999)                                                 |
| defense       | Integer | Base defense stat (1–999)                                                |
| speed         | Integer | Base speed stat (1–999)                                                  |
| intelligence  | Integer | Base intelligence stat (1–999) — attack power for arts and strategies    |
| spirit        | Integer | Base spirit stat (1–999) — damage resistance against arts and strategies |
| moves         | [Move]  | List of 4 move IDs this character can use                                |
| description   | String  | Flavor text for the character                                            |

### Constraints

- Each character has exactly 4 moves.
- Stats are unique per character (no class/template system).
- Primary type must be one of the 7 defined types.
- Secondary type is optional; if set, it MUST differ from the primary type.
- Initial roster: 9+ characters.
- Approximately 30–50% of characters SHOULD have a secondary type.

---

## Entity: Move

Represents a battle action a character can perform.

### Properties

| Property       | Type             | Description                                        |
| -------------- | ---------------- | -------------------------------------------------- |
| id             | String           | Unique identifier (e.g., "fire_strike")            |
| name           | String           | Display name (e.g., "火撃")                        |
| type           | Type             | Move's type (one of 7 types)                       |
| power          | Integer          | Base power (0–255, 0 = non-damage)                 |
| accuracy       | Integer          | Hit chance percentage (0–100)                      |
| effect         | EffectType       | Special effect category                            |
| effectChance   | Integer          | Percentage chance of effect triggering (0–100)     |
| statMod        | StatModification | Stat change applied (if any)                       |
| hitCount       | Integer          | Number of hits (1 for single, 2–5 for multi-hit)   |
| recoil         | Integer          | Fraction of damage dealt returned to user (0–100)  |
| healing        | Integer          | HP restored to user as percentage of power (0–100) |
| damageCategory | DamageCategory   | Whether the move deals physical or arts damage     |
| description    | String           | Flavor text for the move                           |

### Effect Types

| Effect Type | Japanese | Description                          |
| ----------- | -------- | ------------------------------------ |
| None        | なし     | No special effect                    |
| Burn        | 炎上     | Deals damage over time each turn     |
| Poison      | 毒       | Deals increasing damage each turn    |
| Confusion   | 混乱     | May cause the target to hit itself   |
| Chain       | 連環     | Links damage across multiple targets |
| Charm       | 魅了     | Reduces target's attack stat         |

### Damage Categories

| Category | Description                                                        |
| -------- | ------------------------------------------------------------------ |
| Physical | Uses attacker's Attack and defender's Defense for damage calc      |
| Arts     | Uses attacker's Intelligence and defender's Spirit for damage calc |

### Move Categories

| Category    | Description                                    |
| ----------- | ---------------------------------------------- |
| Attack      | Deals damage with optional status/stat effects |
| Multi-hit   | Strikes 2–5 times in one turn                  |
| Heal        | Restores HP to self or ally                    |
| Status-only | Inflicts status without damage                 |

---

## Entity: TypeChart

Defines the effectiveness relationships between the 7 types.

### Types

| Type  | Japanese | Element |
| ----- | -------- | ------- |
| Wood  | 木       | Wood    |
| Fire  | 火       | Fire    |
| Earth | 土       | Earth   |
| Metal | 金       | Metal   |
| Water | 水       | Water   |
| Yang  | 陽       | Light   |
| Yin   | 陰       | Dark    |

### Type Effectiveness Values

| Multiplier | Description                                |
| ---------- | ------------------------------------------ |
| 2.0        | Super effective (double damage) — 相克     |
| 1.25       | Generating bonus (slight advantage) — 相生 |
| 1.0        | Normal damage                              |
| 0.5        | Not very effective (half damage) — 被相克  |
| 0.0        | No effect (immune)                         |

### Type Chart Matrix

| Attacker →<br>Defender ↓ | Wood | Fire | Earth | Metal | Water | Yang | Yin |
| ------------------------ | ---- | ---- | ----- | ----- | ----- | ---- | --- |
| **Wood**                 | 1.0  | 1.25 | 1.0   | 0.5   | 2.0   | 1.0  | 1.0 |
| **Fire**                 | 0.5  | 1.0  | 1.25  | 1.0   | 2.0   | 1.0  | 1.0 |
| **Earth**                | 2.0  | 0.5  | 1.0   | 1.25  | 1.0   | 1.0  | 1.0 |
| **Metal**                | 1.0  | 2.0  | 0.5   | 1.0   | 1.25  | 1.0  | 1.0 |
| **Water**                | 1.25 | 1.0  | 2.0   | 0.5   | 1.0   | 1.0  | 1.0 |
| **Yang**                 | 1.0  | 1.0  | 1.0   | 1.0   | 1.0   | 1.0  | 2.0 |
| **Yin**                  | 1.0  | 1.0  | 1.0   | 1.0   | 1.0   | 2.0  | 1.0 |

> **Reading the matrix**: The row is the **defender's type**, the column is the
> **attacker's type**. For example, a **Fire** move against a **Wood defender**
> = 1.25× (Fire generates Wood in the 相生 cycle).

### Cycle Legend

| Relationship      | Multiplier | Direction                    |
| ----------------- | ---------- | ---------------------------- |
| 相生 (Generating) | 1.25×      | Attacker nourishes defender  |
| 相克 (Overcoming) | 2.0×       | Attacker defeats defender    |
| 被相克 (Overcome) | 0.5×       | Attacker is weak to defender |
| 同タイプ (Same)   | 1.0×       | Neutral                      |
| 陰陽 (Yin-Yang)   | 2.0×       | Mutual super effectiveness   |

### Five Elements Cycles (五行)

**Generating Cycle (相生)**: Wood → Fire → Earth → Metal → Water → Wood

- Each element nourishes the next (1.25× slight advantage in battle)
- The attacker's type generates the defender's type, so the attack resonates and
  deals slightly more damage

**Overcoming Cycle (相克)**: Wood → Earth → Water → Fire → Metal → Wood

- Each element defeats the next (2.0× super effective in battle)
- The attacker's type overcomes the defender's type

**Overcome Cycle (被相克)**: The reverse of 相克 (0.5× not very effective)

- When the attacker's type is overcome by the defender's type

### Yin-Yang Relationship

- Yang and Yin are super effective against each other (2.0×)
- Yang and Yin have neutral (1.0×) effectiveness against 五行 types

### Dual-Type (双属性) Calculation

Some characters possess both a primary and a secondary type. When a move attacks
a dual-type character, the effectiveness multipliers for both defensive types
are **multiplied together**:

```
final_multiplier = type_multiplier(attack_type, primary_type)
                  × type_multiplier(attack_type, secondary_type)
```

**Example**: A **Fire** move against a character with primary **Wood** and
secondary **Earth**:

- Fire vs Wood = 1.25× (相生)
- Fire vs Earth = 1.25× (相生)
- Final = 1.25 × 1.25 = **1.5625×**

**Example**: A **Wood** move against a character with primary **Fire** and
secondary **Water**:

- Wood vs Fire = 0.5× (被相克)
- Wood vs Water = 1.25× (相生)
- Final = 0.5 × 1.25 = **0.625×**

#### Dual-Type Multiplier Bounds

| Scenario                 | Multiplier Range      |
| ------------------------ | --------------------- |
| Best case (both 相生)    | 1.25 × 1.25 = 1.5625× |
| Worst case (both 被相克) | 0.5 × 0.5 = 0.25×     |
| Neutral                  | 1.0 × 1.0 = 1.0×      |

> **Design note**: The multiplicative approach rewards strategic type matching
> while penalizing poor matchups. A dual-type character with two 相生
> resistances against an attack takes 1.5625× damage, adding depth to team
> composition decisions.

---

## Entity: StatusEffect

Defines a status condition that can affect a character during battle.

### Properties

| Property      | Type             | Description                                 |
| ------------- | ---------------- | ------------------------------------------- |
| id            | String           | Unique identifier (e.g., "burn")            |
| name          | String           | Display name (e.g., "炎上")                 |
| type          | Enum             | Burn, Poison, Confusion, Chain, Charm       |
| duration      | Integer          | Turns remaining (0 = permanent until cured) |
| damagePerTurn | Integer          | Damage as % of max HP per turn (0 if N/A)   |
| statMod       | StatModification | Stat change applied (if any)                |

### Status Effect Definitions

#### Burn (炎上)

| Property        | Value                                 |
| --------------- | ------------------------------------- |
| Type            | Damage over time                      |
| Damage per turn | 6.25% of max HP (1/16)                |
| Stat modifier   | Attack ×0.5                           |
| Duration        | Permanent until cured or switched out |
| Visual cue      | Red flame icon, orange tint           |

#### Poison (毒)

| Property        | Value                                            |
| --------------- | ------------------------------------------------ |
| Type            | Damage over time (escalating)                    |
| Damage per turn | 1.56% × turns_poisoned (cumulative, caps at 25%) |
| Stat modifier   | None                                             |
| Duration        | Permanent until cured or switched out            |
| Visual cue      | Purple bubble icon, purple tint                  |

#### Confusion (混乱)

| Property        | Value                                |
| --------------- | ------------------------------------ |
| Type            | Self-hit chance                      |
| Damage per turn | N/A (50% chance to hit self instead) |
| Stat modifier   | None                                 |
| Duration        | 1–5 turns (random on application)    |
| Visual cue      | Stars icon, swirling animation       |

#### Chain (連環)

| Property        | Value                                        |
| --------------- | -------------------------------------------- |
| Type            | Linked damage propagation                    |
| Damage per turn | N/A (damage is shared across linked targets) |
| Stat modifier   | Speed ×0.5                                   |
| Duration        | 2 turns or until target switches out         |
| Visual cue      | Chain link icon, electric sparks             |

#### Charm (魅了)

| Property        | Value                             |
| --------------- | --------------------------------- |
| Type            | Attack reduction                  |
| Damage per turn | N/A                               |
| Stat modifier   | Attack ×0.5                       |
| Duration        | 1–3 turns (random on application) |
| Visual cue      | Heart icon, pink tint             |

---

## Entity: StatModification

Represents a temporary change to a character's stats during battle.

### Properties

| Property   | Type     | Description                      |
| ---------- | -------- | -------------------------------- |
| stat       | StatType | Which stat is modified           |
| stage      | Integer  | Stage change (-6 to +6)          |
| multiplier | Float    | Resulting multiplier (see table) |

### Stat Types

| Stat Type    | Description                                   |
| ------------ | --------------------------------------------- |
| Attack       | Physical attack power                         |
| Defense      | Physical defense                              |
| Speed        | Turn order priority                           |
| Intelligence | Attack power for arts and strategies          |
| Spirit       | Damage resistance against arts and strategies |

### Stage Multiplier Table

| Stage | Multiplier |
| ----- | ---------- |
| -6    | 0.25       |
| -5    | 0.29       |
| -4    | 0.33       |
| -3    | 0.40       |
| -2    | 0.50       |
| -1    | 0.67       |
| 0     | 1.00       |
| +1    | 1.50       |
| +2    | 2.00       |
| +3    | 2.50       |
| +4    | 3.00       |
| +5    | 3.50       |
| +6    | 4.00       |

---

## Entity Relationships

```
Character ──1:N──→ Move (each character has 4 moves)
Character ──1:1──→ Type (primary type)
Character ──0:1──→ Type (optional secondary type)
Move ──────1:1──→ Type (each move has 1 type)
Move ──────0:1──→ StatusEffect (move may inflict a status)
TypeChart ──N:N──→ Type (effectiveness matrix between all types)
StatusEffect ──0:1──→ StatModification (status may modify stats)
```
