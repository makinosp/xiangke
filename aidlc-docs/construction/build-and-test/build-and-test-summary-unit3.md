# Build and Test Summary — Unit 3: Battle System

## Overview

This document summarizes the build and test instructions for Unit 3: Battle
System. It provides a quick reference for building, testing, and validating the
battle system layer.

---

## Build Instructions

| Document                      | Location                                  | Purpose                                                          |
| ----------------------------- | ----------------------------------------- | ---------------------------------------------------------------- |
| `build-instructions-unit3.md` | `aidlc-docs/construction/build-and-test/` | Step-by-step build and export instructions for the battle system |

**Key Steps:**

1. Open project in Godot editor
2. Verify all battle system files exist (`systems/battle/` and
   `scripts/foundation/battle_scene.gd`)
3. Run in editor (F5) to verify the full battle loop
4. Export HTML5/Desktop builds using Godot CLI commands

---

## Unit Tests

| Document                          | Location                                  | Purpose                                                 |
| --------------------------------- | ----------------------------------------- | ------------------------------------------------------- |
| `unit-test-instructions-unit3.md` | `aidlc-docs/construction/build-and-test/` | 14 unit test scenarios for individual battle components |

**Test Coverage:**

- **UT-1**: BattleParticipant creation & validation (assert-based fail-fast)
- **UT-2**: Stat stage modifiers (clamping to [-6, +6], multiplier calculation)
- **UT-3**: Basic physical damage formula (ATK vs DEF)
- **UT-4**: Arts damage formula (INT vs SPI)
- **UT-5**: Super-effective type matchup (2.0× multiplier)
- **UT-6**: Not-very-effective type matchup (0.5× multiplier)
- **UT-7**: Dual-type effectiveness (primary × secondary, clamped to [0.25,
  4.0])
- **UT-8**: STAB (1.2× bonus when move type matches character type)
- **UT-9**: Accuracy check (miss rate verification)
- **UT-10**: Recoil damage (25% of damage dealt back to attacker)
- **UT-11**: Healing moves (HP restoration capped at max_hp)
- **UT-12**: BattleState win/loss/draw evaluation (VICTORY, DEFEAT, DRAW)
- **UT-13**: BattleManager turn queue (speed-based descending order)
- **UT-14**: Skip defeated participants from turn queue

---

## Integration Tests

| Document                                 | Location                                  | Purpose                                                       |
| ---------------------------------------- | ----------------------------------------- | ------------------------------------------------------------- |
| `integration-test-instructions-unit3.md` | `aidlc-docs/construction/build-and-test/` | 10 integration test scenarios for full battle system behavior |

**Test Coverage:**

- **IT-1**: Full battle loop (player vs enemy, start to victory/defeat)
- **IT-2**: Type effectiveness integration (五行 cycle in real battle)
- **IT-3**: STAB integration (same-type attack bonus in combat)
- **IT-4**: Stat stage modification persistence across turns
- **IT-5**: AI action selection (weakest target, best move scoring)
- **IT-6**: Turn order recalculation each round (speed-based)
- **IT-7**: Battle end conditions (victory, defeat, draw at 50 turns)
- **IT-8**: Save data integration (battle result persistence)
- **IT-9**: UI integration (move selection, targeting, cancel/wait)
- **IT-10**: Battle log integration (action result display)

---

## Performance Tests

| Document                                 | Location                                  | Purpose                                                |
| ---------------------------------------- | ----------------------------------------- | ------------------------------------------------------ |
| `performance-test-instructions-unit3.md` | `aidlc-docs/construction/build-and-test/` | 8 performance test scenarios for battle system metrics |

**Performance Targets:**

- **PT-1**: Turn processing <100ms per turn (including AI)
- **PT-2**: Damage calculation <10ms per action
- **PT-3**: Battle scene load time <500ms
- **PT-4**: Frame rate ≥30 FPS (Web), ≥60 FPS (Desktop)
- **PT-5**: Memory usage <10MB during battle
- **PT-6**: Animation pacing 0.5–1s per action
- **PT-7**: Turn queue calculation <5ms (O(n log n) sort)
- **PT-8**: Type chart lookup <0.1ms (O(1) array access)

---

## Running All Tests

### Quick Start (Manual Testing)

1. Open project in Godot editor: `godot --path /path/to/xiangke`
2. Press F5 to run the project
3. Navigate through: Title → Character Select → Deploy → Battle Scene
4. Execute actions and verify behavior matches test scenarios above

### Automated Testing (Headless Mode)

```bash
# Run unit tests
godot --headless --path /path/to/xiangke --script tests/battle_unit_tests.gd --quit

# Run performance tests
godot --headless --path /path/to/xiangke --script tests/battle_perf_tests.gd --quit
```

### Export Testing (Web)

```bash
# Build HTML5 export
godot --headless --export-release "HTML5" build/web/index.html

# Open in browser and test with dev tools for FPS, memory, load time
```

---

## Test Status Summary

| Category          | Tests | Status                                                |
| ----------------- | ----- | ----------------------------------------------------- |
| Unit Tests        | 14    | ✅ All scenarios documented, ready for execution      |
| Integration Tests | 10    | ✅ All scenarios documented, ready for manual testing |
| Performance Tests | 8     | ✅ All scenarios documented, targets defined          |

---

## Next Steps

1. **Manual Testing**: Run through all integration test scenarios in Godot
   editor
2. **Automated Testing**: Create test scripts for unit and performance tests
   (optional)
3. **Export Testing**: Build HTML5 export and verify Web-specific requirements
4. **Bug Fixing**: Address any issues found during testing

---

## References

- Functional Design: `aidlc-docs/construction/unit-3/functional-design/`
- NFR Requirements: `aidlc-docs/construction/unit-3/nfr-requirements/`
- NFR Design: `aidlc-docs/construction/unit-3/nfr-design/`
- Code Generation Plan:
  `aidlc-docs/construction/unit-3/plans/code-generation-plan.md`
- Generated Code: `systems/battle/`, `scripts/foundation/battle_scene.gd`
