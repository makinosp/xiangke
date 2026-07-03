# Integration Test Instructions — Unit 3: Battle System

## Overview

Integration tests for the battle system layer. These tests verify that all
battle components work together correctly: state machine, action execution, turn
management, AI behavior, and UI integration.

---

## Test Scenarios

### IT-1: Full Battle Loop (Player vs Enemy)

**Purpose**: Verify the complete battle loop from start to victory/defeat.

**Test Steps**:

1. Run the project in Godot editor (F5)
2. Navigate through: Title → Character Select → Deploy → Battle Scene loads
3. Verify battle scene shows player and enemy participants with correct HP
4. Select a move from MoveContainer (e.g., "金斬" for 関羽)
5. Select a target from ActionContainer (enemy participant)
6. Verify:
   - Damage is calculated and applied to the enemy's HP
   - Battle log shows the action result (e.g., "関羽 used 金斬! It's super
     effective!")
   - HP displays update for both sides
7. Enemy AI takes its turn automatically:
   - AI selects a move and targets the weakest player participant
   - Damage is applied, HP updates
8. Repeat until one side is defeated or draw (50 turns)
9. Verify: Battle ends, result screen shows correct outcome

**Expected**: Full battle loop executes without errors. All components (UI,
ActionSystem, BattleManager, AI) work together correctly.

---

### IT-2: Type Effectiveness Integration (五行 Cycle)

**Purpose**: Verify type effectiveness is correctly applied in a real battle.

**Test Steps**:

1. Set up a battle with:
   - Player: 関羽 (METAL type) using "金斬" (METAL move, power=90)
   - Enemy: 周瑜 (FIRE+YANG types)
2. Execute the move against the enemy
3. Verify type effectiveness: METAL vs FIRE = 0.5 (not very effective)
4. Verify damage is reduced accordingly

**Expected**: Type effectiveness from `TypeChart` correctly reduces/increases
damage in a real battle context.

---

### IT-3: STAB Integration (Same-Type Attack Bonus)

**Purpose**: Verify 1.2× STAB bonus is applied when move type matches character
type.

**Test Steps**:

1. Set up a battle with:
   - Player: 関羽 (METAL type) using "金斬" (METAL move)
2. Execute the move against an enemy
3. Verify that damage includes the 1.2× STAB multiplier

**Expected**: Damage is higher when move type matches character's primary type.

---

### IT-4: Stat Stage Modification Integration

**Purpose**: Verify stat stage changes persist across turns and affect damage.

**Test Steps**:

1. Set up a battle where one participant uses a move that modifies stat stages
   (e.g., "war_cry" which boosts ATTACK)
2. Apply the move and verify stat stage increases (e.g., +1 to ATTACK)
3. On the next turn, use a damaging move and verify:
   - Damage calculation uses the boosted stat stage multiplier (1.5× for +1)
4. Verify that stat stages persist across multiple turns

**Expected**: Stat stage modifications affect subsequent damage calculations
correctly.

---

### IT-5: AI Action Selection Integration

**Purpose**: Verify AI selects the best move and targets the weakest enemy.

**Test Steps**:

1. Set up a battle with:
   - Player has 2 characters with different HP levels (one low, one high)
   - Enemy uses AI-controlled moves
2. Let the enemy take its turn
3. Verify:
   - AI targets the player character with lowest HP percentage
   - AI selects the move with highest score (power × type effectiveness ×
     accuracy)

**Expected**: AI behavior is strategic and targets correctly.

---

### IT-6: Turn Order (Speed-Based) Integration

**Purpose**: Verify turn order is recalculated each round based on effective
speed.

**Test Steps**:

1. Set up a battle with participants having different speeds:
   - Player 1: Speed=80, Player 2: Speed=120
   - Enemy 1: Speed=60, Enemy 2: Speed=150
2. Start the battle and observe turn order in Round 1:
   - Expected: Enemy 2 (150) → Player 2 (120) → Player 1 (80) → Enemy 1 (60)
3. If a move modifies speed during the round, verify that:
   - Current round's turn order is NOT affected (recalculated next round)
   - Next round's turn order reflects the speed change

**Expected**: Turn order follows effective speed, recalculated each round.

---

### IT-7: Battle End Conditions Integration

**Purpose**: Verify victory, defeat, and draw conditions trigger correctly.

**Test Steps**:

1. **Victory**: Defeat all enemy participants → verify battle ends with VICTORY
   status
2. **Defeat**: Defeat all player participants → verify battle ends with DEFEAT
   status
3. **Draw**: Let the battle reach 50 turns → verify battle ends with DRAW status
4. Verify: After battle ends, result screen shows correct outcome and save data
   is updated

**Expected**: All end conditions trigger correctly and transition to result
screen.

---

### IT-8: Save Data Integration (Battle Result)

**Purpose**: Verify battle result is saved and loaded correctly.

**Test Steps**:

1. Complete a battle (win or lose)
2. Verify `SaveManager.current_data["last_battle_won"]` is set correctly
3. Close and reopen the game
4. Verify save data persists (result screen shows correct outcome)

**Expected**: Battle result saved to `user://save.cfg` and loaded on restart.

---

### IT-9: UI Integration (Move Selection & Targeting)

**Purpose**: Verify the battle scene UI correctly handles player input.

**Test Steps**:

1. Run the project and reach the battle scene
2. Verify MoveContainer shows all 4 moves for the active participant
3. Click a move → ActionContainer shows enemy targets with HP info
4. Select a target → action executes, damage applies
5. Verify "Cancel" button returns to move selection
6. Verify "Wait" option skips the turn

**Expected**: UI correctly handles all player input scenarios without errors.

---

### IT-10: Battle Log Integration

**Purpose**: Verify battle log displays action results correctly.

**Test Steps**:

1. Run the project and reach the battle scene
2. Execute several actions (player and AI)
3. Verify BattleLog RichTextLabel shows:
   - Each action's result (who used what, damage dealt, type effectiveness)
   - Log entries are appended in order
   - Recent log (last 10 entries) is displayed

**Expected**: Battle log accurately reflects all actions taken during the
battle.

---

## Running Tests

### Manual Testing (Recommended)

All integration tests are manual and require running the project in the Godot
editor or an exported build. Use the test steps above as a checklist.

### Semi-Automated Testing (Optional)

Create a test script that sets up specific battle scenarios and verifies
outcomes:

```bash
godot --headless --path /path/to/xiangke --script tests/battle_integration_tests.gd --quit
```

---

## Review Test Results

- **Expected**: All integration scenarios complete without errors or crashes
- **Test Report Location**: Godot Output panel / terminal stdout
- **Coverage**: Full battle loop, type effectiveness, AI behavior, UI
  integration

---

## Fix Failing Tests

If an integration test fails:

1. Check the Godot Output panel for error messages
2. Identify which component failed (ActionSystem, BattleManager, UI, etc.)
3. Refer to the unit test instructions for that component
4. Fix the issue and re-run the integration test
