## Context

The enemy AI lives in `BasicAi` (`extensions/battle/src/flow.rs`). It selects an
action by evaluating type effectiveness against the opponent's front and
deciding whether to attack or switch. See proposal.md - Why for the motivation.

Key current-state constraints:

- `TypeChart` is a 7×7 f64 matrix with `effectiveness(attack, defense)` for
  single-type and `effectiveness_dual(attack, a, b)` for dual-type defenders.
- `BattleParticipant.character_data.secondary_element` is `Option<TypeElement>`.
- `execute_switch` currently returns `Result<(), BattleError>` and writes its
  log via `state.add_log`; `execute_ai_turn` reads it back with `recent_log(1)`.
- The workspace uses `rand = "0.8"` (so `r#gen` is correct; `random()` is a rand
  0.9 API and is out of scope).
- `execute_damage_action` clones `MoveData` to satisfy the borrow checker when
  splitting `state.participants` mutably; this is intentional and retained.

## Goals / Non-Goals

**Goals:**

- Correct single-type effectiveness (no squaring).
- Never select a healing move as an attack, including in the fallback path.
- Switch on 0x effectiveness, not only `(0.0, 0.5]`.
- Choose the best living benched participant by type effectiveness when
  switching.
- Compare attacking vs. switching so the AI attacks when it can defeat the
  front.
- Cache the `TypeChart` instance.
- Return the switch log message directly instead of reading it back.

**Non-Goals:**

- Upgrading `rand` to 0.9 (the `r#gen` → `random()` change is out of scope).
- Removing the `MoveData` clone in `execute_damage_action` (borrow-checker
  necessity, negligible cost).
- General AI improvements beyond the reviewed issues (e.g. status-effect
  awareness, move PP, target selection beyond the front).

## Decisions

### D1: Single-type effectiveness uses `effectiveness`, not `effectiveness_dual`

`move_effectiveness_against` currently falls back to the primary element when
`secondary_element` is `None`, squaring the multiplier. Change it to branch:

- `Some(secondary)` → `effectiveness_dual(move_element, element, secondary)`
- `None` → `effectiveness(move_element, element)`

Rationale: matches the actual `TypeChart` API (there is no
`effectiveness_single` method) and removes the squaring bug.

### D2: Fallback move selection filters healing moves

The fallback currently uses `moves.first()` unconditionally. Change it to pick
the first move with `healing == 0` (and `power > 0`), mirroring the main search.
If no such move exists, return `None` so the AI performs no action.

Rationale: keeps the fallback consistent with the main attack search and the
spec requirement that healing moves are never selected as attacks.

### D3: Switch condition includes 0x effectiveness

Change the switch condition from `our_eff > 0.0 && our_eff <= THRESHOLD` to
`our_eff <= THRESHOLD`, and initialize `best_effectiveness` to `-1.0` so that
"no damaging move available" (`-1.0`) is distinguishable from "0x effectiveness"
(`0.0`). Both cases trigger a switch attempt.

Rationale: 0x is the worst possible matchup and should trigger a switch; the
`-1.0` sentinel keeps the no-move case distinct for clarity.

### D4: Best-bench selection

Replace `living_bench_indices(...).first()` with a scan that picks the living
benched participant maximizing `best_effectiveness` against the opponent's
front. Only switch if the best bench participant is not worse off than the
current front (existing `bench_eff >= our_eff` guard retained).

Rationale: improves AI quality with minimal complexity; the existing guard
prevents switching to a strictly worse matchup.

### D5: Attack-vs-switch comparison

Instead of returning `Switch` immediately when `should_switch` is true, compute
the best attack's expected damage and compare it against the opponent front's
remaining HP. If the attack would defeat the front, prefer the attack; otherwise
switch. This requires computing the best move before the switch decision.

Rationale: prevents the AI from switching away when it could secure a knockout.

### D6: Cache `TypeChart` via `OnceLock`

Introduce a module-level `static TYPE_CHART: OnceLock<TypeChart>` (or a
`fn type_chart() -> &'static TypeChart` helper) and use it in
`best_effectiveness` and `score_move`.

Rationale: `TypeChart` is immutable and cheap to build once; avoids
reconstructing it on every effectiveness evaluation.

### D7: `execute_switch` returns the log message

Change `execute_switch` to return `Result<String, BattleError>` where the `Ok`
value is the switch log message. `execute_ai_turn` uses that value directly
instead of `recent_log(1)`.

Rationale: removes the fragile assumption that the most recent log entry is the
switch message.

## Risks / Trade-offs

- [D5 changes AI behavior in ways that are hard to predict without simulation] →
  Covered by unit tests asserting the attack-when-knockout and switch-when-not
  cases.
- [D4 best-bench scan adds a small per-turn cost] → Negligible (bench size is
  small); bounded by the number of living benched participants.
- [D7 changes a public function signature] → `execute_switch` is internal to the
  battle crate; update its callers and tests in the same change.
