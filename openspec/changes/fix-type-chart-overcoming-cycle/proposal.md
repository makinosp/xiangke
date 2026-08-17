## Why

The type effectiveness matrix in the implementation does not match the spec. The
五行 (Five Elements) overcoming cycle is reversed in both the GDScript
(`scripts/type_chart.gd`) and Rust (`extensions/core/src/types.rs`)
implementations:

- Spec: Wood → Earth → Water → Fire → Metal → Wood at 2.0× (overcoming).
- Implementation: the 2.0× entries follow the _reverse_ cycle (Fire → Water →
  Earth → Wood → Metal → Fire), i.e. the "being overcome" pairs carry the 2.0×
  multiplier and the actual overcoming pairs are neutral 1.0×.

Additionally, the spec currently defines only three multipliers (1.25×
generating, 2.0× overcoming, 0.5× overcome). The implementation assigns 0.5× to
the reverse-generating pairs (e.g. Fire → Wood, since Wood generates Fire).
Design decision: these reverse-generating pairs (子盗母気, "the child drains the
mother") are intentionally strong and SHALL be 2.0×. The spec needs to be
extended to define this fourth relationship.

## What Changes

- Correct the 5×5 五行 block of the type chart so that the overcoming cycle Wood
  → Earth → Water → Fire → Metal → Wood is 2.0×.
- Make the reverse-generating pairs (the reverse of the generating cycle) 2.0×:
  Fire → Wood, Earth → Fire, Metal → Earth, Water → Metal, Wood → Water.
- Keep generating pairs at 1.25× (Wood → Fire, Fire → Earth, Earth → Metal,
  Metal → Water, Water → Wood).
- Keep "being overcome" pairs at 0.5× (reverse of the overcoming cycle).
- Update the domain spec to define the reverse-generating (子盗母気)
  relationship at 2.0×.
- Update all unit, integration, and proptest expectations in GDScript and Rust
  that encode the old (reversed) chart, and the validator checks if needed.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `domain`: Extend the Type Effectiveness requirement to define the
  reverse-generating relationship (2.0×) and clarify the full 五行 cycles.

## Impact

- `openspec/specs/domain/spec.md` — updated via delta spec.
- `scripts/type_chart.gd` — TYPE_CHART 5×5 block values.
- `extensions/core/src/types.rs` — `TypeChart::default()` matrix, doc comment,
  and unit tests.
- `extensions/core/src/proptests.rs` — expectations if they encode old values.
- `extensions/core/tests/integration.rs` — `test_type_chart_character_scenario`.
- `extensions/battle/tests/integration.rs` — dual-type and Wood-vs-Metal
  scenarios that assume the old chart.
- `extensions/battle/src/action.rs`, `extensions/battle/src/flow.rs` — inline
  comments and test expectations referencing matchups.
- `tests/unit/test_type_chart.gd` — GDScript unit test expectations.
- Gameplay balance: elements now have exactly two 2.0× matchups (overcoming
  target + generating source), one 1.25× matchup (generating target), one 0.5×
  matchup (being overcome), and one 1.0× self. The previously dominant "Wood
  beats Metal" assumption in tests flips to "Metal beats Wood".
