## 1. TypeColors Utility

- [x] 1.1 Create `scripts/foundation/type_colors.gd` with static methods:
      `get_type_color(type: int) -> Color`,
      `get_type_name(type: int) -> String`,
      `get_status_effect_label(effect: int) -> String`,
      `get_status_effect_color(effect: int) -> Color`
- [x] 1.2 Define 7 type colors (WOOD=#4CAF50, FIRE=#F44336, EARTH=#FF9800,
      METAL=#9E9E9E, WATER=#2196F3, YANG=#FFD700, YIN=#9C27B0) and 5 status
      effect label/color mappings
- [x] 1.3 Verify TypeColors compiles without errors by opening the project in
      Godot editor

## 2. BattleUnitPanel Scene

- [x] 2.1 Create `scripts/battle_unit_panel.gd` with class
      `BattleUnitPanel extends PanelContainer`
- [x] 2.2 Implement panel layout: VBoxContainer → [HBoxContainer (name + type
      label), ProgressBar (HP bar), Label (HP text), HBoxContainer (status
      badges), HBoxContainer (stat stages)]
- [x] 2.3 Implement `func update_from_participant(p: BattleParticipant) -> void`
      to update all child elements from participant data
- [x] 2.4 Implement `func set_front_highlight(is_front: bool) -> void` to
      visually distinguish the front character (e.g., border or background tint)
- [x] 2.5 Implement HP bar color logic: green (≥50%), yellow (25–50%), red
      (<25%), gray if defeated
- [x] 2.6 Implement status effect badge rendering: iterate
      `active_status_effects`, create Label with emoji + name from TypeColors
- [x] 2.7 Implement stat stage display: iterate `stat_stages`, show only
      non-zero values as "ATK↑2" / "DEF↓1" format
- [x] 2.8 Implement type label display: show primary type name in type color;
      show secondary type if present (e.g., "木+水")
- [x] 2.9 Create `scenes/battle_unit_panel.tscn` scene file with BattleUnitPanel
      root node and script attachment

## 3. Battle Scene HP Display Integration

- [x] 3.1 Refactor `_update_team_hp()` to create `BattleUnitPanel` instances on
      first call and store them in `_player_panels: Array[BattleUnitPanel]` /
      `_enemy_panels: Array[BattleUnitPanel]` dictionaries
- [x] 3.2 On subsequent calls, update existing panels via
      `update_from_participant()` instead of destroy-recreate
- [x] 3.3 Apply `set_front_highlight()` to the panel representing the current
      front character
- [x] 3.4 Handle panel reordering on switch: clear HBoxContainer children and
      re-add panels in the new order
- [x] 3.5 Remove the old `_update_team_hp()` Label-based implementation
- [x] 3.6 Verify HP display updates correctly during a full battle cycle
      (damage, healing, switch, defeat)

## 4. Move Button Type Color Enhancement

- [x] 4.1 In `_show_move_selection()`, add a type color label next to each move
      button text using `TypeColors.get_type_color(move_data.type)`
- [x] 4.2 Include damage category indicator (Physical/Arts) in the move button
      text

## 5. Switch Selection UI Enhancement

- [x] 5.1 In `_show_switch_selection()`, replace plain text buttons with
      `BattleUnitPanel` instances showing HP bar and status for each benched
      character
- [x] 5.2 Ensure the cancel button remains functional and styled consistently

## 6. Verification

- [x] 6.1 Run `godot --headless res://tests/test_runner.tscn` to confirm no
      existing tests break
- [x] 6.2 Manual test: start a battle, verify HP bars display correctly with
      color coding
- [x] 6.3 Manual test: inflict a status effect (e.g., use a move with Burn),
      verify badge appears on the affected character panel
- [x] 6.4 Manual test: use a stat modification move, verify stat stage indicator
      appears
- [x] 6.5 Manual test: switch characters, verify panel reordering and front
      highlight update
- [x] 6.6 Manual test: verify benched character panels show correct HP in switch
      selection UI
