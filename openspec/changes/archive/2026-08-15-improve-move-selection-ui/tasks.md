# Tasks: Improve Move Selection UI

## 1. MoveButton Helper Script

- [x] 1.1 Create `scripts/foundation/move_button.gd` with
      `class_name MoveButton
      extends Button`, building child labels in
      `_build_ui()` (matching the `BattleUnitPanel` pattern) with all children
      set to `MOUSE_FILTER_IGNORE`
- [x] 1.2 Implement `update_from_move(move: MoveData, effectiveness: float)`:
      row 1 = move name (white) + type name (type color); row 2 = power,
      accuracy, damage category + effectiveness multiplier; row 3 = effect
      badges
- [x] 1.3 Render effect badges from `MoveData`: status effect label + trigger
      chance, stat stage change (stat name + signed stage + self/target suffix),
      healing, recoil, and multi-hit count; hide badges when not applicable
- [x] 1.4 Format and color the effectiveness multiplier (×2.0 / ×1.25 / ×1.0 /
      ×0.5 / ×0; ≥1.25 green, 1.0 gray, ≤0.5 red, 0 dark red)
- [x] 1.5 Set `tooltip_text` to the move's flavor description

## 2. Scene Layout

- [x] 2.1 Update `MoveContainer` anchors in `scenes/battle_scene.tscn` to
      0.62–0.98 x / 0.45–0.95 y (bottom-right) so all options fit the viewport
- [x] 2.2 Add the panel structure inside `MoveContainer`: a `PanelContainer`
      styled like `BattleUnitPanel` (dark `StyleBoxFlat`), containing a
      `VBoxContainer` move list and a slot for the full-width switch button

## 3. Battle Scene Wiring

- [x] 3.1 Rewrite `_show_move_selection()` in
      `scripts/foundation/battle_scene.gd` to populate the move list with
      `MoveButton` instances (one per known move, no empty rows) plus the switch
      button
- [x] 3.2 Compute each move's effectiveness against the opponent's current front
      character via `TypeChart.new().resolve_type_effectiveness(...)` in
      `_show_move_selection()` (recomputed on every turn, covering front
      changes)
- [x] 3.3 Keep `_on_move_selected` / `_on_switch_selected` wiring and the
      bench-selection flow working with the new grid
- [x] 3.4 Add list keyboard navigation in `_input`: up/down (with left/right as
      prev/next equivalents) move through the 5-slot order
      `[move0..move3, switch]` with wrapping per the design (D4), encapsulated
      in a pure index-math helper
- [x] 3.5 Apply `UIFocusManager`-style modulate highlighting to the focused move
      option and grab initial focus on the first move

## 4. Tests

- [x] 4.1 Add `tests/unit/test_move_selection_ui.gd` covering `MoveButton`
      rendering: name/type row, stats row, status-effect badge with chance,
      stat-stage badge with self/target suffix, healing, recoil, multi-hit, and
      effectiveness text/collist index-math helper: up/down movement, wrap from
      the first move to the switch, wrap from the switch to the first move, and
      zero-move safetydown row movement, down from bottom row to switch, and
      switch wrapping
- [x] 4.3 Add a scene-structure test (following `test_opponent_visibility.gd`):
      `battle_scene.tscnmove listads,`MoveContainer` anchors are within the
      viewport, and the grid/switch containers exist

## 5. Validation

- [x] 5.1 Run the GDScript test suite (existing test runner) and fix any
      failures
- [x] 5.2 Run `just inspect` (headless check) to confirm no script/scene parse
      errors
- [x] 5.3 Manually verify in-game: all 4 moves + switch visible, arrows navigate
      with wrap, Enter executes, Esc cancels bench selection, and the switch
      flow still works
- [x] 5.4 Run `openspec validate` on the change and confirm it passes
