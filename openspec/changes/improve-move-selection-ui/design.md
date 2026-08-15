# Design: Improve Move Selection UI

## Context

The move selection is currently rendered in `_show_move_selection()` in
`scripts/foundation/battle_scene.gd`: a plain `VBoxContainer` (`MoveContainer`
in `scenes/battle_scene.tscn`, anchored at 0.35–0.65 x / 0.85–0.95 y, ~72px
tall) holding one-line `Button`s. Four move buttons plus the switch button
overflow the container and fall off the bottom of the viewport. The scene is
1280×720.

Existing assets already cover most of the display needs:

- `TypeColors` — type colors/names, status effect emoji labels and colors, stat
  names, damage category names
- `scripts/type_chart.gd` — `resolve_type_effectiveness()` (7×7 matrix +
  dual-type clamp) usable via `TypeChart.new()`
- `MoveData` — power, accuracy, effect, effect_chance, stat_mod_*, hit_count,
  recoil, healing, damage_category, description
- `BattleUnitPanel` — the code-built UI pattern (StyleBoxFlat panel, labels
  constructed in `_build_ui()`) used as a quality reference
- Tests — `tests/unit/test_opponent_visibility.gd` shows the pattern of loading
  `battle_scene.tscn` and calling private builders directly

The opponent's front character is always fully revealed (see
`opponent-roster-visibility`), so type effectiveness is always computable.

## Goals / Non-Goals

**Goals:**

- A 2×2 move grid plus a switch option that all fit on screen
- Per-move display: type name, name, power, accuracy, category, effect badges,
  effectiveness multiplier, description tooltip
- Arrow-key navigation with wrapping, Enter to confirm, Esc to cancel bench
  selection (existing behavior preserved)

**Non-Goals:**

- Changing battle mechanics, targeting, or AI (Rust untouched)
- Changing the switch/bench selection panel itself beyond keeping it working
- Reworking `UIFocusManager` (list navigation is handled locally in the battle
  scene; see Decisions)

## Decisions

### D1: Move panel layout — bottom-right vertical list

MoveContainer anchors change to 0.62–0.98 x / 0.45–0.95 y (~460×360px at
1280×720), wrapping a `PanelContainer` styled like `BattleUnitPanel` (dark
`StyleBoxFlat`: bg `0.15,0.15,0.2,0.8`, border `0.3,0.3,0.4`, radius 4). Inside:
a `VBoxContainer` list — one `MoveButton` per move, then a full-width switch
button.

**Rationale:** the first implementation used a bottom-center 2×2 grid, but the
half-width cells left no room for the three text rows (name/type, stats/
effectiveness, badges), which visually overlapped. A vertical list gives every
option the full panel width (~450px), so each row has room to breathe. The
bottom-right area is unused during move selection (`ActionContainer` on the left
is only shown during switch selection, and `BattleLog` ends at 0.4 y).

**Alternatives considered:** keeping the 2×2 grid with smaller fonts — rejected,
shrinking text further harms readability on the Web target; a bottom-center
vertical list — rejected, bottom-right keeps the screen center clear for the
battle log and status messages.

### D2: Rich move buttons via a small helper script

New `class_name MoveButton extends Button` in
`scripts/foundation/move_button.gd`. It builds child labels in `_ready()`:

- Row 1: move name (white) + type name (type color, right-aligned)
- Row 2: `P:80 A:95% Phys` (gray) + effectiveness `×2.0` (colored)
- Row 3: badges — status effect (`TypeColors.get_status_effect_label` + chance),
  stat stage (`+2 DEF`, `(self)`/`(target)` suffix), healing (`Heal 33%`),
  recoil (`Recoil 33%`), multi-hit (`×3 hits`)
- `tooltip_text` = move description

All child controls get `mouse_filter = MOUSE_FILTER_IGNORE` so the Button still
receives clicks and focus. Expose an `update_from_move(move, effectiveness)`
method plus `_build_ui()` (matching the `BattleUnitPanel` test pattern).

**Rationale:** a plain `Button` only supports one font color; per-element
coloring (type color, badge colors, effectiveness color) needs child labels.
Extending `Button` keeps native hover/pressed/focus behavior free.

**Alternative considered:** a `PanelContainer` with manual input handling —
rejected, loses native focus ring and keyboard activation for free.

### D3: Effectiveness hint — computed against the revealed enemy front

`TypeChart.new().resolve_type_effectiveness(move.type, front.type,
front.secondary_type)`,
formatted as ×2.0 / ×1.25 / ×1.0 / ×0.5 / ×0. Colors: ≥1.25 green, 1.0 gray,
≤0.5 red, 0 special (e.g. `×0` in dark red). Rebuilt every time the move grid is
shown, so a front change automatically recomputes (satisfies the spec scenario).

**Rationale:** data is client-side; no Rust changes. The enemy front is always
revealed, so no "unknown" state is needed. (If it ever could be unknown, the
display falls back to hiding the multiplier.)

### D4: Keyboard navigation — vertical wrap logic in battle_scene

Keep a 5-element focus order `[move0..move3, switch]` (index 4 = switch). Handle
`ui_up/ui_down` (with `ui_left/ui_right` as prev/next equivalents) in `_input`
while the move list is visible:

- up/left: previous option, wrapping from the first move to the switch
- down/right: next option, wrapping from the switch to the first move
- `ui_accept` activates the focused Button natively; `ui_cancel` closes the
  bench selection (existing code path)

**Rationale:** a vertical list only needs 1D navigation; explicit index math is
deterministic, testable, and small. The move list also gets
`UIFocusManager`-style modulate highlighting on the focused button for visual
consistency with other screens.

### D5: Scene changes only touch MoveContainer

`battle_scene.tscn` changes are limited to `MoveContainer`'s anchors and the
panel/container structure. No scene changes to the HP panels, log, or
`ActionContainer`. The dynamic buttons remain code-built (existing pattern), so
`battle_scene.gd`'s `_show_move_selection()` is rewritten but its
`_on_move_selected` / `_on_switch_selected` wiring stays.

## Risks / Trade-offs

- [Child controls inside a Button can swallow input] → set every child to
  `MOUSE_FILTER_IGNORE`; covered by a test that presses the button.
- [Grid math drift (index wrap rules)] → encapsulate in one pure function
  (`_next_grid_index(from, dir)`) and unit-test it directly.
- [Panel consumes vertical space used by nothing today — but the log and HP rows
  are above 0.58 y] → anchors verified against viewport math and the existing
  scene test pattern.
- [TypeColor emoji labels (e.g. 🔥Burn) render differently per platform] →
  already used in the codebase; acceptable, no change here.

## Migration Plan

No migration needed — battle data, saves, and the Rust bridge are untouched.
Rollback = revert the scene anchors and `_show_move_selection()`; the change is
fully contained in `battle_scene.tscn`, `battle_scene.gd`, and the new
`move_button.gd`.

## Open Questions

None — deferrable unknowns would not change specs, approach, or task split.
