# Performance Test Instructions — Unit 3: Battle System

## Overview

Performance tests for the battle system layer. These tests verify that the
battle system meets non-functional requirements for responsiveness, memory
usage, and frame rate during combat.

---

## Performance Requirements (from NFR Requirements)

| Requirement                | Target                           | Source                |
| -------------------------- | -------------------------------- | --------------------- |
| Turn processing time       | <100ms per turn                  | NFR-3.2 (Performance) |
| Damage calculation time    | <10ms per action                 | NFR-3.2 (Performance) |
| Battle scene load time     | <500ms                           | NFR-3.2 (Performance) |
| Frame rate during battle   | ≥30 FPS (Web), ≥60 FPS (Desktop) | NFR-1.1               |
| Memory usage during battle | <10MB total                      | NFR-3.2 (Memory)      |
| Animation pacing           | 0.5–1s per action                | NFR-3.2 (Animation)   |

---

## Test Scenarios

### PT-1: Turn Processing Performance

**Purpose**: Verify that each turn (including AI action) completes within 100ms.

**Test Steps**:

1. Run the project in Godot editor with debugger enabled
2. Navigate to a battle scene
3. Use the Performance tab in Godot's debugger to measure:
   - Time from turn start to action execution completion
   - Include AI decision-making time for enemy turns
4. Run 20 consecutive turns and record the average processing time

**Expected**: Average turn processing time <100ms.

**Measurement**: Godot debugger Performance tab or manual timing with
`Time.get_ticks_msec()`.

---

### PT-2: Damage Calculation Performance

**Purpose**: Verify that `ActionSystem.calculate_damage()` completes within
10ms.

**Test Steps**:

1. Create a test script that calls `ActionSystem.calculate_damage()` 100 times
2. Measure total time and calculate average per call:

```gdscript
var start_time := Time.get_ticks_msec()
for i in range(100):
    var result := ActionSystem.calculate_damage(attacker, defender, move)
var elapsed := Time.get_ticks_msec() - start_time
print("Average damage calculation time: %.2f ms" % (elapsed / 100.0))
```

3. Run the test in headless mode:

```bash
godot --headless --path /path/to/xiangke --script tests/damage_perf_test.gd --quit
```

**Expected**: Average time <10ms per calculation.

---

### PT-3: Battle Scene Load Time

**Purpose**: Verify the battle scene loads within 500ms.

**Test Steps**:

1. Export an HTML5 build of the project
2. Open in browser with dev tools (Network tab)
3. Navigate from character select to battle scene
4. Measure time from "Deploy" button click to battle scene fully rendered

**Expected**: Load time <500ms.

**Measurement**: Browser dev tools Network tab or Godot's profiler.

---

### PT-4: Frame Rate During Battle

**Purpose**: Verify the game maintains target FPS during active battle.

**Test Steps**:

1. Run the project in Godot editor with debugger enabled
2. Navigate to a battle scene and execute several actions
3. Monitor the FPS counter in Godot's debugger (Monitors tab)
4. Record minimum, average, and maximum FPS during:
   - Idle (waiting for player input)
   - Action execution (damage calculation, UI updates)
   - AI turn processing

**Expected**:

- Web export: ≥30 FPS average
- Desktop: ≥60 FPS average

**Measurement**: Godot debugger Monitors tab or browser dev tools (for Web).

---

### PT-5: Memory Usage During Battle

**Purpose**: Verify memory usage stays under 10MB during battle.

**Test Steps**:

1. Run the project in Godot editor with debugger enabled
2. Navigate to a battle scene
3. Check the Memory usage in Godot's debugger (Monitors tab)
4. Execute several turns and monitor memory growth

**Expected**: Total memory usage <10MB during battle.

**Measurement**: Godot debugger Monitors tab → "Memory" section.

---

### PT-6: Animation Pacing (0.5–1s per action)

**Purpose**: Verify that battle animations and UI updates complete within the
target pacing.

**Test Steps**:

1. Run the project in Godot editor
2. Execute an action and measure:
   - Time from move selection to damage display update
   - Time from damage display to next turn start
3. Verify the pacing feels responsive (0.5–1s per action)

**Expected**: Each action's visual feedback completes within 0.5–1s.

**Note**: This is a subjective test — rely on feel and user feedback for final
tuning.

---

### PT-7: Turn Queue Calculation Performance

**Purpose**: Verify that `BattleManager.calculate_turn_queue()` is efficient.

**Test Steps**:

1. Create a test with 4 participants (2 player, 2 enemy)
2. Call `BattleManager.calculate_turn_queue()` 100 times
3. Measure average time per call:

```gdscript
var start_time := Time.get_ticks_msec()
for i in range(100):
    var queue := BattleManager.calculate_turn_queue(battle_state)
var elapsed := Time.get_ticks_msec() - start_time
print("Average turn queue calculation: %.2f ms" % (elapsed / 100.0))
```

**Expected**: Average time <5ms per calculation (well within the 100ms turn
budget).

---

### PT-8: Type Chart Lookup Performance

**Purpose**: Verify that `TypeChart.resolve_type_effectiveness()` is O(1) and
fast.

**Test Steps**:

1. Create a test that calls `TypeChart.resolve_type_effectiveness()` 1000 times
2. Measure average time per call:

```gdscript
var type_chart := TypeChart.new()
var start_time := Time.get_ticks_msec()
for i in range(1000):
    var result := type_chart.resolve_type_effectiveness(randi() % 7, randi() % 7, -1)
var elapsed := Time.get_ticks_msec() - start_time
print("Average type chart lookup: %.3f ms" % (elapsed / 1000.0))
```

**Expected**: Average time <0.1ms per lookup (O(1) array access).

---

## Running Tests

### Automated Performance Testing (Headless Mode)

```bash
# Run performance tests in headless mode
godot --headless --path /path/to/xiangke --script tests/battle_perf_tests.gd --quit
```

### Manual Performance Testing (Godot Debugger)

1. Open the project in Godot
2. Enable the debugger (Debug → Run Project with Debugger)
3. Use the Monitors and Performance tabs to track metrics during battle

---

## Review Test Results

- **Expected**: All performance targets met (see table above)
- **Test Report Location**: Godot Output panel / terminal stdout / debugger tabs
- **Coverage**: Turn processing, damage calculation, scene loading, FPS, memory,
  animations

---

## Fix Failing Performance Tests

If a performance target is not met:

1. Identify the bottleneck (use Godot's profiler)
2. Optimize the slowest function first (e.g., damage calculation, turn queue)
3. Consider caching precomputed values (e.g., type effectiveness table)
4. Re-run the test to verify improvement
