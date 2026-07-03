# Unit Test Instructions — Unit 3: Battle System

## Overview

Unit tests for the battle system layer. These tests verify that each component
works correctly in isolation: damage calculation, turn order, stat stages, and
battle state evaluation.

---

## Testing Approach

GDScript does not have a standard xUnit-style test framework. We use:

1. Godot's `assert()` statements for fail-fast validation (NFR-3.1)
2. Godot's headless mode (`godot --headless`) for automated execution
3. Manual verification via Godot's Output panel

---

## Test Scenarios

### UT-1: BattleParticipant Creation & Validation

**Purpose**: Verify `BattleParticipant.create()` validates inputs correctly.

**Test Steps**:

1. Create a valid `CharacterData` resource (e.g., load `guan_yu.tres`)
2. Call `BattleParticipant.create(char_data, BattleParticipant.Team.PLAYER, 0)`
3. Verify: `current_hp == max_hp == char_data.hp`
4. Verify: `stat_stages` is an array of 5 zeros
5. Verify: `is_defeated == false`

**Edge Cases**:

- Pass `null` as character data → should trigger `assert()` failure
- Pass invalid team value (e.g., `-1`) → should trigger `assert()` failure
- Pass negative slot index → should trigger `assert()` failure

**Expected**: Valid participant created with correct initial state. Invalid
inputs fail fast with clear error messages.

---

### UT-2: Stat Stage Modifiers

**Purpose**: Verify stat stage clamping and multiplier calculation.

**Test Steps**:

1. Create a `BattleParticipant` with default stat stages (all 0)
2. Apply +3 to ATTACK stage:
   `participant.apply_stat_stage(TypeEnums.Stat.ATTACK, 3)`
3. Verify stage is clamped to +3 (not exceeding MAX_STAT_STAGE=6)
4. Get multiplier:
   `participant.get_stat_stage_multiplier(TypeEnums.Stat.ATTACK)`
5. Verify multiplier for +3: `(2+3)/2 = 2.5`
6. Apply -4 to DEFENSE stage:
   `participant.apply_stat_stage(TypeEnums.Stat.DEFENSE, -4)`
7. Verify multiplier for -4: `2/(2-(-4)) = 2/6 ≈ 0.33`
8. Apply +10 to SPEED stage (exceeds max): verify clamped to +6
9. Verify multiplier for +6: `(2+6)/2 = 4.0`
10. Apply -10 to INTELLIGENCE stage (exceeds min): verify clamped to -6
11. Verify multiplier for -6: `2/(2-(-6)) = 2/8 = 0.25`

**Expected**: All stage values clamped to [-6, +6]. Multipliers match formula.

---

### UT-3: Damage Calculation — Basic Physical Attack

**Purpose**: Verify basic damage formula for physical moves.

**Test Steps**:

1. Create attacker with ATK=100, DEF=50 (irrelevant for physical)
2. Create defender with DEF=80, SPI=60 (irrelevant for physical)
3. Create a `MoveData` with: power=90, damage_category=PHYSICAL
4. Call `ActionSystem.calculate_damage(attacker, defender, move)`
5. Expected raw damage: `(100 × 90 × 0.8) / 80 = 7200/80 = 90`
6. Verify `result.raw_damage == 90` (before type/STAB/variance)
7. Verify `result.damage_dealt > 0` (after all modifiers applied)

**Expected**: Damage calculated correctly using physical formula.

---

### UT-4: Damage Calculation — Arts Attack (INT vs SPI)

**Purpose**: Verify arts damage uses Intelligence and Spirit stats.

**Test Steps**:

1. Create attacker with INT=130, ATK=45 (irrelevant for arts)
2. Create defender with SPI=100, DEF=65 (irrelevant for arts)
3. Create a `MoveData` with: power=80, damage_category=ARTS
4. Call `ActionSystem.calculate_damage(attacker, defender, move)`
5. Expected raw damage: `(130 × 80 × 0.8) / 100 = 8320/100 = 83.2 → 83`
6. Verify `result.raw_damage == 83`

**Expected**: Arts damage uses INT/SPI, not ATK/DEF.

---

### UT-5: Type Effectiveness — Super Effective (2.0×)

**Purpose**: Verify super-effective type matchups apply 2.0× multiplier.

**Test Steps**:

1. Create attacker with type=METAL (index 3)
2. Create defender with primary type=WOOD (index 0), no secondary type
3. Create a `MoveData` with: type=METAL, power=100
4. Call `ActionSystem.calculate_damage(attacker, defender, move)`
5. Verify `result.type_effectiveness == 2.0` (Metal super effective vs Wood)
6. Verify `result.is_super_effective == true`

**Expected**: Type effectiveness correctly resolved from `TypeChart`.

---

### UT-6: Type Effectiveness — Not Very Effective (0.5×)

**Purpose**: Verify not-very-effective type matchups apply 0.5× multiplier.

**Test Steps**:

1. Create attacker with type=FIRE (index 1)
2. Create defender with primary type=EARTH (index 2), no secondary type
3. Create a `MoveData` with: type=FIRE, power=100
4. Call `ActionSystem.calculate_damage(attacker, defender, move)`
5. Verify `result.type_effectiveness == 0.5` (Fire not very effective vs Earth)
6. Verify `result.is_not_very_effective == true`

**Expected**: Type effectiveness correctly resolved from `TypeChart`.

---

### UT-7: Dual-Type Effectiveness (Primary × Secondary)

**Purpose**: Verify dual-type defenders multiply effectiveness.

**Test Steps**:

1. Create attacker with type=WATER (index 4)
2. Create defender with primary=FIRE (1), secondary=EARTH (2)
3. WATER vs FIRE = 2.0 (super effective), WATER vs EARTH = 1.25 (generating)
4. Expected final: `2.0 × 1.25 = 2.5` (clamped to [0.25, 4.0])
5. Verify `result.type_effectiveness == 2.5`

**Expected**: Dual-type effectiveness is product of both, clamped to [0.25,
4.0].

---

### UT-8: STAB (Same-Type Attack Bonus)

**Purpose**: Verify 1.2× bonus when move type matches character's primary type.

**Test Steps**:

1. Create attacker with primary type=METAL (3)
2. Create a `MoveData` with: type=METAL, power=100
3. Call `ActionSystem.calculate_damage(attacker, defender, move)`
4. Verify STAB multiplier (1.2×) is applied to damage

**Expected**: Damage includes 1.2× STAB bonus when types match.

---

### UT-9: Accuracy Check (Miss)

**Purpose**: Verify moves with low accuracy can miss.

**Test Steps**:

1. Create a `MoveData` with: accuracy=30 (low)
2. Run `ActionSystem.calculate_damage()` 100 times in a loop
3. Count how many times `result.hit == false`
4. Expected miss rate: ~70% (1 - 0.3)

**Expected**: Miss rate approximately matches (100 - accuracy)% over many
trials.

---

### UT-10: Recoil Damage

**Purpose**: Verify recoil damage is applied to the attacker.

**Test Steps**:

1. Create a `MoveData` with: power=90, recoil=25 (25% of damage dealt)
2. Call `ActionSystem.calculate_damage(attacker, defender, move)`
3. Verify `result.recoil_damage > 0` (if damage was dealt)
4. Verify recoil ≈ `result.damage_dealt × 25 / 100`

**Expected**: Attacker takes recoil damage proportional to damage dealt.

---

### UT-11: Healing Move

**Purpose**: Verify healing moves restore HP correctly.

**Test Steps**:

1. Create a `MoveData` with: power=0, healing=50 (50% of max HP)
2. Create attacker with current_hp = 30, max_hp = 100
3. Call `ActionSystem.calculate_damage(attacker, defender, move)` (healing is
   self-target)
4. Verify `result.healing_done == 50` (30 + 50 = 80, capped at max_hp=100)

**Expected**: Healing restores HP up to max_hp cap.

---

### UT-12: BattleState Win/Loss Evaluation

**Purpose**: Verify battle state correctly detects victory/defeat/draw.

**Test Steps**:

1. Create `BattleState` with 2 player and 2 enemy participants
2. Defeat all enemies: set `is_defeated = true` for both enemies
3. Call `state.evaluate_battle_status()` → should return `true`, status=VICTORY
4. Reset: defeat all players instead → status=DEFEAT
5. Set `turn_count = 50` (MAX_TURNS) → status=DRAW

**Expected**: Correct battle outcome detected in each scenario.

---

### UT-13: BattleManager Turn Queue (Speed-Based)

**Purpose**: Verify turn queue is sorted by effective speed (descending).

**Test Steps**:

1. Create 4 participants with different speeds: [80, 120, 60, 150]
2. Create `BattleState` with these participants
3. Call `BattleManager.calculate_turn_queue(state)`
4. Verify queue order: [150, 120, 80, 60] (descending by speed)

**Expected**: Participants sorted by effective speed, fastest first.

---

### UT-14: BattleManager Skip Defeated Participants

**Purpose**: Verify defeated participants are excluded from turn queue.

**Test Steps**:

1. Create 4 participants, set one as defeated (`is_defeated = true`)
2. Call `BattleManager.calculate_turn_queue(state)`
3. Verify queue contains only 3 participants (defeated one excluded)

**Expected**: Defeated participants not included in turn queue.

---

## Running Tests

### Manual Testing via Godot Editor

1. Open the project in Godot
2. Create a test script that instantiates each component and calls its methods
3. Check the Output panel for `assert()` failures or error messages

### Automated Testing via Headless Mode

```bash
# Run a test script in headless mode
godot --headless --path /path/to/xiangke --script tests/battle_unit_tests.gd --quit
```

---

## Review Test Results

- **Expected**: All `assert()` statements pass (no errors in output)
- **Test Report Location**: Godot Output panel / terminal stdout
- **Coverage**: All battle system components (Participant, State, Action,
  Manager, Flow)

---

## Fix Failing Tests

If an `assert()` fails:

1. Read the error message — it includes the failing condition and values
2. Check the component's input validation logic
3. Fix the data or code causing the failure
4. Re-run tests
