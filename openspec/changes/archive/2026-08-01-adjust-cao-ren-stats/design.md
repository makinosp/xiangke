## Context

- `resources/characters/cao_ren.tres` currently: HP 130 / ATK 85 / DEF 120 / SPD
  70 / INT 75 / SPR 95, sum 575 — the roster's #1 DEF but by only 8 points over
  Dian Wei (112), and with HP 130 that makes him a generalist tank.
- Damage formula: `ceil(attack * power * 0.8 / defense)`, min 1. Physical EHP is
  therefore proportional to HP × DEF. Arts damage uses INT vs SPR (DEF does not
  help).
- Validation rules (CR-1..CR-4): each stat in [1, 500], stat sum ≤ 3000, exactly
  4 moves, at least one damaging move. The proposed values pass trivially.
- See proposal.md (Why) for motivation.

## Goals / Non-Goals

**Goals:**

- Make DEF the single dominant signature stat of Cao Ren ("the unbreakable
  shield"), 60 points beyond the old roster max.
- Create a sharp physical-wall / magic-weakness asymmetry: extremely high
  physical mitigation paired with low HP, so arts moves and HP-based status
  effects become his deliberate counter.
- Keep the change to a single data-file edit with no collateral effects.

**Non-Goals:**

- Changing his type (EARTH), moves, or description.
- Adjusting ATK / SPD / INT / SPR.
- Swapping moves — move changes are deferred until the move pool is properly
  implemented.

## Decisions

### D1: DEF 120 → 180, HP 130 → 70 (60-point swap, sum unchanged)

| Stat    | Before  | After   | Note                                                    |
| ------- | ------- | ------- | ------------------------------------------------------- |
| HP      | 130     | 70      | ▼ 60 — the price of the ultimate shield                 |
| ATK     | 85      | 85      | keep                                                    |
| DEF     | 120     | 180     | ▲ 60 — roster-max by a wide margin (next: Dian Wei 112) |
| SPD     | 70      | 70      | keep                                                    |
| INT     | 75      | 75      | keep                                                    |
| SPR     | 95      | 95      | keep                                                    |
| **Sum** | **575** | **575** | unchanged                                               |

Rationale: within the same 575 budget, 60 points move from HP into DEF. This is
an archetype statement rather than an efficiency play: physical EHP (HP × DEF)
drops from 15,600 to 12,600 (−19%), but the profile becomes unambiguous —
massive physical mitigation, one-shot-able by strong arts (flame_burst ≈ 101
against his SPR 95), fragile against poison/burn.

Alternatives considered:

- HP 120 / DEF 130 — EHP-neutral swap; rejected: DEF 130 is only 18 above the
  field and does not read as a singular identity stat.
- HP 100 / DEF 140 — milder; rejected: the user deliberately chose the extreme
  signature number.
- HP 70 / DEF 150 — intermediate; user iterated to DEF 180.

### D2: No move changes in this change

His kit (iron_cleave / earth_barrier / metal_slash / wood_heal) is unchanged.
With DEF 180, `earth_barrier` (a DEF buff) compounds his mitigation further, and
`wood_heal` offsets the HP loss — both synergize with the new profile, so no kit
edits are needed now.

## Risks / Trade-offs

- [Physical EHP drops 19% (15,600 → 12,600)] → Accepted: the intent is the
  archetype statement and physical/magic asymmetry, not raw survivability.
- [One-shot-able by strong arts moves (~101 damage vs HP 70)] → Accepted and
  intended: magic is the shield's counter.
- [Very vulnerable to HP-based status effects (poison/burn)] → Accepted:
  documented consequence of the low HP.
- [DEF 180 may feel like a "vanity number" if future DEF-based mechanics
  (counter/reflect) are not added] → Accepted; revisit when battle mechanics
  expand.

## Open Questions

None.
