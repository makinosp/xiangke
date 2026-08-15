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
- Reworking `UIFocusManager` for 2D grids (grid nav is handled locally in the
  battle scene; see Decisions)

## Decisions

### D1: Move panel layout — bottom-center panel

MoveContainer anchors change to 0.28–0.72 x / 0.58–0.95 y (~560×266px), wrapping
a `PanelContainer` styled like `BattleUnitPanel` (dark `StyleBoxFlat`: bg
`0.15,0.15,0.2,0.8`, border `0.3,0.3,0.4`, radius 4). Inside: a `GridContainer`
(2 columns) for the moves, then a full-width switch button.

**Rationale:** the current 72px strip cannot hold rich buttons; the bottom
center area is unused during move selection (`ActionContainer` on the left is
only shown during switch selection). The panel visually matches the existing
unit panels.

**Alternatives considered:** reusing the left `ActionContainer` area — rejected
because it doubles as the switch-selection surface, causing overlap and
confusing state management.

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

### D4: Keyboard navigation — local 2D wrap logic in battle_scene

Keep a 5-element focus order `[move0..move3, switch]` (index 4 = switch). Handle
`ui_left/right/up/down` in `_input` while the move grid is visible:

- left/right: swap column within the row (from switch → index 0)
- up/down: ±2 rows; from bottom row down → switch; from switch up/down →
  top-left (index 0)
- `ui_accept` activates the focused Button natively; `ui_cancel` closes the
  bench selection (existing code path)

**Rationale:** `UIFocusManager` is linear (prev/next) and does not fit a 2×2
grid; native Godot focus neighbors do not guarantee wrapping. Explicit index
math is deterministic, testable, and small. The move grid also gets
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
