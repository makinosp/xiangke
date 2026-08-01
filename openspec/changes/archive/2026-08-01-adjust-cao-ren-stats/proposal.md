## Why

Cao Ren (曹仁) is Wei's shield — the general who held Fan Castle against Guan
Yu's siege. His current profile (HP 130 / DEF 120) already reads as a wall, but
his DEF is not yet the dominant signature stat his identity calls for: DEF 120
is only 8 points above Dian Wei's 112, and his HP 130 makes him a generalist
tank rather than THE unbreakable shield. His defensive profile should be rebuilt
so that DEF is the single defining stat, with a deliberate physical-wall /
magic-weakness trade-off.

## What Changes

- Adjust Cao Ren's stats in `resources/characters/cao_ren.tres`:
  - DEF 120 → 180 (the roster's ultimate defensive stat)
  - HP 130 → 70 (moved 60 points into DEF)
  - Stat sum stays 575 (70 + 85 + 180 + 70 + 75 + 95)
- Keep ATK 85, SPD 70, INT 75, SPR 95 unchanged.
- Do **not** change his type (EARTH), moves, or description.
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

- `resources/characters/cao_ren.tres` — one file modified (HP, DEF).
- Validation — new values (HP 70, DEF 180) are well within all ranges; the stat
  sum is unchanged at 575, so no validation rule is affected.
- Game balance — Cao Ren becomes the extreme physical wall: physical hits land
  at roughly 17–56 damage (large moves ~45–56), while his low HP 70 makes him
  one-shot-able by strong arts moves (e.g. flame_burst ≈ 101 damage) and very
  vulnerable to HP-based status effects (poison/burn). Magic is his deliberate
  counter.
- Note: the EHP math (HP × DEF) means physical tankiness is actually reduced
  from 15,600 to 12,600 (−19%); the value of this change is the archetype
  statement (DEF 180, 68 above Dian Wei's 112) and the sharpened physical/magic
  asymmetry, not raw survivability.
- Tests — no test hardcodes Cao Ren's stats; no test changes expected.
