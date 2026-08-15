## 1. BattleUnitPanel hidden state

- [ ] 1.1 Add `show_hidden_placeholder(character_data)` to
      `scripts/battle_unit_panel.gd` that renders a grayed panel showing the
      character's name and type but no HP, status, or stat-stage content
- [ ] 1.2 Make `update_from_participant()` reset any placeholder state so a
      panel reused for a revealed character renders normally again

## 2. Enemy slot mapping and reveal state

- [ ] 2.1 Extend `_select_enemy_battle_team()` in
      `scripts/foundation/battle_scene.gd` to also return each selected
      character's index within `roster.opponent_corps`, and build a
      `_enemy_slot_to_corps: Array[int]` mapping Rust participant `slot_index`
      (0..2) to corps index (0..5)
- [ ] 2.2 Add `_revealed_enemy_slots: Array[bool]` (size = opponent corps size,
      all false) and initialize it in `_setup_battle()`

## 3. Enemy panel rendering with reveal logic

- [ ] 3.1 Add an enemy branch in `_update_team_hp()` that renders one slot per
      corps member in corps order: mark the current enemy front's corps slot as
      revealed, render revealed slots with `update_from_participant()` and all
      other slots with `show_hidden_placeholder()`
- [ ] 3.2 Keep the player branch of `_update_team_hp()` unchanged (fielded
      participants, front first, full identity)
- [ ] 3.3 Verify `scenes/battle_scene.tscn` enemy container layout fits 6 panels
      (adjust container sizing/scroll if needed)

## 4. Verification

- [ ] 4.1 Run `just test-rust` and the GDScript test runner
      (`godot --headless -s res://tests/test_runner.gd`) and confirm no
      regressions
- [ ] 4.2 Manual test: at battle start the enemy panel fully displays exactly
      one front character and up to 5 grayed-out slots that show the character's
      name and type but no HP or status information
- [ ] 4.3 Manual test: when the enemy switches a hidden benched character in,
      that character becomes revealed and stays revealed after switching back to
      the bench
- [ ] 4.4 Manual test: when the enemy front is defeated, the automatic
      replacement character becomes revealed
- [ ] 4.5 Manual test: the player team panel still shows all player characters
      with full identity
- [ ] 4.6 Manual test: grayed-out slots give no way to distinguish selected from
      unselected corps members
