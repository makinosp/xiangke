## Why

The current battle flow lets the player pick a target from all enemy
participants after choosing a move, and every participant of both teams (3
player + 6 enemy) takes turns in a speed-sorted initiative order. The intended
design is a front-line battle: both teams field only their leading character,
and on a turn the player either performs an action against the opponent's front
character or switches with a benched character. Target selection should not
exist.

## What Changes

- **BREAKING**: Remove target selection entirely. The player picks a move and it
  always targets the opponent's current front character.
- Introduce a front-line + bench model: only the front character of each team is
  active in battle; the rest are benched.
- **BREAKING**: Both teams field 3 characters (selected from the 6-character
  corps). The enemy team now fields 3 characters instead of all 6.
- Add a Switch action: on your turn you may switch your front character with a
  living benched character. Switching consumes the team's turn for that round;
  the newly entered character acts starting next round.
- Add automatic bench replacement: when the front character is defeated, the
  first living benched character automatically enters and cannot act that round.
- Stat stages and status effects are preserved when switching to the bench.
- The enemy AI also uses the Switch action (e.g. when low on HP or at a type
  disadvantage).
- Remove the "Wait (Skip Turn)" option from the battle UI.
- Update the Rust battle crate, the GDExtension bridge API, the GDScript flow
  service, and the battle scene UI to implement the above.

## Capabilities

### New Capabilities

- `front-line-battle`: Front-line + bench battle model with automatic bench
  replacement, switch action semantics, and front-targeted attacks.

### Modified Capabilities

- `domain`: Battle participants gain a front/bench state; attacks always target
  the opponent's front character; team size changes to 3v3.
- `rust-bridge`: `execute_player_action` no longer takes a target index; new
  bridge functions for switching and querying front/bench participants.
- `testing`: New test coverage for switch mechanics, automatic bench
  replacement, and front-targeted actions.

## Impact

- `extensions/battle/src/participant.rs` — add `is_front` flag.
- `extensions/battle/src/manager.rs` — turn queue only includes front
  participants; switch and automatic replacement logic.
- `extensions/battle/src/flow.rs` — AI action enum with Attack/Switch; AI
  targets the opponent front character and may switch.
- `extensions/battle/src/action.rs` — unchanged core damage logic.
- `extensions/godot_bridge/src/lib.rs` — API changes (target-less action
  execution, switch, front/bench queries).
- `systems/battle/battle_flow_service.gd` — wrapper updates.
- `scripts/foundation/battle_scene.gd` — UI changes (no target selection, switch
  menu, front/bench HP display, enemy 3-character fielding, AI switch).
- `openspec/specs/{domain,rust-bridge,testing}/spec.md` — main specs updated
  after archival.
