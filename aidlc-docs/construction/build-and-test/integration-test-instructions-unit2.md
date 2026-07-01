# Integration Test Instructions — Unit 2: Game Foundation

## Overview

Integration tests for the game foundation layer. These tests verify that the
systems work together correctly: state machine, save system, audio, and UI.

---

## Test Scenarios

### IT-1: State Machine Integration

**Purpose**: Verify state transitions work correctly with scene loading.

**Test Steps**:

1. Run the project
2. Observe initial state is `TITLE`
3. Click "Start" → should transition to `CHARACTER_SELECT`
4. Select 6 characters → click "Confirm Corps" → should transition to Phase 2
5. Select 3 characters → click "Deploy" → should transition to `BATTLE`
6. Wait for battle placeholder → should transition to `RESULT`
7. Click "Return to Title" → should transition back to `TITLE`

**Expected**: All transitions succeed, no errors in output.

---

### IT-2: Save Data Integration

**Purpose**: Verify save/load works with GameManager and AudioManager.

**Test Steps**:

1. Run the project
2. Click "Start"
3. Navigate to character select (no selection needed for this test)
4. Close and reopen the game
5. Check that save file exists and contains default values

**Expected**: Save file created at `user://save.cfg` with default values.

---

### IT-3: Audio System Integration

**Purpose**: Verify audio initialization and playback.

**Test Steps**:

1. Run the project
2. Click "Start" button
3. Verify audio is initialized (check console for "Audio initialized" message)
4. Navigate through scenes (if BGM files exist, they should play)

**Expected**: Audio initializes on first click, no autoplay errors.

---

### IT-4: Focus Management Integration

**Purpose**: Verify keyboard navigation works across UI screens.

**Test Steps**:

1. Run the project
2. Use arrow keys to navigate focus on title screen
3. Press Enter to start
4. Use arrow keys to navigate character grid
5. Press Enter to select/deselect characters

**Expected**: Focus highlights move correctly, selections register.

---

### IT-5: Corps Roster Integration

**Purpose**: Verify two-phase selection works correctly.

**Test Steps**:

1. Run the project
2. Select exactly 6 characters
3. Click "Confirm Corps" → Phase 2 begins
4. Try selecting a character NOT in the corps → should be rejected
5. Select exactly 3 characters from the corps
6. Click "Deploy" → should transition to battle

**Expected**: Corps roster validates selections, invalid selections rejected.

---

## Running Tests

### Manual Testing

All tests are manual and require running the project in the Godot editor or
exported build.

### Automated Testing (Future)

When GUT (Godot Unit Test) or similar framework is added, these tests can be
automated:

```gdscript
# Example test structure (requires GUT)
func test_state_machine_transition():
    assert_eq(GameManager.current_state, GameManager.GameState.TITLE)
    GameManager.transition_to_state(GameManager.GameState.CHARACTER_SELECT)
    assert_eq(GameManager.current_state, GameManager.GameState.CHARACTER_SELECT)
```

---

## Test Results

| Test ID | Description                  | Status | Notes                        |
| ------- | ---------------------------- | ------ | ---------------------------- |
| IT-1    | State machine integration    | Manual | Requires scene files present |
| IT-2    | Save data integration        | Manual | Verify save.cfg creation     |
| IT-3    | Audio system integration     | Manual | Requires audio files         |
| IT-4    | Focus management integration | Manual | Keyboard navigation test     |
| IT-5    | Corps roster integration     | Manual | Selection validation test    |
