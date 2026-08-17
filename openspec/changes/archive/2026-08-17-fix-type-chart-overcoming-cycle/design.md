## Context

The type chart lives in two places that must stay in sync:

- `scripts/type_chart.gd` — `const TYPE_CHART: Array` (7×7, row = defender,
  column = attacker). Used by `TypeChart.new().resolve_type_effectiveness(...)`
  in the GDScript battle UI and by the data validator.
- `extensions/core/src/types.rs` — `impl Default for TypeChart` (7×7 f64,
  `chart[defender][attacker]`). This is the authoritative chart used by the Rust
  battle engine (`extensions/battle`).

The current 5×5 五行 block (row = defender, col = attacker):

```
              atk: WOOD FIRE EARTH METAL WATER
def WOOD :   [ 1.0, 0.5, 2.0, 1.0, 1.25 ]
def FIRE :   [ 1.25, 1.0, 0.5, 2.0, 1.0 ]
def EARTH:   [ 1.0, 1.25, 1.0, 0.5, 2.0 ]
def METAL:   [ 2.0, 1.0, 1.25, 1.0, 0.5 ]
def WATER:   [ 0.5, 2.0, 1.0, 1.25, 1.0 ]
```

Reading `effectiveness(attacker, defender) = chart[defender][attacker]`, the
current 2.0× entries are: Fire→Water, Water→Earth, Earth→Wood, Wood→Metal,
Metal→Fire — the _reverse_ of the spec's overcoming cycle.

The spec (`openspec/specs/domain/spec.md`) requires:

- Generating (相生): attacker generates defender, e.g. Wood → Fire = 1.25×.
- Overcoming (相克): attacker overcomes defender, e.g. Wood → Earth = 2.0×.
- Overcome (被克): attacker is overcome by defender, e.g. Earth → Wood = 0.5×.
- Dual-type: multiply, clamp to [0.25, 4.0].

## Goals / Non-Goals

**Goals:**

- Make the implementation match the spec's overcoming cycle: Wood → Earth →
  Water → Fire → Metal → Wood at 2.0×.
- Add the reverse-generating relationship (子盗母気) at 2.0× and document it in
  the spec.
- Keep generating at 1.25× and being-overcome at 0.5×.
- Keep both GDScript and Rust charts identical.
- Update every test/comment that encodes the old chart.

**Non-Goals:**

- Changing the 陰陽 (Yang/Yin) block (already correct: Yang↔Yin mutual 2.0×,
  neutral to all 五行).
- Changing the dual-type clamping rules ([0.25, 4.0]).
- Renaming type enums or reordering the matrix axes.
- Rebalancing character/move data (only the chart and its tests change).

## Decisions

### D1: Target matrix

New 5×5 五行 block (row = defender, col = attacker):

```
              atk: WOOD FIRE EARTH METAL WATER
def WOOD :   [ 1.0, 2.0, 0.5, 2.0, 1.25 ]
def FIRE :   [ 1.25, 1.0, 2.0, 0.5, 2.0 ]
def EARTH:   [ 2.0, 1.25, 1.0, 2.0, 0.5 ]
def METAL:   [ 0.5, 2.0, 1.25, 1.0, 2.0 ]
def WATER:   [ 2.0, 0.5, 2.0, 1.25, 1.0 ]
```

Derived relationships (effectiveness(attacker, defender)):

- Overcoming 2.0×: Wood→Earth, Earth→Water, Water→Fire, Fire→Metal, Metal→Wood
  (matches the spec and the requested cycle).
- Reverse-generating 2.0× (子盗母気): Fire→Wood, Earth→Fire, Metal→Earth,
  Water→Metal, Wood→Water (the reverse of the generating cycle; the child drains
  the mother).
- Generating 1.25×: Wood→Fire, Fire→Earth, Earth→Metal, Metal→Water, Water→Wood
  (unchanged).
- Being overcome 0.5×: Earth→Wood, Water→Earth, Fire→Water, Metal→Fire,
  Wood→Metal (reverse of overcoming).
- Self: 1.0×. Yang/Yin block unchanged.

Every element now has exactly two 2.0× matchups, one 1.25×, one 0.5×, and one
1.0× (self). The chart is asymmetric in the generating direction (Wood→Fire is
1.25× but Fire→Wood is 2.0×), which is the intended 子盗母気 design.

Rationale: follows the spec's overcoming cycle, encodes the user's design
decision that reverse-generating is strong (2.0×), and keeps the chart
consistent with traditional 五行 theory.

### D2: Spec delta

Modify `Requirement: Type Effectiveness` in `openspec/specs/domain/spec.md` to:

- List four multipliers: generating 1.25×, overcoming 2.0×, overcome 0.5×,
  reverse-generating 2.0×.
- Add a scenario for the reverse-generating cycle with concrete examples.
- Clarify the full cycles (all five edges, not just one example).

No new capability is created; the change is a MODIFIED requirement in the
existing `domain` capability.

### D3: Source of truth and sync

`extensions/core/src/types.rs` remains the authoritative implementation (the
Rust battle engine consumes it); `scripts/type_chart.gd` is the GDScript mirror
used by UI and validation. Both must be updated in the same change and kept
identical. Add/adjust a validator check (Rust `validate_type_chart` and GDScript
`_validate_type_chart`) that asserts the overcoming edges are 2.0× so the
reversed-cycle bug cannot silently regress.

### D4: Test updates

Update every test that hard-codes old matchups:

- GDScript `tests/unit/test_type_chart.gd` — fix `test_fire_vs_water`,
  `test_water_vs_fire`, `test_wood_vs_fire_generating` expectations; add
  coverage for overcoming and reverse-generating edges.
- Rust `extensions/core/src/types.rs` unit tests — fix `test_water_vs_fire`,
  `test_fire_vs_water`, `test_earth_vs_wood`, `test_metal_vs_wood`,
  `test_wood_vs_earth`, `test_type_chart_five_element_cycle`,
  `test_type_chart_known_effectiveness`,
  `test_effectiveness_dual_extreme_clamping`.
- Rust `extensions/core/src/proptests.rs` — verify bounds assumptions (the
  proptest asserts `0.0 <= eff <= 2.0`; the new chart still satisfies it).
- Rust `extensions/core/tests/integration.rs` — fix
  `test_type_chart_character_scenario` (Fire→Water was 2.0×, now 0.5×).
- Rust `extensions/battle/tests/integration.rs` — fix the dual-type tests that
  assume "Wood beats Metal" (Wood→Metal is now 0.5×) and any scenario comments.
- Rust `extensions/battle/src/action.rs`, `flow.rs` — update inline comments and
  test setups that reference reversed matchups.

### D5: Validator additions

Extend `validate_type_chart` (Rust) and `_validate_type_chart` (GDScript) with
checks that the overcoming edges (Wood→Earth, Earth→Water, Water→Fire,
Fire→Metal, Metal→Wood) are 2.0× and the reverse-generating edges are 2.0×,
keeping the existing diagonal and Yang/Yin checks.

Rationale: the current validators only check diagonals and Yang/Yin, which is
why the reversed-cycle bug went undetected.
