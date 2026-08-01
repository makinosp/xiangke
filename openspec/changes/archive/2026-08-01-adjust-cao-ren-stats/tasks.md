## 1. Stat Adjustment

- [x] 1.1 Edit `resources/characters/cao_ren.tres`: set `hp = 70` and
      `defense = 180`, keeping all other fields unchanged

## 2. Verification

- [x] 2.1 Confirm stat sum is still 575 and all stats remain in [1, 500]
- [x] 2.2 Run `godot --headless res://tests/test_runner.tscn` and confirm no
      validation errors and tests pass
