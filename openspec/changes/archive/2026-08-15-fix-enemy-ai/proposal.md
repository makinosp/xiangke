## Why

The enemy AI (`BasicAi` in `extensions/battle/src/flow.rs`) contains several
bugs and design limitations that produce incorrect or suboptimal behavior:
single-type effectiveness is squared, the fallback can select a healing move as
an attack, and the AI fails to switch when its moves are completely ineffective
(0x). These issues make the AI behave incorrectly and reduce battle quality.

## What Changes

- Fix single-type effectiveness being squared: when a defender has no
  `secondary_element`, use the single-type `effectiveness` lookup instead of
  passing the primary element twice to `effectiveness_dual`.
- Fix the fallback move selection to skip healing moves (`healing > 0`), so the
  AI never selects a healing move as an attack.
- Fix the switch-on-type-disadvantage condition so the AI switches when its best
  effectiveness is 0x (immune), not only when it is in `(0.0, 0.5]`.
- Improve bench selection so the AI picks the living benched participant with
  the best type effectiveness against the opponent's front, instead of always
  the first benched participant.
- Compare attacking vs. switching so the AI attacks when it can defeat the
  opponent's front even at low HP, instead of always switching when a switch
  condition is met.
- Cache the `TypeChart` instance (e.g. `OnceLock`/`static`) instead of
  reconstructing it on every effectiveness evaluation.
- Make the switch log message robust by having `execute_switch` return the log
  message directly instead of reading it back via `recent_log(1)`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `front-line-battle`: Update the AI Action Selection requirements to reflect
  correct type-effectiveness handling, healing-move exclusion in the fallback,
  switching on 0x effectiveness, best-bench selection, and attack-vs-switch
  comparison.

## Impact

- `extensions/battle/src/flow.rs`: `BasicAi` action selection, effectiveness
  computation, and `execute_ai_turn` switch handling.
- `extensions/battle/src/manager.rs`: `execute_switch` return type (returns the
  log message instead of only `Result<(), BattleError>`).
- `extensions/battle/src/action.rs`: no functional change (borrow-split clone is
  intentional and retained).
- Tests in `extensions/battle/src/flow.rs` and `manager.rs` updated/added.
