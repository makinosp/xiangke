## Why

The codebase has already migrated from "STAB" (Same-Type Attack Bonus) to "type
match" terminology in most Rust code, but several remnants remain: a historical
comment in `action.rs`, a GDScript test name that conflates "same type" with
type effectiveness, and the domain spec lacks documentation of the 1.5× type
match multiplier. This change completes the terminology cleanup so the codebase
consistently uses "type match" and the spec documents the mechanic.

## What Changes

- Remove the "formerly known as STAB" historical reference from the
  `is_type_matched` doc comment in `extensions/battle/src/action.rs`.
- Rename `test_same_type_is_neutral` to
  `test_same_type_effectiveness_is_neutral` in `tests/unit/test_type_chart.gd`
  to disambiguate it from the STAB/type-match concept.
- Add a "Type Match Bonus" requirement to the domain spec documenting the 1.5×
  multiplier when attacker element matches move element.
- Expose `is_type_matched` in the GDExtension bridge's `result_dict()` so
  GDScript can display type-match feedback to the player.

## Capabilities

### New Capabilities

None. This is a terminology cleanup and spec documentation change with no new
behavior.

### Modified Capabilities

- `domain`: Add a "Type Match Bonus" requirement documenting the 1.5× multiplier
  when the attacker's element matches the move's element.

## Impact

- `extensions/battle/src/action.rs`: Update doc comment on `is_type_matched` to
  remove STAB historical reference.
- `tests/unit/test_type_chart.gd`: Rename test function for clarity.
- `openspec/specs/domain/spec.md`: Add type match bonus requirement.
- `extensions/godot_bridge/src/lib.rs`: Add `is_type_matched` field to
  `result_dict()` output.
