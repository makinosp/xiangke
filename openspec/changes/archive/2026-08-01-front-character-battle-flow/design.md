## Context

See proposal.md for motivation. Current state that shapes the approach:

- The Rust battle crate (`xiangke-battle`) models all participants in a single
  `BattleState.participants` Vec, and `calculate_turn_queue` includes every
  non-defeated participant.
- `BattleParticipant` has `slot_index` (index within team) but no front/bench
  concept; all 9 participants (3 player + 6 enemy) take turns.
- The GDExtension bridge (`execute_player_action(move_data, target_index)`)
  passes an explicit target index from GDScript.
- GDScript battle scene drives the flow: move menu → target menu → execute →
  advance turn. AI logic is duplicated in GDScript (`_select_best_move`,
  `_find_weakest_target_index`) rather than using Rust `BasicAi`.
- Data flow: 3 player chars chosen via CorpsRoster; enemy uses all 6
  `opponent_corps` ids.

## Goals / Non-Goals

**Goals:**

- Front-line + bench model with the turn queue containing only front characters.
- Actions automatically resolve the opponent's front character as target.
- Switch action semantics: consumes the team's round action; entering character
  acts next round.
- Automatic bench replacement on front defeat, preserving stat stages and status
  effects.
- Enemy team fields 3 characters (deterministic selection from 6-corps).
- Enemy AI uses the switch action too.

**Non-Goals:**

- New type-chart, damage, or status-effect mechanics (existing systems
  unchanged).
- Changing corps creation / character select scenes beyond the enemy selection.
- Persistence/format changes to save data.
- Speed/initiative ordering rules (existing speed-descending order stays).

## Decisions

### D1: `is_front: bool` on BattleParticipant

Add a single `is_front` flag per participant (serde-serialized). The turn queue
filters on `!is_defeated && is_front`.

- Rationale: minimal change to the existing Vec-based model; no separate
  front/bench collections. Bench querying is done by filtering the same Vec.
- Alternative considered: separate `front` indices per team (`player_front`,
  `enemy_front`) in BattleState — rejected because it risks inconsistency (flag
  vs index drift) and complicates serialization; a flag keeps the single source
  of truth on the participant.

### D2: Switch = swap front flags, consume team round action

`execute_switch(team, bench_index)` validates (alive, same team, benched), then
swaps `is_front` between the two participants. The caller (bridge/GDScript)
consumes the turn by advancing the queue, so the entering character naturally
does not act this round.

- Rationale: no new "acted" bookkeeping needed. The existing round-queue
  mechanism (each participant acts once per round) already gives "entering
  character acts next round" for free.
- Alternative considered: re-inserting the entering character into the current
  round queue — rejected (complex, and spec says entering character may not
  act).

### D3: Automatic replacement inside the bridge action path

After a player action defeats the enemy front, the bridge calls
`auto_replace(Team::Enemy)` which promotes the first living benched enemy. The
same happens for the player side in GDScript after the AI acts.

- Rationale: keeps the Rust crate the source of truth for replacement logic
  while letting each side (bridge for enemy after player action, GDScript after
  AI action) trigger it at the right point.
- Alternative considered: deferring replacement to the next `advance_turn` —
  rejected because the front needs to be correct immediately after defeat for HP
  display and battle-end evaluation.

### D4: Enemy fielding = deterministic top-3 by combined stats

New GDScript helper selects 3 of `opponent_corps` by highest stat sum; first
(strongest) is the initial front.

- Rationale: deterministic and testable; no new randomness for an already-random
  corps.
- Alternative considered: random 3-of-6 — rejected (unpredictable difficulty,
  harder to test).

### D5: AI switch heuristic mirrors player rules

Extend `BasicAi` with an `AIAction` enum (`Attack { move_id, target }` /
`Switch { bench_index }`). AI switches when front HP ratio is low or the front
holds a type disadvantage against the player front; otherwise attacks.

- Rationale: the Rust crate already owns `BasicAi`; GDScript reimplements it for
  the live game. Both are updated to keep behavior consistent.
- Alternative considered: only GDScript AI — rejected because Rust `BasicAi`
  tests exist and should reflect the same rules.

### D6: Bridge API surface

- `execute_player_action(move_data)` — target removed; resolves enemy front
  internally.
- `execute_switch(bench_index)` — player team switch.
- `get_front_participant(team)` / `get_bench_participants(team)`.
- `part_dict` includes `is_front`.

- Rationale: target resolution belongs in Rust where the enemy front is known;
  GDScript passes only a bench index for switches.

## Risks / Trade-offs

- [Turn queue with only front chars means early rounds are 1v1; battles get
  longer as replacements enter] → acceptable; matches the requested design.
- [AI switch heuristics may over/under-switch, affecting difficulty] → simple
  thresholds (HP < 30%, type disadvantage) kept configurable later.
- [Enemy top-3 selection makes battles deterministic] → corps is still randomly
  generated at creation; only the 3-of-6 pick is deterministic.
- [Bridge auto-replace for enemy after player action but GDScript handles player
  side] → slight asymmetry; consolidated in a shared GDScript helper that calls
  the same Rust replacement function for both sides.
- [Removing target index changes bridge API] → breaking change; GDScript call
  sites updated in the same change.

## Migration Plan

1. Rust crate changes first (flag, queue filter, switch, auto-replace, AI).
2. Bridge API changes and GDScript wrapper updates in the same commit set so the
   project never builds in a half-migrated state.
3. Update battle scene UI (remove target menu, add switch menu).
4. Update/extend tests (Rust + GDScript) and run full verification.
5. Rollback: revert the change as a whole; no data migration required (save
   format untouched).

## Open Questions

None.
