## 1. Remove STAB Historical Reference

- [x] 1.1 Update doc comment on `is_type_matched` in
      `extensions/battle/src/action.rs` to remove "formerly known as STAB"
      reference
- [x] 1.2 Update doc comment on `TYPE_MATCH_MULTIPLIER` in
      `extensions/battle/src/action.rs` to remove "Same-Type Attack Bonus"
      reference

## 2. Rename GDScript Test

- [x] 2.1 Rename `test_same_type_is_neutral` to
      `test_same_type_effectiveness_is_neutral` in
      `tests/unit/test_type_chart.gd`

## 3. Expose is_type_matched in Bridge

- [x] 3.1 Add `is_type_matched` field to `ActionResult` struct in
      `extensions/battle/src/action.rs`
- [x] 3.2 Populate `is_type_matched` in `calculate_damage` from
      `RawDamage.is_type_matched`
- [x] 3.3 Add `is_type_matched` to `result_dict()` in
      `extensions/godot_bridge/src/lib.rs`

## 4. Sync Domain Spec

- [x] 4.1 Add "Type Match Bonus" requirement to `openspec/specs/domain/spec.md`

## 5. Verify

- [x] 5.1 Run `cargo test` in `extensions/` to verify Rust tests pass (117
      unit + 16 integration tests pass)
- [x] 5.2 Verify GDScript test rename doesn't break anything
- [x] 5.3 Run `openspec validate` to verify all artifacts are valid
