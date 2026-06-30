# Integration Test Instructions

## Purpose

Test interactions between the data layer (Unit 1) and future game systems to
ensure the data contracts are correctly implemented and accessible.

## Current Scope

Since only Unit 1 (Resources) is implemented, integration tests focus on
verifying that the `DataRegistry` autoload provides correct data access patterns
that future units (Game Foundation, Battle System, AI System) will use.

## Test Scenarios

### Scenario 1: DataRegistry → Character Lookup

**Description**: Verify that character data can be retrieved by ID with all
properties intact.

**Setup**: Project loaded with sample data (3 characters).

**Test Steps**:

1. Open Godot Editor, press F5 to run
2. In the Debugger → Monitors, check `DataRegistry.get_character("zhuge_liang")`
3. Verify returned object has expected properties:
   - `id` == `"zhuge_liang"`
   - `name` == `"諸葛亮"`
   - `type` == `TypeEnums.Type.WOOD` (0)
   - `secondary_type` == `TypeEnums.Type.WATER` (4)
   - `hp` == `85`
   - `moves.size()` == `4`

**Expected Results**: All properties match the `.tres` file values.

---

### Scenario 2: DataRegistry → Move Lookup

**Description**: Verify that move data can be retrieved by ID.

**Test Steps**:

1. Check `DataRegistry.get_move("fire_strike")`
2. Verify returned object:
   - `id` == `"fire_strike"`
   - `type` == `TypeEnums.Type.FIRE` (1)
   - `power` == `80`
   - `effect` == `TypeEnums.EffectType.BURN` (1)
   - `effect_chance` == `30`

**Expected Results**: All properties match the `.tres` file values.

---

### Scenario 3: Type Effectiveness Resolution

**Description**: Verify that `TypeChart.resolve_type_effectiveness()` returns
correct multipliers for single-type and dual-type defenders.

**Test Steps**:

1. Fire move (type=FIRE) vs Wood defender (single type):
   ```
   TypeChart.resolve_type_effectiveness(FIRE, WOOD, -1)
   ```
   Expected: `0.5` (Fire is overcome by Wood / 被相克)

2. Fire move vs Wood+Earth defender (dual type):
   ```
   TypeChart.resolve_type_effectiveness(FIRE, WOOD, EARTH)
   ```
   Expected: `0.5 * 1.25 = 0.625`

3. Yang move vs Yin defender:
   ```
   TypeChart.resolve_type_effectiveness(YANG, YIN, -1)
   ```
   Expected: `2.0` (super effective)

**Expected Results**: All multipliers match the type chart matrix in
`scripts/type_chart.gd`.

---

### Scenario 4: DataRegistry Convenience Method

**Description**: Verify `get_type_effectiveness_against()` combines move lookup
with type resolution.

**Test Steps**:

1. Call
   `DataRegistry.get_type_effectiveness_against("fire_strike", "zhuge_liang")`
   - Fire strike (FIRE) vs Zhuge Liang (Wood/Water)
   - Expected: `0.5 * 1.0 = 0.5`

2. Call `DataRegistry.get_type_effectiveness_against("metal_slash", "guan_yu")`
   - Metal slash (METAL) vs Guan Yu (Metal, single type)
   - Expected: `1.0` (neutral, same type)

**Expected Results**: Correct combined lookup and resolution.

---

### Scenario 5: Batch Validation Integration

**Description**: Verify that `DataValidator.validate_all()` correctly validates
the entire dataset.

**Test Steps**:

1. Run project in headless mode:
   ```bash
   godot --headless --path /path/to/xiangke --quit
   ```
2. Check output for validation summary

**Expected Results**: "All data loaded and validated successfully" with 0
errors.

---

## Setup Integration Test Environment

No additional services required. All tests run within the Godot editor or via
Godot CLI in headless mode.

## Cleanup

No cleanup needed. Tests are read-only and do not modify data files.
