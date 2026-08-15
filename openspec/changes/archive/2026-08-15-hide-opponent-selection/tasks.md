## 1. BattleUnitPanel hidden state

- [x] 1.1 Add `show_hidden_placeholder(character_data)` to
      `scripts/battle_unit_panel.gd` that renders a grayed panel showing the
      character's name and type but no HP, status, or stat-stage content
- [x] 1.2 Make `update_from_participant()` reset any placeholder state so a
      panel reused for a revealed character renders normally again

## 2. Enemy slot mapping and reveal state

- [x] 2.1 In `scripts/foundation/battle_scene.gd`, resolve each enemy
      participant's corps position by `character_data.id` lookup in
      `roster.opponent_corps` (the Rust bridge reports global participant
      indices in `slot_index`, so it cannot be used for corps mapping), and
      store the corps list as `_enemy_corps_ids` for slot rendering
- [x] 2.2 Add `_revealed_enemy_slots: Array[bool]` (size = opponent corps size,
      all false) and initialize it in `_setup_battle()`

## 3. Enemy panel rendering with reveal logic

- [x] 3.1 Add an enemy branch in `_update_team_hp()` that renders one slot per
      corps member in corps order: mark the current enemy front's corps slot as
      revealed, render revealed slots with `update_from_participant()` and all
      other slots with `show_hidden_placeholder()`
- [x] 3.2 Keep the player branch of `_update_team_hp()` unchanged (fielded
      participants, front first, full identity)
- [x] 3.3 Verify `scenes/battle_scene.tscn` enemy container layout fits 6 panels
      (adjust container sizing/scroll if needed)
- [x] 3.4 Add `show_defeated_placeholder()` to `scripts/battle_unit_panel.gd`
      (identity + red "DEFEATED" marker, no battle state) and render revealed
      slots whose participant is no longer living (defeated) with it in
      `_update_enemy_team_hp()`

## 4. Verification

- [x] 4.1 Run `just test-rust` and the GDScript test runner
      (`godot --headless -s res://tests/test_runner.gd`) and confirm no
      regressions
- [x] 4.2 Manual test: at battle start the enemy panel fully displays exactly
      one front character and up to 5 grayed-out slots that show the character's
      name and type but no HP or status information
- [x] 4.3 Manual test: when the enemy switches a hidden benched character in,
      that character becomes revealed and stays revealed after switching back to
      the bench
- [x] 4.4 Manual test: when the enemy front is defeated, the automatic
      replacement character becomes revealed and the defeated character's slot
      shows a distinct defeated state (not the hidden "???" placeholder)
- [x] 4.5 Manual test: the player team panel still shows all player characters
      with full identity
- [x] 4.6 Manual test: grayed-out slots give no way to distinguish selected from
      unselected corps members
