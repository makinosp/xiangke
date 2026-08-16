# Tasks: Improve Character Select Preview

## 1. Character Select Scene Layout

- [x] 1.1 Restructure `StatsPreview` in `scenes/character_select.tscn`: wrap the
      existing labels in a `MarginContainer` (10px padding) + `VBoxContainer`,
      keeping the panel anchors (0.55–0.95 x / 0.35–0.8 y)
- [x] 1.2 Update all preview labels (Name, Type, HP…Spirit, MovesContainer,
      DescLabel) to drop fixed `offset_right` values and span the container
      width
- [x] 1.3 Configure `DescLabel`: `size_flags_vertical = SIZE_EXPAND_FILL`,
      `autowrap_mode = AUTOWRAP_WORD_SMART`; remove `lines_truncated` and
      `max_lines_visible`
- [x] 1.4 Update `@onready` node paths in
      `scripts/foundation/character_select.gd` to the new container hierarchy
      (`$StatsPreview/MarginContainer/VBoxContainer/...`)

## 2. Opponent Hover Preview

- [x] 2.1 In `_load_opponent_display()`
      (`scripts/foundation/character_select.gd`), set
      `mouse_filter = Control.MOUSE_FILTER_STOP` on each opponent label
- [x] 2.2 Connect `mouse_entered` → `_on_character_hovered(char_id)` and
      `mouse_exited` → `_on_character_hover_exit` on each opponent label,
      reusing the existing handlers
- [x] 2.3 Keep the reddish tint on opponent labels so the list stays visually
      distinct from the player's corps

## 3. Corps Creation Scene Layout

- [x] 3.1 Apply the same `StatsPreview` restructure from task 1.1–1.3 to
      `scenes/corps_creation.tscn` (panel anchors 0.65–0.95 x / 0.1–0.75 y)
- [x] 3.2 Update `@onready` node paths in `scripts/foundation/corps_creation.gd`
      to the new container hierarchy
- [x] 3.3 Confirm player hover preview still works on the corps creation screen

## 4. Tests & Verification

- [x] 4.1 Add `tests/unit/test_character_select_preview.gd` (following
      `test_opponent_visibility.gd`): instantiate `character_select.tscn`, show
      the preview for a 4-move character, and assert every preview element's
      rect is inside the panel bounds and no two element rects intersect
- [x] 4.2 Add a test that the description label ends within the panel bounds
      when populated with the longest catalog description
- [x] 4.3 Add a test that hovering an opponent label triggers preview population
      with that opponent's data (call the hover handlers directly)
- [x] 4.4 Add a test that `_on_character_hover_exit` hides the preview
- [x] 4.5 Run the full GDScript test suite
      (`godot --headless
      res://tests/test_runner.tscn`) and confirm no
      regressions
- [ ] 4.6 Manual verification: on both screens, hover each character and each
      opponent; confirm no overlap, description fully visible, and preview hides
      on mouse exit
