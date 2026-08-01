## Why

Cao Cao (曹操) is currently the strongest character in the roster with a stat
sum of 625, yet his stats are so uniformly high that he reads as "good at
everything" rather than a defined archetype. His offense stats (ATK 95, DEF 100)
make his physical moves strong, but his real identity is the cunning strategist
— his highest stat is INT 110. The current spread undercuts that identity.

## What Changes

- Adjust Cao Cao's stats in `resources/characters/cao_cao.tres`:
  - ATK 95 → 75 (moved points away from physical offense)
  - DEF 100 → 85 (softened his physical tankiness)
  - Stat sum 625 → 590
- Keep HP 130, SPD 85, INT 110, SPR 105 unchanged.
- Do **not** change his type, moves, or description.
- No code changes — this is a single data file edit.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a pure data adjustment to one character's stats. No requirements
in `openspec/specs/` change; the Character Data requirement (stats in [1,500],
stat sum ≤ 3000) continues to be satisfied. `skip_specs: true` is set in
`.openspec.yaml`.

## Impact

- `resources/characters/cao_cao.tres` — one file modified (ATK, DEF).
- Validation — new values (ATK 75, DEF 85) are well within all ranges; the stat
  sum drops from 625 to 590, so no validation rule is affected.
- Game balance — Cao Cao becomes a durable strategist (HP 130, SPR 105) with INT
  110 as his standout offense stat, instead of an all-rounder whose physical
  moves are also strong.
- Note: this intentionally does not differentiate him from other Wei strategists
  (Guo Jia, Sima Yi, Xun Yu); that is deferred until the move pool is properly
  implemented (currently provisional).
- Tests — no test hardcodes Cao Cao's stats; no test changes expected.
