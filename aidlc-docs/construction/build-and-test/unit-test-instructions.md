# Unit Test Execution

## Testing Approach

This project uses GDScript's built-in `assert()` statements and Godot's
command-line headless mode for automated validation. GDScript does not have a
standard xUnit-style test framework, but the `DataValidator` class provides
comprehensive data validation that serves as the primary automated test.

## Run Data Validation Tests

### 1. Execute Validation via Godot CLI

```bash
# Run the project in headless mode to trigger DataRegistry._ready() validation
godot --headless --path /path/to/xiangke --quit
```

**Expected Output:**

```
DataRegistry: All data loaded and validated successfully.
  Characters: 3 | Moves: 7
```

### 2. Manual Validation Test Cases

The following test scenarios are covered by `DataValidator.validate_all()`:

| Test Case                 | Rule Code | Description                                           |
| ------------------------- | --------- | ----------------------------------------------------- |
| Valid character ID format | CR-1      | ID must be lowercase snake_case                       |
| Character name length     | CR-1      | Name must be 1-20 characters                          |
| Stat range validation     | CR-2      | All stats must be in [1, 999]                         |
| Stat maximum cap          | CR-2      | No single stat exceeds 500                            |
| Stat sum constraint       | CR-2      | Total stats must not exceed 3000                      |
| Primary type validity     | CR-3      | Must be one of 7 valid types                          |
| Secondary type differs    | CR-3      | Secondary must differ from primary                    |
| Move count                | CR-4      | Exactly 4 moves per character                         |
| Move existence            | CR-4      | All move IDs must exist in registry                   |
| Damaging move present     | CR-4      | At least one move with power > 0                      |
| Move ID format            | MR-1      | ID must be lowercase snake_case                       |
| Move power range          | MR-2      | Power must be in [0, 255]                             |
| Move accuracy range       | MR-2      | Accuracy must be in [1, 100]                          |
| Effect consistency        | MR-3      | Effect chance must match effect type                  |
| Stat mod range            | MR-4      | Stage must be in [-3, 3]                              |
| Hit count range           | MR-5      | Hit count must be in [1, 5]                           |
| Recoil requires damage    | MR-6      | Recoil requires power > 0                             |
| Healing range             | MR-7      | Healing must be in [0, 100]                           |
| Type chart dimensions     | TR-1      | Chart must be 7×7                                     |
| Diagonal constraints      | TR-2      | No self-immunity or self-super-effective              |
| Yin-Yang mutual           | TR-2      | Yang/Yin super effective against each other           |
| Yin-Yang neutral vs 五行  | TR-2      | Yin/Yang neutral against 五行 types                   |
| Cycle compliance          | TR-3      | Each type has exactly 1 super/generating/weak matchup |

### 3. Type Chart Verification

```bash
# Verify type chart correctness via Godot script execution
godot --headless --path /path/to/xiangke --script scripts/type_chart.gd --quit
```

**Expected:** No errors. The `TypeChart` class validates its own matrix
structure at load time.

### 4. Graceful Degradation Test

To test the placeholder fallback (NFR pattern RP-1):

1. Temporarily rename a `.tres` file (e.g., `zhuge_liang.tres` →
   `zhuge_liang.tres.bak`)
2. Run the project — should see a warning but not crash
3. Restore the file

**Expected Output:**

```
DataLoader: Character not found: zhuge_liang
```

## Review Test Results

- **Expected**: 0 validation errors, 0 warnings (with sample data)
- **Test Report Location**: Godot Output panel / terminal stdout
- **Coverage**: All business rules (CR-1 through MR-7, TR-1 through TR-3)

## Fix Failing Tests

If validation errors occur:

1. Check the error code (e.g., `[CR-2]`, `[MR-3]`)
2. Refer to `aidlc-docs/construction/unit-1/functional-design/business-rules.md`
   for the rule definition
3. Fix the offending `.tres` file property
4. Re-run validation
