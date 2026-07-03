# Business Rules — Unit 3: Battle System

This document defines the constraints and rules governing the Battle System.

## 1. Turn Order Rules

- **Speed Priority**: Higher speed always acts first.
- **Tie-Breaking**: In case of identical speed, a random participant is chosen.
- **Recalculation**: Turn order is recalculated at the start of every round.
  Changes to speed during a round do not affect the current `turn_queue` but
  will affect the next round.

## 2. Action Rules

- **MP Constraint**: An action cannot be executed if the source's `current_mp`
  is less than the move's cost.
- **Move Limit**: Characters are limited to 4 moves, as defined in their `.tres`
  resources.
- **Targeting**:
  - Single-target moves must have one valid target.
  - Area-of-effect (AoE) moves target all participants of the opposing team.
- **Fleeing**: The `FLEE` action has a probability of success. If successful,
  the battle ends immediately.

## 3. Damage and Type Rules

- **Type Effectiveness**: Damage is multiplied based on the 五行 (Wood, Fire,
  Earth, Metal, Water) relationship.
- **STAB (Same-Type Attack Bonus)**: If a move's type matches the character's
  type, damage is increased by a fixed percentage (e.g., 1.2x).
- **Stat Stages**:
  - Stages range from -6 to +6.
  - Each stage increases or decreases the stat by a specific multiplier.
- **Zero Damage**: Damage cannot be negative; the minimum damage is 1.

## 4. Status Effect Rules

- **Processing Order**:
  - **Start of Turn**: Non-damage effects (e.g., "Paralyzed" skipping turn,
    "Attack Down" stat change).
  - **End of Turn**: Damage-over-time (DoT) effects (e.g., "Burn", "Poison").
- **Duration**: All status effects have a duration in turns. Duration is
  decremented at the end of the affected participant's turn.
- **Expiration**: When duration reaches 0, the effect is removed.

## 5. Battle State Rules

- **Defeat**: A participant is marked `is_defeated` when `current_hp <= 0`.
- **Turn Limit**: The battle is forced to a draw if the `turn_count` exceeds 50.
- **Victory/Defeat Trigger**: The battle ends immediately when one side is
  completely defeated.
