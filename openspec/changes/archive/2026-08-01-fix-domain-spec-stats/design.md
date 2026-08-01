## Context

Spec-only correction. See `proposal.md` for motivation. The `domain` spec has an
internal contradiction between the Type System requirement (5 stats) and the
Character Data requirement (6 stats with HP). The actual game data (`.tres`
resources) and Rust `Stat` enum define 6 stats including HP — the Type System
requirement is the one that is wrong.

## Goals / Non-Goals

**Goals:**

- Make the `domain` spec internally consistent: 6 stats including HP.
- Keep the change reviewable as a pure spec edit with no code impact.

**Non-Goals:**

- No changes to Rust, GDScript, resources, or any runtime behavior.
- No redefinition of what the 6 stats mean — only the Type System requirement's
  stat list is corrected.

## Decisions

- **Correct the Type System requirement only** — the Character Data requirement
  already lists the correct 6 stats (HP, attack, defense, speed, intelligence,
  spirit). The delta spec rewrites the stat list in Type System to "6 stats (HP,
  Attack, Defense, Speed, Intelligence, Spirit)" so both requirements agree.
- **No scenario changes** — the Type System requirement's only scenario (Type
  enum values) is unaffected by the stat-list wording; it is included in the
  delta verbatim so the sync is a clean description update.

## Risks / Trade-offs

- [Risk: sync misapplies the modified requirement] → Mitigation: the delta
  matches the existing requirement heading exactly; sync preserves the unchanged
  scenario.
