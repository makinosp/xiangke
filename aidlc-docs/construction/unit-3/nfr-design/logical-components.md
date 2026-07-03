# Logical Components — Unit 3: Battle System

This document describes the logical components and infrastructure elements used
to implement the NFR design for the Battle System.

## 1. Core Components

### 1.1 BattleStateManager

**Purpose**: Centralized management of battle state with validation capabilities
**Responsibilities**:

- Maintain the single source of truth for all battle data
- Provide thread-safe (in GDScript context) access to battle state
- Implement pre-action and post-action validation
- Notify listeners of state changes via signals **NFR Addressed**:
- NFR-3.2 (Battle state integrity)
- NFR-6.1 (Code modularity) **Implementation**:

```gdscript
# Pseudocode structure
class BattleStateManager:
    signal state_changed
    signal validation_failed(message)
    
    var _state: BattleState
    
    function validate_state() -> bool:
        # Implement NFR-3.2 validation logic
        pass
        
    function apply_action(action: Action) -> bool:
        # Pre-action validation
        if not _validate_pre_action(action):
            return false
            
        # Apply action
        _state = _action_system.execute(action, _state)
        
        # Post-action validation
        if not _validate_post_action():
            # Rollback or handle corruption
            return false
            
        emit_signal("state_changed", _state)
        return true
```

### 1.2 PerformanceMonitor

**Purpose**: Monitor and enforce performance budgets **Responsibilities**:

- Track execution time of critical paths (damage calculation, turn processing)
- Alert when performance thresholds are exceeded
- Provide profiling data for optimization **NFR Addressed**:
- NFR-1.1 (Battle turn processing time)
- NFR-1.3 (Damage calculation time) **Implementation**:

```gdscript
# Pseudocode structure
class PerformanceMonitor:
    var frame_times: Array[float] = []
    var action_times: Dictionary[String, float] = {}
    
    function begin_timing(label: String):
        # Start timer for labeled operation
        pass
        
    function end_timing(label: String):
        # End timer and record duration
        # Alert if exceeds threshold
        pass
        
    function get_average_fps() -> float:
        # Calculate FPS from frame times
        pass
```

### 1.3 AnimationManager

**Purpose**: Centralized management of battle animations with timing control
**Responsibilities**:

- Queue and sequence animations
- Ensure animations complete within time budgets (0.5-1.0s)
- Provide callbacks for animation completion
- Manage animation resource pooling **NFR Addressed**:
- NFR-1.2 (Animation frame rate)
- NFR-7.1 (Animation speed) **Implementation**:

```gdscript
# Pseudocode structure
class AnimationManager:
    var _queue: Array[AnimationJob] = []
    var _is_playing: bool = false
    
    function play_animation(animation: AnimationJob):
        # Add to queue, play immediately if idle
        pass
        
    function _on_animation_complete():
        # Process next in queue
        pass
        
    function set_speed_factor(factor: float):
        # Adjust all animation speeds
        pass
```

### 1.4 DebugConsole

**Purpose**: Provide real-time battle calculation visibility
**Responsibilities**:

- Display detailed calculation breakdowns
- Toggle visibility via input
- Update with minimal performance impact
- Show battle state, action details, and formulas **NFR Addressed**:
- NFR-9.1 (Battle log with calculation breakdown) **Implementation**:

```gdscript
# Pseudocode structure
class DebugConsole(Node):
    @onready var _panel: PanelContainer = $PanelContainer
    @onready var _text: RichTextLabel = $PanelContainer/VBoxContainer/RichTextLabel
    
    var _is_visible: bool = false
    var _last_update_time: float = 0
    
    function _input(event):
        if event.is_action_pressed("ui_debug_toggle"):
            toggle_visibility()
            
    function show_calculation(action: Action, details: Dictionary):
        # Format and display calculation details
        # Update at most 10-15 times per second
        pass
        
    function toggle_visibility():
        _is_visible = not _is_visible
        _panel.visible = _is_visible
```

### 1.5 ResourceValidator

**Purpose**: Validate game resources at load time **Responsibilities**:

- Validate .tres resources for correctness
- Check for missing references or invalid values
- Provide clear error messages for missing data **NFR Addressed**:
- NFR-3.1 (Error handling with clear messages)
- NFR-5.1 (Data validation) **Implementation**:

```gdscript
# Pseudocode structure
class ResourceValidator:
    function validate_character_data(resource: CharacterData) -> Array[String]:
        # Return list of validation errors
        var errors = []
        if not resource:
            errors.append("Character data is null")
            return errors
            
        if resource.max_hp <= 0:
            errors.append("Character %s has invalid max HP: %d" % [resource.name, resource.max_hp])
            
        # Validate moves, types, stats, etc.
        return errors
        
    function validate_move_data(resource: MoveData) -> Array[String]:
        # Similar validation for moves
        pass
```

### 1.6 TurnScheduler

**Purpose**: Efficiently manage turn order based on speed stats
**Responsibilities**:

- Calculate initiative scores for participants
- Maintain sorted turn queue
- Handle turn progression and round boundaries
- Recalculate order when speed stats change **NFR Addressed**:
- NFR-3.3 (Turn queue consistency)
- NFR-1.1 (Battle turn processing time) **Implementation**:

```gdscript
# Pseudocode structure
class TurnScheduler:
    var _participants: Array[BattleParticipant] = []
    var _turn_queue: Array[BattleParticipant] = []
    var _current_index: int = 0
    
    function update_participant_speed(participant: BattleParticipant):
        # Recalculate initiative and re-sort if needed
        # For 1v1, simple comparison is sufficient
        pass
        
    function get_next_participant() -> BattleParticipant:
        # Return next participant or None if round complete
        pass
        
    def is_round_complete() -> bool:
        # Check if all participants have had a turn
        pass
```

## 2. Infrastructure Elements

### 2.1 Signal Bus

**Purpose**: Decoupled communication between systems **Implementation**: Godot's
built-in signal system **Usage**:

- BattleStateManager emits `state_changed`
- AnimationManager emits `animation_completed`
- DamageSystem emits `damage_dealt`
- UI systems listen to relevant signals **NFR Addressed**:
- NFR-6.1 (Code modularity)
- NFR-6.2 (Maintainability through loose coupling)

### 2.2 Object Pool (Optional)

**Purpose**: Reduce allocation overhead for frequent objects **Consideration**:
Only implement if profiling shows allocation pressure **Application**:

- Action objects (created/destroyed each turn)
- Temporary calculation objects
- Animation job objects **NFR Addressed**:
- NFR-2.2 (Memory usage per battle)
- NFR-3.2 (Performance consistency)

### 2.3 Configuration Manager

**Purpose**: Centralized configuration for tuning NFR parameters
**Responsibilities**:

- Store performance thresholds
- Animation timing configurations
- Debug console settings
- Enable/disable features based on build type **NFR Addressed**:
- All NFRs (through centralized configurability) **Implementation**:

```gdscript
# Pseudocode structure
class BattleConfig:
    # Performance thresholds
    const MAX_TURN_TIME_MS: float = 100.0
    const MAX_DAMAGE_CALC_TIME_MS: float = 10.0
    const MIN_FPS: float = 30.0
    
    # Animation settings
    const MIN_ANIMATION_TIME: float = 0.5
    const MAX_ANIMATION_TIME: float = 1.0
    
    # Debug settings
    const DEBUG_UPDATE_FPS: float = 10.0
    
    # Feature flags
    const ENABLE_DEBUG_CONSOLE: bool = true  # Set false in release builds
```

## 3. Component Interaction Patterns

### 3.1 Data Flow

```
[Input System] → [BattleStateManager] → [ActionSystem] 
                    ↓              ↓              ↓
            [TurnScheduler]  [DamageCalc]   [StatusEffectSys]
                    ↓              ↓              ↓
            [AnimationManager] ← [Validation] → [ResourceMgr]
                    ↓
              [Render/Update Loop]
```

### 3.2 Event Flow

```
Action Requested
    ↓
BattleStateManager.validate_pre_action()
    ↓
ActionSystem.execute()
    ↓
BattleStateManager.apply_state_changes()
    ↓
[DamageCalc/StatusEffectSys] → BattleStateManager
    ↓
AnimationManager.queue_animations()
    ↓
[Each Animation] → AnimationManager.on_complete()
    ↓
TurnScheduler.advance_turn()
    ↓
BattleStateManager.check_win_conditions()
    ↓
[Repeat or End Battle]
```

### 3.3 Update Loop Integration

```
_main_process(delta):
    PerformanceMonitor.begin_timing("frame")
    
    # Process input
    InputHandler.process()
    
    # Update battle state if not waiting for animation
    if not AnimationManager.is_busy():
        BattleStateManager.update()
        
    # Update animations
    AnimationManager.update(delta)
    
    # Update debug console (throttled)
    DebugConsole.update_if_needed(delta)
    
    PerformanceMonitor.end_timing("frame")
    PerformanceMonitor.check_budget()
```

## 4. Scalability Considerations

### 4.1 Current Design (1v1 Focus)

- TurnScheduler uses simple comparison (O(1))
- BattleStateManager stores only 2 participants
- AnimationManager handles limited concurrent animations
- Memory footprint predictable and small

### 4.2 Extension Paths for Larger Battles

- Replace simple comparison with priority queue for turn ordering
- Implement object pooling for Action and StatusEffect instances
- Add animation culling for off-screen or low-priority effects
- Consider spatial partitioning for range-based attacks (if needed later)

## 5. Deployment Considerations

### 5.1 Web Platform Optimization

- Minimize DOM updates (use CanvasLayer for UI)
- Optimize JavaScript export settings
- Preload critical resources
- Use compressed textures where possible

### 5.2 Development vs Production Builds

- DebugConsole enabled only in debug builds
- Assertions active in debug, stripped in release
- Logging level configurable per build type
- Performance monitoring more verbose in development

---
