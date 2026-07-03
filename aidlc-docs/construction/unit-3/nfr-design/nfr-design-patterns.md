# NFR Design Patterns — Unit 3: Battle System

This document describes the design patterns used to address non-functional
requirements for the Battle System.

## 1. Performance Optimization Patterns

### 1.1 Efficient Data Structures

- **Pattern**: Use Godot's built-in typed arrays and dictionaries for battle
  state storage
- **Application**:
  - Store BattleParticipant stats in typed arrays for fast access
  - Use dictionaries with enum keys for status effect tracking
  - Pre-allocate fixed-size arrays for turn queue (max 2 participants)

### 1.2 Algorithm Optimization

- **Pattern**: Optimize damage calculation with lookup tables and minimized
  branching
- **Application**:
  - Pre-compute 五行 type effectiveness matrix as a constant 2 lookup table
  - Use bit flags for status effect combinations where applicable
  - Minimize function calls in hot paths (damage calculation, turn processing)

### 1.3 Caching Strategy

- **Pattern**: Cache expensive calculations that don't change frequently
- **Application**:
  - Cache character's effective stats (base + stages) until they change
  - Cache move power calculations for repeated use in same turn
  - Invalidate caches when stats or equipment change

## 2. Error Handling Patterns

### 2.1 Fail-Fast with Assertions

- **Pattern**: Use GDScript's `assert()` function for development-time
  validation
- **Application**:
  - Validate BattleState integrity before each action
  - Check move data validity before execution
  - Verify target validity in targeting systems
  - Example:
    `assert(participant.current_hp >= 0, "Invalid HP value: " + str(participant.current_hp))`

### 2.2 Defensive Input Validation

- **Pattern**: Validate all external inputs at system boundaries
- **Application**:
  - Validate move data loaded from .tres resources
  - Check AI controller responses for valid actions
  - Validate UI input before processing
  - Return early with error logging for invalid inputs

### 2.3 Error Logging

- **Pattern**: Centralized error logging with context information
- **Application**:
  - Log errors with timestamp, battle state snapshot, and stack trace
  - Include participant IDs and move names in error messages
  - Log to console for development visibility

## 3. Memory Management Patterns

### 3.1 Object Lifecycle Management

- **Pattern**: Short-lived objects for battle-scoped data
- **Application**:
  - BattleState created at battle start, destroyed at battle end
  - Action objects created per turn, discarded after execution
  - StatusEffect instances created when applied, removed when expired
  - Rely on GDScript's garbage collection for cleanup

### 3.2 Memory-Efficient Data Storage

- **Pattern**: Use appropriate data types and avoid unnecessary duplication
- **Application**:
  - Use `int` for HP/MP values instead of `float` where fractional values not
    needed
  - Store references to resources rather than duplicating data
  - Use PackedScene for instantiating battle UI elements
  - Minimize use of large arrays or dictionaries that grow unbounded

## 4. Animation System Patterns

### 4.1 Tween-Based Timing

- **Pattern**: Use Godot's Tween node for precise, timed animations
- **Application**:
  - Create Tween nodes for each action animation (damage numbers, status
    effects)
  - Set duration between 0.5-1.0 seconds per NFR-7.1
  - Use callback functions to trigger next animation or end turn
  - Reuse Tween nodes through object pooling to reduce allocation

### 4.2 Animation Sequencing

- **Pattern**: Chain animations using Tween callbacks
- **Application**:
  - Damage number appears → hits target → fades out
  - Status effect icon appears → pulses → settles
  - Each animation triggers the next in sequence
  - Total sequence time stays within 0.5-1.0 second range

### 4.3 Performance Considerations

- **Pattern**: Limit concurrent animations to maintain frame rate
- **Application**:
  - Queue animations if system is busy
  - Simplify animations when many effects occur simultaneously
  - Use LOD (Level of Detail) approach for complex battles (though not needed
    for 1v1)

## 5. Debug Console Patterns

### 5.1 Toggleable Debug Panel

- **Pattern**: UI panel that can be shown/hidden via input
- **Application**:
  - Create a CanvasLayer-based panel that overlays the battle scene
  - Bind to a debug key (e.g., F12 or Ctrl+D) for toggling
  - Start hidden by default,可显示时显示
  - Semi-transparent background to see battle underneath

### 5.2 Real-Time Calculation Display

- **Pattern**: Update display values each frame during calculations
- **Application**:
  - Show base stats, stage modifiers, final values
  - Display type effectiveness multipliers
  - Show STAB and field effect modifiers
  - Display random variance roll and final damage/healing amount
  - Update only when values change to reduce CPU usage

### 5.3 Performance-Friendly Implementation

- **Pattern**: Minimize debug console impact on performance
- **Application**:
  - Only update visible elements
  - Use string buffering to reduce string concatenation
  - Limit update frequency to 10-15 FPS when visible
  - Allow configuration of detail level (minimal/normal/verbose)

## 6. State Validation Patterns

### 6.1 Pre-Action Validation

- **Pattern**: Validate state before allowing action execution
- **Application**:
  - Check participant has sufficient MP for move
  - Verify move is not on cooldown (if applicable)
  - Confirm target is valid and in range
  - Ensure BattleState is internally consistent
  - Return early with specific error if validation fails

### 6.2 Post-Action Validation

- **Pattern**: Validate state after action execution to detect corruption
- **Application**:
  - Verify HP/MP values are within valid bounds
  - Check that status effect durations are non-negative
  - Ensure turn queue still contains all active participants
  - Confirm no participant has invalid stat stage values
  - Log warnings for any inconsistencies found

### 6.3 Centralized Validation Functions

- **Pattern**: Create reusable validation functions
- **Application**:
  - `validate_battle_state()` - comprehensive state check
  - `validate_participant(participant)` - individual participant check
  - `validate_action(action)` - action-specific validation
  - Call these at key points in battle flow

## 7. Turn Flow Optimization Patterns

### 7.1 Efficient Turn Queue Management

- **Pattern**: Maintain sorted turn queue with minimal re-sorting
- **Application**:
  - Calculate initiative scores once per round
  - Insert participants into correct position using insertion sort (efficient
    for small n)
  - Only re-sort when speed stats actually change
  - For 1v1 battles, simple comparison is sufficient

### 7.2 State Change Minimization

- **Pattern**: Only update what has actually changed
- **Application**:
  - Track which stats changed during an action
  - Only recalculate derived values when base stats change
  - Update UI elements only when their values change
  - Avoid unnecessary node property changes that trigger expensive updates

---
