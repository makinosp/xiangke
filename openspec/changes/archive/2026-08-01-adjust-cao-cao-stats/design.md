## Context

- `resources/characters/cao_cao.tres` currently: HP 130 / ATK 95 / DEF 100 / SPD
  85 / INT 110 / SPR 105, sum 625 — the highest sum in the 38-character roster.
- Validation rules (CR-1..CR-4): each stat in [1, 500], stat sum ≤ 3000, exactly
  4 moves, at least one damaging move. The proposed values pass trivially.
- See proposal.md (Why) for motivation.

## Goals / Non-Goals

**Goals:**

- Make Cao Cao read as a durable strategist: keep his tank stats (HP, SPR) and
  his standout INT, while removing the physical-offense excess that made him an
  all-rounder.
- Keep the change to a single data-file edit with no collateral effects.

**Non-Goals:**

- Changing his type (YIN + WATER), moves, or description.
- Swapping moves (e.g., metal_slash → flame_burst) — move changes are deferred
  until the move pool is properly implemented.
- Differentiating Cao Cao from other Wei strategists (Guo Jia, Sima Yi, Xun Yu)
  — explicitly out of scope for now.

## Decisions

### D1: Cut ATK 95 → 75 and DEF 100 → 85

| Stat    | Before  | After   | Note                                        |
| ------- | ------- | ------- | ------------------------------------------- |
| HP      | 130     | 130     | keep — tank identity                        |
| ATK     | 95      | 75      | ▼ 20 — physical offense no longer his focus |
| DEF     | 100     | 85      | ▼ 15 — less physical tankiness              |
| SPD     | 85      | 85      | keep                                        |
| INT     | 110     | 110     | keep — his standout stat                    |
| SPR     | 105     | 105     | keep — arts resistance                      |
| **Sum** | **625** | **590** | largest → upper-mid tier                    |

Rationale: removes 35 points from the two physical stats, leaving a profile
where INT (110) is clearly the highest combat-relevant stat and HP/SPR keep him
durable. This matches the "tanky strategist" archetype agreed in exploration.

Alternative considered: cutting harder (sum → 570, near Guo Jia's 550) —
rejected; that collapses him into the generic strategist band and erases the
durable identity. Cutting only ATK (keeping DEF 100) — rejected; DEF 100 with HP
130 made him too strong defensively for a strategist.

### D2: No move changes in this change

His best move today is `metal_slash` (physical, uses ATK), which will become
relatively weaker after the cut. Swapping it for `flame_burst` (arts, uses INT)
would fit the new profile, but move adjustments belong with the future move pool
work (all 4 moves are provisional). Keeping moves unchanged makes this change
reviewable in isolation.

## Risks / Trade-offs

- [After the cut, `metal_slash` (his current best move, physical) underperforms
  INT 110] → Accepted and documented; resolved by the future move rework, not
  this change.
- [Cao Cao remains numerically close to other Wei strategists] → Accepted;
  differentiation deferred per user decision.
- [Reducing DEF lowers his durability against physical attackers] → Mitigated:
  HP 130 and SPR 105 remain, so he still out-tanks pure strategists.

## Open Questions

None.
