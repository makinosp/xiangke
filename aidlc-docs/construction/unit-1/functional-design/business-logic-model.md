# Business Logic Model — Unit 1: Resources (Shared Data)

## Overview

Business logic models for the shared data layer. These define how game data is
structured, validated, and used by other systems.

---

## Logic Model: Type Effectiveness Resolution

### Purpose

Determine the damage multiplier when an attacker uses a move against a defender,
accounting for single-type and dual-type defenders.

### Input

- `attacker_move_type`: Type enum (one of 7 types)
- `defender_primary_type`: Type enum (one of 7 types)
- `defender_secondary_type`: Type enum or null (optional second type)

### Process

```
1. Look up TypeChart[attacker_move_type][defender_primary_type] → primary_multiplier
2. If defender_secondary_type is null:
     → return primary_multiplier
3. Look up TypeChart[attacker_move_type][defender_secondary_type] → secondary_multiplier
4. final_multiplier = primary_multiplier × secondary_multiplier
5. Clamp final_multiplier to [0.25, 4.0]
6. Return final_multiplier
```

### Output

- `multiplier`: Float value applied to damage calculation (range: 0.25–4.0)

### Rules

- Type effectiveness is a single multiplier (no STAB in v1).
- If multiplier is 0.0, the move has no effect and no secondary effects apply.
- The type chart is asymmetric in direction (attacker → defender).
- **Generating Cycle (相生)**: When the attacker's type generates the defender's
  type (e.g., Wood → Fire), the multiplier is 1.25×. This reflects the 五行
  concept where the attacker's energy nourishes the defender but still deals
  slightly more damage due to resonance.
- **Overcoming Cycle (相克)**: When the attacker's type overcomes the defender's
  type (e.g., Wood → Earth), the multiplier is 2.0×.
- **Overcome Cycle (被相克)**: The reverse of 相克, the multiplier is 0.5×.
- **Yin-Yang**: Yang and Yin are super effective against each other (2.0×).
- **Dual-Type (双属性)**: When the defender has a secondary type, multiply the
  effectiveness of both type matchups. The result is clamped to a minimum of
  0.25× and a maximum of 4.0× to prevent extreme values.
- **Dual-Type Examples**:
  - Fire vs (Wood + Earth) = 1.25 × 1.25 = **1.5625×**
  - Wood vs (Fire + Water) = 0.5 × 1.25 = **0.625×**
  - Metal vs (Wood + Earth) = 2.0 × 0.5 = **1.0×**

---

## Logic Model: Status Effect Application

### Purpose

Determine if a status effect is applied when a move is used.

### Input

- `move`: Move entity with effect and effectChance properties
- `target`: Character entity (to check immunities)

### Process

```
1. If move.effect == None → no status applied
2. Generate random integer 1–100
3. If random <= move.effectChance → status is applied
4. Create StatusEffect instance with type = move.effect
5. Apply status to target
6. If status has statMod → apply stat modification to target
```

### Output

- `applied`: Boolean (whether status was applied)
- `status`: StatusEffect instance (if applied)

### Rules

- A character can only have one status effect at a time.
- If a character already has a status, the new one replaces it.
- Burn and Poison cannot coexist (new one replaces old).
- Confusion, Chain, and Charm are mutually exclusive.

---

## Logic Model: Damage Calculation

### Purpose

Calculate the damage dealt by a move.

### Input

- `attacker`: Character entity (with stats)
- `defender`: Character entity (with stats)
- `move`: Move entity (with power, type)

### Process

```
1. If move.power == 0 → damage = 0 (non-damaging move)
2. If move.damageCategory == Physical:
     attack_stat = attacker.attack
     defense_stat = defender.defense
   If move.damageCategory == Arts:
     attack_stat = attacker.intelligence
     defense_stat = defender.spirit
3. base_damage = ((2 * 50 / 5 + 2) * move.power * attack_stat / defense_stat) / 50 + 2
4. type_multiplier = TypeChart[move.type][defender.type]
   - 2.0 if attacker overcomes defender (相克)
   - 1.25 if attacker generates defender (相生)
   - 1.0 if neutral
   - 0.5 if attacker is overcome by defender (被相克)
   - 0.0 if immune
5. final_damage = floor(base_damage * type_multiplier)
6. If final_damage < 1 AND type_multiplier > 0 → final_damage = 1 (minimum 1 damage)
7. If type_multiplier == 0 → final_damage = 0 (immune)
```

### Output

- `damage`: Integer (HP to subtract from defender)

### Rules

- Damage is always an integer (floor after all calculations).
- Minimum 1 damage on any non-immune hit.
- Multi-hit moves calculate damage independently for each hit.
- Recoil damage = floor(final_damage * move.recoil / 100).
- Healing amount = floor(attacker.max_hp * move.healing / 100).

---

## Logic Model: Stat Modification

### Purpose

Apply temporary stat changes during battle.

### Input

- `target`: Character entity
- `statMod`: StatModification from move or status effect

### Process

```
1. Clamp target's current stage + statMod.stage to [-6, +6]
2. Set target's stage for statMod.stat to clamped value
3. Recalculate effective stat using stage multiplier table
```

### Output

- `new_stage`: Integer (clamped stage value)
- `effective_stat`: Integer (base_stat × multiplier)

### Rules

- Stat stages range from -6 to +6.
- Effective stat = base_stat × stage_multiplier.
- Status-imposed stat mods (e.g., Burn's attack ×0.5) stack with stage mods.
- Stat mods reset when character switches out or battle ends.

---

## Logic Model: Status Effect Tick

### Purpose

Process status effects at the end of each turn.

### Input

- `affected_character`: Character with an active status effect
- `turn_count`: Current turn number (for poison escalation)

### Process

```
1. If status == Burn:
   - damage = floor(max_hp * 0.0625)
   - Subtract damage from current HP
2. If status == Poison:
   - damage = floor(max_hp * 0.0156 * turn_count)
   - Cap damage at floor(max_hp * 0.25)
   - Subtract damage from current HP
3. If status == Confusion:
   - 50% chance: character hits itself with a typeless attack (power = 40)
4. If status == Chain:
   - No tick action (damage propagation handled on attack)
5. If status == Charm:
   - No tick action (stat mod applied on infliction)
6. Decrement duration (if not permanent)
7. If duration == 0 or HP == 0 → remove status
```

### Output

- `damage_dealt`: Integer (damage from status)
- `status_removed`: Boolean (whether status expired)

### Rules

- Status ticks occur after all actions in a turn are resolved.
- Burn and Poison damage does not trigger recoil or secondary effects.
- Confusion self-hit does not count as an action for turn counting.

---

## Logic Model: Multi-Hit Resolution

### Purpose

Handle moves that strike multiple times.

### Input

- `move`: Move entity with hitCount > 1
- `attacker`: Character entity
- `defender`: Character entity

### Process

```
1. For each hit in 1..move.hitCount:
   a. Calculate damage using Damage Calculation model
   b. Apply damage to defender
   c. If defender HP == 0 → stop remaining hits
2. Sum total damage across all hits
3. If move has effect → roll effectChance once (applies to all hits)
```

### Output

- `total_damage`: Integer (sum of all hits)
- `hits_landed`: Integer (actual hits before defender fainted)
- `effect_applied`: Boolean (if effect chance succeeded)

### Rules

- Each hit of a multi-hit move can be independently affected by type
  effectiveness.
- Effect chance is rolled once, not per hit.
- If defender faints mid-multi-hit, remaining hits are canceled.

---

## Logic Model: Move Execution Pipeline

### Purpose

Orchestrate the complete execution of a move in battle.

### Input

- `attacker`: Character entity
- `defender`: Character entity
- `move`: Move entity

### Process

```
1. Check accuracy: random(1, 100) <= move.accuracy
   - If miss → return {hit: false}
2. If move.power > 0:
   a. If move.hitCount > 1 → use Multi-Hit Resolution model
   b. Else → use Damage Calculation model
3. If move.healing > 0:
   a. healing = floor(attacker.max_hp * move.healing / 100)
   b. Restore HP to attacker (cap at max_hp)
4. If move.recoil > 0:
   a. recoil_damage = floor(total_damage * move.recoil / 100)
   b. Subtract recoil_damage from attacker
5. If move.effect != None AND move.effectChance > 0:
   a. Use Status Effect Application model
6. If move.statMod != None:
   a. Use Stat Modification model on defender
7. Return execution result
```

### Output

- `result`: ExecutionResult containing:
  - `hit`: Boolean
  - `damage`: Integer
  - `healing`: Integer
  - `recoil`: Integer
  - `status_applied`: StatusEffect or null
  - `stat_modified`: Boolean
  - `hits_landed`: Integer

### Rules

- Accuracy check happens first; misses skip all effects.
- Healing happens before recoil (net HP change can be positive).
- Status and stat modifications apply even if damage is 0 (for status-only
  moves).
- Recoil is based on total damage dealt (including multi-hit sum).
