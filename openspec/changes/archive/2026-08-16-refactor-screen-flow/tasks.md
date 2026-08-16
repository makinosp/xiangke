## 1. GameManager State Machine

- [x] 1.1 Rename `CORPS_CREATION` to `CORPS_SETTINGS` in the `GameState` enum
- [x] 1.2 Update `_is_valid_transition()`: TITLE → CORPS_SETTINGS, TITLE →
      CHARACTER_SELECT, CORPS_SETTINGS → TITLE (remove CORPS_CREATION →
      CHARACTER_SELECT)
- [x] 1.3 Update `get_scene_for_state()` to map CORPS_SETTINGS to
      `corps_creation.tscn` (reuse existing scene)

## 2. Title Screen

- [x] 2.1 Add a "Corps Settings" button node to `title_screen.tscn`
- [x] 2.2 Add `_on_corps_settings_button_pressed()` handler that transitions to
      CORPS_SETTINGS
- [x] 2.3 Add disabled-state logic: check saved corps on `_ready()`, disable
      Start button if no valid 6-character corps
- [x] 2.4 Rename Start button handler to clarify it leads to CHARACTER_SELECT
- [x] 2.5 Register the new button in the UIFocusManager focus group

## 3. Corps Settings Screen (corps_creation)

- [x] 3.1 Add a "Back" button node to `corps_creation.tscn`
- [x] 3.2 Add `_on_back_button_pressed()` handler that returns to TITLE without
      saving
- [x] 3.3 Rename "Confirm" button to "Save & Back" in the scene
- [x] 3.4 Update `_on_confirm_pressed()` → `_on_save_pressed()`: save corps,
      then transition to TITLE instead of CHARACTER_SELECT
- [x] 3.5 Remove `_generate_opponent_corps()` call from save handler (opponent
      generation moves to battle start)

## 4. Character Select Screen

- [x] 4.1 Add a "Back" button node to `character_select.tscn`
- [x] 4.2 Add `_on_back_button_pressed()` handler that returns to TITLE
- [x] 4.3 Ensure `_load_characters()` reads from
      `GameManager.corps_roster.corps_characters` (already the case, verify)

## 5. Translations

- [x] 5.1 Add translation keys for new UI strings: `ui.corps_settings`,
      `ui.save_and_back`, `ui.back`, `ui.start_disabled_hint`
- [x] 5.2 Add entries in all 4 translation CSVs (en, ja, zh_CN, zh_TW)

## 6. Validation

- [x] 6.1 Run `just inspect` to verify no scene/script errors
- [x] 6.2 Manual test: Title → Corps Settings → Save → Title → Start → Character
      Select → Back → Title
- [x] 6.3 Manual test: Title → Start with no saved corps (button should be
      disabled)
- [x] 6.4 Manual test: Corps Settings → Back without saving (selection
      discarded)
