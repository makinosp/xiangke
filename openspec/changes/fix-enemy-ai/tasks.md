## 1. Type Effectiveness Fixes

- [x] 1.1 Fix `move_effectiveness_against` to use `effectiveness` for
      single-type defenders and `effectiveness_dual` only when
      `secondary_element` is `Some`
- [x] 1.2 Add a unit test asserting single-type effectiveness is not squared
      (e.g. Fire vs single-type Wood is 0.5, not 0.25)

## 2. Move Selection Fixes

- [x] 2.1 Filter healing moves (`healing == 0`) in the fallback move selection,
      returning `None` when no usable damaging move exists
- [x] 2.2 Add a unit test asserting the AI never selects a healing move as an
      attack in the fallback path

## 3. Switch Logic Fixes

- [x] 3.1 Initialize `best_effectiveness` to `-1.0` and change the switch
      condition to `our_eff <= SWITCH_TYPE_THRESHOLD` so 0x effectiveness
      triggers a switch
- [x] 3.2 Add a unit test asserting the AI switches when its best effectiveness
      is 0x (immune)

## 4. Best-Bench Selection

- [x] 4.1 Replace `living_bench_indices(...).first()` with a scan selecting the
      living benched participant with the best type effectiveness against the
      opponent's front, retaining the `bench_eff >= our_eff` guard
- [x] 4.2 Add a unit test asserting the AI switches to the best benched
      participant when multiple are available

## 5. Attack-vs-Switch Comparison

- [x] 5.1 Compute the best attack before the switch decision and prefer the
      attack when it would defeat the opponent's front, even at low HP
- [x] 5.2 Add a unit test asserting the AI attacks (not switches) when a move
      would defeat the opponent's front

## 6. TypeChart Caching

- [x] 6.1 Introduce a module-level `OnceLock<TypeChart>` (or helper) and use it
      in `best_effectiveness` and `score_move`
- [x] 6.2 Verify existing effectiveness tests still pass

## 7. Switch Log Robustness

- [x] 7.1 Change `execute_switch` to return `Result<String, BattleError>` with
      the switch log message as the `Ok` value
- [x] 7.2 Update `execute_ai_turn` to use the returned message instead of
      `recent_log(1)`
- [x] 7.3 Update `execute_switch` callers and tests in `manager.rs`

## 8. Verification

- [x] 8.1 Run `cargo test -p xiangke-battle` and confirm all tests pass
- [x] 8.2 Run `cargo clippy -p xiangke-battle` and confirm no new warnings
