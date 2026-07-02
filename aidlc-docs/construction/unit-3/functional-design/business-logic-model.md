# Business Logic Model — Unit 3: Battle System

This document describes the core algorithms and workflows for the Battle System.

## 1. Turn Flow Workflow (Speed-Based)

The battle proceeds in rounds. Each round consists of multiple turns.

### Round Start

1. **Initiative Calculation**: The `TurnManager` scans all non-defeated
   `BattleParticipant`s.
2. **Queue Generation**: Participants are sorted in descending order of their
   current Speed stat (Base Speed + Stage Modifiers + Status Effects).
3. **Turn Queue**: The sorted list becomes the `turn_queue` for the round.

### Turn Execution

For each participant in the `turn_queue`:

1. **Start-of-Turn Processing**:
   - Process non-damage status effects (e.g., action restrictions, stat
     debuffs).
2. **Action Request**:
   - If `team == PLAYER`: `BattleFlowService` requests action from `PlayerUI`.
   - If `team == ENEMY`: `BattleFlowService` requests action from
     `AIController`.
3. **Action Execution**:
   - `ActionSystem` calculates the effect of the chosen `MoveData`.
   - Apply damage/healing/stat changes to targets.
   - Trigger animations and update `BattleLog`.
4. **End-of-Turn Processing**:
   - Process damage-over-time (DoT) effects.
   - Decrement duration of all active status effects.
   - Check if the participant is defeated.
5. **Win/Loss Evaluation**:
   - Check if all enemies or all allies are defeated.

### Round End

1. Increment `round_count`.
2. Return to **Round Start**.

## 2. Action Execution Pipeline

When an `Action` is executed:

1. **Validation**: Check if the source has enough MP and if the move is still
   usable.
2. **Targeting**: Ensure the target is valid.
3. **Damage Calculation**: The `ActionSystem` calculates the final value using:
   - Base Damage (from `MoveData`)
   - Type Effectiveness (based on 5 Elements)
   - STAB (Same-Type Attack Bonus): 1.2x if move type matches character type.
   - Stat Modifiers: Applied based on current `stat_stages`.
4. **Effect Application**: Apply damage/healing, status effects, and stat
   changes to targets.
5. **Feedback**: Trigger animations and update `BattleLog`.
6. **Calculation**:
   - Calculate raw power based on `MoveData` and source stats.
   - Apply Type Effectiveness (五行 system).
   - Apply STAB (Same-Type Attack Bonus).
   - Apply Stat Stages (Buffs/Debuffs).
   - Apply Field Effects.
   - Apply random variance (e.g., 85% - 100%).
7. **Application**:
   - Subtract HP/MP.
   - Apply new status effects if specified in `MoveData`.
8. **Feedback**: Update UI and log the result.

## 3. Damage Calculation Formula (Conceptual)

$$Damage = \left( \frac{f(ATK_{source}, Power_{move})}{f(DEF_{target})} \right) \times TypeMod \times STAB \times StageMod \times FieldMod \times RandomVar$$

- $f(Stat, Power)$: A function combining the attacker's relevant stat and the
  move's base power.
- $TypeMod$: Multiplier based on the 五行 type chart.
- $STAB$: Bonus if the move's type matches the character's primary type.
- $StageMod$: Multiplier based on the current ATK/DEF stages of source and
  target.
- $FieldMod$: Multiplier based on the current `field_effect`.
- $RandomVar$: A random float between 0.85 and 1.0.

## 4. Win/Loss Condition Evaluation

After every action:

- **Victory**: All enemy `BattleParticipant`s have `is_defeated == true`.
- **Defeat**: All player `BattleParticipant`s have `is_defeated == true`.
- **Draw**: `turn_count` reaches the limit (e.g., 50 turns).
- **Escape**: If the `FLEE` action is successful, the battle ends in a "Retreat"
  state.
