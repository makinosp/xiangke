# Design: Retune Roster to Troop Strength

## Context

See `proposal.md` — Why. This is a pure data change across
`resources/characters/*.tres`. Each character resource is a Godot
`CharacterData` resource (see `scripts/character_data.gd`) with 6 stats: hp,
attack, defense, speed, intelligence, spirit. Validation rules (CR-1..CR-4)
require stats in [1, 500], sum ≤ 3000, exactly 4 moves, ≥1 damaging move.

The damage model splits by category: Physical uses ATK vs DEF, Arts uses INT vs
SPR (`extensions/core/src/calc.rs`). Physical EHP ≈ HP × DEF, so a
point-for-point HP↔DEF transfer keeps physical durability roughly neutral —
except for shields, where the archetype _is_ the extreme DEF number.

## Goals / Non-Goals

**Goals:**

- HP expresses 兵力 (troop strength): rulers/supreme commanders high, bodyguards
  and non-military figures low.
- Every changed character keeps an identical stat sum (zero-sum HP↔DEF swap), so
  validation and overall balance budget are untouched.
- Only `hp` and `defense` fields change; ATK/SPD/INT/SPR and move sets are
  frozen.

**Non-Goals:**

- No spec changes (`skip_specs: true` in `.openspec.yaml`).
- No new moves, status effects, or battle mechanics.
- No tier-based fine-tuning of the full table — that is deferred (the user
  explicitly postponed tier adjustment).

## Decisions

### D1: Zero-sum HP↔DEF swap only

Every edit moves the same number of points between `hp` and `defense` per
character. Sums never change, which keeps CR validation green and preserves the
intended per-character power budget.

| Group           | N             | HP shift                             | DEF shift | Example                    |
| --------------- | ------------- | ------------------------------------ | --------- | -------------------------- |
| Shields         | 3 (+1 anchor) | −40                                  | +40       | Dian Wei 140/112 → 100/152 |
| Strategists     | 9             | +25                                  | −25       | Zhuge Liang 85/60 → 110/35 |
| Rulers          | 6             | +5                                   | −5        | Dong Zhuo 145/95 → 150/90  |
| Warriors (adj.) | 3             | Lu Bu −5, Huang Zhong +5, Lü Meng +5 | mirrored  | Lu Bu 100/70 → 95/75       |
| Non-military    | 5             | −10                                  | +10       | Da Qiao 85/80 → 75/90      |

Cao Ren (70/180) is the confirmed anchor from `adjust-cao-ren-stats` — the
template the shield group follows, just with a 60-point transfer.

### D2: Shield group targets DEF-first durability

Dian Wei, Xu Chu, Xiahou Dun transfer 40 HP → DEF, matching the Cao Ren
philosophy. Their physical EHP stays within ~6% of the original while DEF
becomes their signature stat; magic (Arts vs SPR) and HP-based status effects
remain the intended counter. SPR is untouched.

### D3: Strategists sacrifice DEF, not SPR

Only `defense` is reduced (−25), `spirit` is preserved. The archetype is
"troop-backed commander who is devastating with arts but vulnerable to a sword
at close range" — physical attacks punish them, arts fights do not.

### D4: Rulers and non-military mirror shifts

- Rulers (+5 HP / −5 DEF): max troop strength, slightly softer personal defense
  (they command, they don't duel).
- Non-military (−10 HP / +10 DEF): no troops, but personal agility; a small DEF
  bump compensates the HP loss so physical EHP is nearly neutral (e.g., Da Qiao
  85×80=6,800 → 75×90=6,750).

### D5: Manual per-file edits, verified by script

24 `.tres` files change. Edits are two field lines per file (`hp =`,
`defense
=`). A Python verification script (sum check + range check, same
pattern used for Cao Cao/Cao Ren) runs before commit; GDScript tests (42/42) and
`openspec validate --all --no-interactive` gate the change.

## Risks / Trade-offs

- [Magic one-shots shields] → Intended: SPR stays low for Dian Wei/Xu Chu/
  Xiahou Dun/Cao Ren; strong arts (flame_burst ≈ 101 vs Cao Ren) already
  threaten them. This is a deliberate counter, documented in the Cao Ren design.
- [High-DEF strategists lose physical bulk] → Intended: physical EHP drops ~25%
  for the nine strategists; they now need protection or first-strike tempo (most
  are fast, SPD ≥ 85).
- [CAO_CAO was just retuned in 85b0b73] → User confirmed re-tuning him again
  (130/85 → 135/80) as part of the ruler group; the previous change is still
  coherent, this extends the theme.
- [Lü Meng treated as warrior, not strategist] → User confirmed; his DEF stays
  higher (90) than the strategist group despite being INT-heavy.

## Migration Plan

Pure data change — apply by editing the `.tres` files, verify with the Python
sum/range check and `godot --headless res://tests/test_runner.tscn`, then
commit. Rollback is a single `git revert` (or restoring the previous commit's
`resources/characters/`).

## Open Questions

None — stat values were confirmed with the user during exploration; the deferred
tier table fine-tuning is intentionally out of scope.
