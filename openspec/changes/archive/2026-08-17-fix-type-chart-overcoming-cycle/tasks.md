## 1. Spec Update

- [x] 1.1 Update `openspec/specs/domain/spec.md` Type Effectiveness requirement:
      add reverse-generating (2.0×) multiplier and the Reverse-generating cycle
      scenario (per the delta spec in `specs/domain/spec.md`)

## 2. Rust Core Chart (`extensions/core/src/types.rs`)

- [x] 2.1 Replace the 5×5 五行 block in `TypeChart::default()` with the target
      matrix (overcoming + reverse-generating edges at 2.0×)
- [x] 2.2 Update the module doc comment describing the cycles
- [x] 2.3 Fix unit tests encoding old matchups: `test_water_vs_fire`,
      `test_fire_vs_water`, `test_earth_vs_wood`, `test_metal_vs_wood`,
      `test_wood_vs_earth`, `test_wood_vs_fire`, `test_fire_vs_wood`
- [x] 2.4 Fix `test_type_chart_five_element_cycle` (the 2.0× cycle is now Wood →
      Earth → Water → Fire → Metal → Wood)
- [x] 2.5 Fix `test_type_chart_known_effectiveness` cases and
      `test_effectiveness_dual_extreme_clamping` expectations
- [x] 2.6 Add unit tests asserting the reverse-generating edges are 2.0× (Fire →
      Wood, Earth → Fire, Metal → Earth, Water → Metal, Wood → Water)

## 3. Rust Core Validator (`extensions/core/src/validator.rs`)

- [x] 3.1 Extend `validate_type_chart` to assert the five overcoming edges and
      the five reverse-generating edges are 2.0×
- [x] 3.2 Add/adjust validator tests covering the new checks

## 4. Rust Core Proptests (`extensions/core/src/proptests.rs`)

- [x] 4.1 Verify the `eff <= 2.0` bounds assumption still holds (it does — no
      value exceeds 2.0) and update comments if they mention specific edges

## 5. Rust Core Integration (`extensions/core/tests/integration.rs`)

- [x] 5.1 Fix `test_type_chart_character_scenario` (Fire → Water was 2.0×, now
      0.5×; update the pairings/assertions to match the new chart)

## 6. GDScript Chart (`scripts/type_chart.gd`)

- [x] 6.1 Replace the 5×5 五行 block in `TYPE_CHART` with the target matrix
- [x] 6.2 Update the row comment headers if needed (row = defender)

## 7. GDScript Validator (`systems/data/data_validator.gd`)

- [x] 7.1 Extend `_validate_type_chart` with overcoming-edge and
      reverse-generating-edge checks mirroring the Rust validator

## 8. GDScript Unit Tests (`tests/unit/test_type_chart.gd`)

- [x] 8.1 Fix `test_fire_vs_water` / `test_water_vs_fire` expectations
- [x] 8.2 Fix `test_wood_vs_fire_generating` / any generating-direction tests
- [x] 8.3 Add tests for the overcoming cycle (Wood → Earth = 2.0×) and
      reverse-generating (Fire → Wood = 2.0×)

## 9. Battle Engine Tests (`extensions/battle`)

- [x] 9.1 Fix `extensions/battle/tests/integration.rs` dual-type tests that
      assume "Wood beats Metal" (Wood → Metal is now 0.5×) and update scenario
      comments (e.g. `test_dual_type_clamp_max`, Wood-vs-Metal battle sim)
- [x] 9.2 Fix `extensions/battle/src/action.rs` inline comments/test setups
      referencing old matchups (e.g. Fire vs Water = 2.0× → 0.5×, Metal resists
      Wood direction)
- [x] 9.3 Fix `extensions/battle/src/flow.rs` comments/test setups referencing
      old matchups (e.g. Earth move vs Wood = 2.0× → 0.5×, Metal move vs
      Wood/Fire dual)

## 10. Verification

- [x] 10.1 Run `just test-rust` (or `cargo test --workspace`) and confirm all
      Rust tests pass
- [x] 10.2 Run the GDScript test runner (`tests/test_runner.tscn`) and confirm
      all GDScript tests pass
- [x] 10.3 Run the data validator (`just verify` or equivalent) to confirm the
      new validator checks pass
- [x] 10.4 Spot-check `just report types --format=csv` (or the data report) to
      confirm the exported chart shows the corrected matrix
