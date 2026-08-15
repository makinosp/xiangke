# Design: Hide Opponent Selection

## Context

The battle flow (`scripts/foundation/battle_scene.gd`) selects the 3 strongest
enemy characters from the 6-character opponent corps via
`_select_enemy_battle_team`, starts the battle through `BattleFlowService` (Rust
battle engine), and renders every fielded participant of both teams with full
identity (`_update_team_hp`, `BattleUnitPanel`). There is currently no notion of
"hidden" opponents: the player sees the opponent's entire fielded team from the
first frame. The Rust engine already tracks front/bench state and exposes it via
`get_front_participant` / `get_bench_participants`.

See proposal.md - Why for motivation; the behavior contract is in
`specs/opponent-roster-visibility/spec.md`.

## Goals / Non-Goals

**Goals:**

- At battle start, fully display only the opponent's front character; show the
  remaining slots grayed out (identity visible, battle state hidden)
- Fully display an opponent character exactly when it appears on the field
  (switch or automatic replacement), and keep it displayed afterwards
- Keep the player's own team panel fully visible and unchanged
- Keep all disclosure logic in GDScript; no Rust engine or bridge changes

**Non-Goals:**

- Not changing the character select screen (the player still sees the opponent's
  6-member corps there; only the selection is hidden)
- Not changing the AI's knowledge: the AI and battle engine keep full state
- Not hiding battle-log messages about characters that act (they are revealed by
  acting)
- Not adding a pre-battle "team preview" flow

## Decisions

### D1: Reveal state lives in GDScript, not Rust

Track which opponent corps slots have been revealed as a plain array in
`battle_scene.gd` (`_revealed_enemy_slots: Array[bool]`, size 6). Disclosure is
a presentation-layer concern; the Rust engine is authoritative about battle
state but must stay ignorant of what the player may or may not see.

- Alternative: Rust participants carry a `revealed` flag. Rejected: mixes
  presentation state into the domain model and would leak through the bridge for
  no behavioral gain.
- Alternative: derive reveal from front/bench state each frame. Rejected: once a
  character returns to the bench it would "un-reveal"; an explicit ever-revealed
  set is simpler and matches the spec.

### D2: Render the enemy panel as 6 fixed corps slots

The enemy panel always renders 6 slots in corps order (`roster.opponent_corps`
order). The 3 fielded characters are placed at their corps positions; every
non-front slot renders grayed out, showing the character's name and type but no
battle state. This gives the "up to 5 grayed out" layout from the spec and keeps
slot positions stable across switches.

- Alternative: render only the 3 fielded slots with placeholders for the 2
  hidden bench characters. Rejected: it would leak that the other 3 corps
  members are not selected (spec: selection status must not be disclosed).

### D3: Resolve corps positions by character id

The Rust bridge reports _global_ participant indices in `slot_index` (0..2 for
player, 3..5 for enemy) — a pre-existing contract used by `execute_switch`.
Treating it as a team-local index breaks reveal bookkeeping, so rendering
resolves each participant's corps position with
`_enemy_corps_ids.find(participant.character_data.id)` instead.
`_select_enemy_battle_team` keeps returning plain character IDs, and the corps
list is stored as `_enemy_corps_ids` for lookup and slot rendering.

### D4: Reveal rule = "has ever been the front"

A slot is revealed (fully displayed) if and only if its character has ever been
the enemy front character. Every code path that can change the front (battle
start, manual switch, `replace_front_if_defeated` before/after turns, AI turns)
funnels through `_update_hp_displays`, so `_update_team_hp(ENEMY)` marks the
current front's corps slot as revealed before rendering. No separate event
plumbing is needed.

- Alternative: explicit `mark_revealed()` calls at each switch/replace site.
  Rejected: more call sites to keep in sync; the funnel already exists.

### D5: Extend `BattleUnitPanel` with a hidden state

Add `show_hidden_placeholder(character_data)` to `BattleUnitPanel`: renders a
grayed panel showing the character's name and type but no HP, status, or
stat-stage content. Reusing the panel keeps layout and sizing identical to fully
displayed slots.

- Alternative: a separate lightweight placeholder scene. Rejected: duplicate
  sizing/styling logic for no benefit.

### D6: Player panel unchanged

The player branch of `_update_team_hp` keeps rendering fielded participants
(front first, then bench) with full identity.

## Risks / Trade-offs

- [Layout shifts when a hidden character appears] → Slots are fixed to corps
  order, so the revealed character renders in place; the grid never reorders.
- [Reveal bookkeeping drifts if a future code path changes the front without
  calling `_update_hp_displays`] → The reveal mark lives inside
  `_update_team_hp` (the single funnel); a future path that skips it would also
  skip HP updates, which is already a bug by construction.
- [Player can infer the selection from switch timing / panel positions] →
  Accepted: the spec only forbids explicit disclosure; inference from play
  (e.g., "the AI switched, so that slot was selected") is inherent to hidden
  information and matches the user's stated intent.
- [Corps with fewer than 6 members] → The 6-slot layout renders as many slots as
  the corps has; "up to 5" hidden slots naturally degrades.

## Migration Plan

No data migration; no engine or bridge changes. Rollback = revert the
GDScript/scene edits; battle mechanics, AI, and save data are untouched.
