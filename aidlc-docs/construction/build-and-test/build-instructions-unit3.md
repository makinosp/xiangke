# Build Instructions — Unit 3: Battle System

## Overview

Build instructions for the battle system layer (Unit 3). This layer provides the
core turn-based combat logic, action execution, damage calculation, and battle
UI integration.

---

## Prerequisites

- Godot 4.x (latest stable) installed
- Export templates installed (for HTML5 export)
- Project files from Unit 1 (Resources) and Unit 2 (Game Foundation) already in
  place
- `systems/battle/` directory with all battle system scripts

---

## Build Steps

### 1. Open Project

```bash
# Open project in Godot editor
godot --path /path/to/xiangke
```

### 2. Verify Battle System Files

In Godot Editor, verify the following files exist:

| File                                    | Purpose                                                     |
| --------------------------------------- | ----------------------------------------------------------- |
| `systems/battle/battle_participant.gd`  | Runtime participant state (HP, stat stages, status effects) |
| `systems/battle/battle_state.gd`        | Battle state management (turn queue, win/loss evaluation)   |
| `systems/battle/action_system.gd`       | Damage calculation, type effectiveness, STAB, effects       |
| `systems/battle/battle_manager.gd`      | Initiative calculation, turn advancement                    |
| `systems/battle/battle_flow_service.gd` | Battle loop orchestration, AI actions, signals              |
| `scripts/foundation/battle_scene.gd`    | Battle scene UI integration (move selection, targeting)     |
| `scenes/battle_scene.tscn`              | Battle scene with HUD, action menu, battle log              |

### 3. Run in Editor

Press F5 or click "Play" to run the project.

**Expected Flow:**

1. Title screen appears
2. Click "Start" → Character select loads
3. Select 6 characters → Confirm Corps
4. Select 3 characters → Deploy
5. Battle scene loads with player and enemy participants
6. Player selects a move from the MoveContainer
7. Player selects a target from ActionContainer
8. `ActionSystem.calculate_damage()` executes:
   - Accuracy check → hit/miss
   - Damage formula: `(atk × power × 0.8) / def`
   - Type effectiveness (via `TypeChart`)
   - STAB bonus (1.2× if move type matches character type)
   - Stat stage modifiers applied
   - Random variance (0.85–1.0)
9. HP displays update, battle log shows result
10. Enemy AI takes its turn (targets weakest player, uses best move)
11. Battle continues until victory/defeat/draw (50 turns max)
12. Result screen shows outcome, save data updated

---

## Export Instructions

### HTML5 Export

```bash
# Export HTML5 build
godot --headless --export-release "HTML5" build/web/index.html
```

**Output Files:**

- `build/web/index.html`
- `build/web/index.wasm`
- `build/web/index.pck`
- `build/web/index.js`

### Desktop Export

```bash
# Export Windows build
godot --headless --export-release "Windows Desktop" build/xiangke-windows.exe

# Export macOS build
godot --headless --export-release "macOS" build/xiangke-macos.zip

# Export Linux build
godot --headless --export-release "Linux/X11" build/xiangke-linux.x86_64
```

---

## Troubleshooting

### Battle Scene Not Loading

**Error**: `Failed to load scene: res://scenes/battle_scene.tscn`

**Solution**: Verify the `.tscn` file exists and is not corrupted. Check that
the script reference in `battle_scene.tscn` points to the correct path:
`res://scripts/foundation/battle_scene.gd`.

### Type Chart Errors

**Error**: `TypeChart: invalid attacker_type X` or `invalid defender_type Y`

**Solution**: Verify that all `CharacterData` and `MoveData` `.tres` files have
valid type values (0–6 for the 7 types). Check `TypeEnums.Type` enum values.

### AI Not Acting

**Symptom**: Enemy turns skip or do nothing.

**Solution**: Verify that `BattleFlowService._get_ai_action()` can find valid
targets and moves. Check that enemy characters have at least one move with
`power > 0`.

### Damage Calculation Returns Zero

**Symptom**: All attacks deal 0 damage.

**Solution**: Check that:

1. Attacker's ATK/INT stats are > 0
2. Defender's DEF/SPI stats are not excessively high (causing rounding to 0)
3. Move power is > 0
4. Type effectiveness is not 0.0 (immunity)

### Turn Queue Stuck

**Symptom**: Battle freezes after a few turns.

**Solution**: Check that `BattleManager.advance_to_next_turn()` is being called
after each action. Verify that defeated participants are properly skipped and
that the turn queue is regenerated for new rounds.
