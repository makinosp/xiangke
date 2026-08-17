## Tests for the move selection UI.
##
## Verifies MoveButton rendering (name/type, stats, effect badges,
## effectiveness, tooltip), the grid navigation index helper, and the battle
## scene's move panel structure.
extends "res://tests/test_base.gd"

## Battle scene script, used to call the static grid navigation helper.
const BattleSceneScript = preload("res://scripts/scenes/battle_scene.gd")


## Builds a MoveButton without entering the tree (BattleUnitPanel test
## pattern).
func _make_button() -> MoveButton:
	var btn := MoveButton.new()
	btn._build_ui()
	return btn


## Builds a damaging move with a status effect and a description.
func _make_damage_move() -> MoveData:
	var move := MoveData.new()
	move.id = "test_move"
	move.name = "Test Move"
	move.type = TypeEnums.Type.FIRE
	move.power = 80
	move.accuracy = 95
	move.damage_category = TypeEnums.DamageCategory.PHYSICAL
	move.effect = TypeEnums.EffectType.BURN
	move.effect_chance = 30
	move.stat_mod_stat = -1
	move.stat_mod_stage = 0
	move.stat_mod_target = TypeEnums.StatModTarget.SELF
	move.hit_count = 1
	move.recoil = 0
	move.healing = 0
	move.description = "A blazing test strike."
	return move


## Builds a non-damaging move with a stat stage modification.
func _make_stat_move(target: int) -> MoveData:
	var move := MoveData.new()
	move.id = "test_stat_move"
	move.name = "Test Wall"
	move.type = TypeEnums.Type.EARTH
	move.power = 0
	move.accuracy = 100
	move.damage_category = TypeEnums.DamageCategory.PHYSICAL
	move.effect = TypeEnums.EffectType.NONE
	move.effect_chance = 0
	move.stat_mod_stat = TypeEnums.Stat.DEFENSE
	move.stat_mod_stage = 2
	move.stat_mod_target = target
	move.hit_count = 1
	move.recoil = 0
	move.healing = 0
	move.description = "Raises a stone barrier."
	return move


func test_move_button_shows_name_and_type() -> int:
	var btn := _make_button()
	var move := _make_damage_move()
	btn.update_from_move(move, 2.0)

	var err := OK
	err = assert_eq(btn._name_label.text, "Test Move",
		"Move button should show the move name"); if err: return err
	err = assert_eq(btn._type_label.text, "Fire",
		"Move button should show the type name"); if err: return err
	err = assert_eq(btn._type_label.get_theme_color("font_color"),
		TypeColors.get_type_color(TypeEnums.Type.FIRE),
		"Type label should use the type color"); if err: return err
	btn.free()
	return err


func test_move_button_shows_stats() -> int:
	var btn := _make_button()
	btn.update_from_move(_make_damage_move(), 1.0)

	var err := OK
	err = assert_true(btn._stats_label.text.contains("P:80"),
		"Stats should include power"); if err: return err
	err = assert_true(btn._stats_label.text.contains("A:95%"),
		"Stats should include accuracy"); if err: return err
	err = assert_true(btn._stats_label.text.contains("Phys"),
		"Stats should include the damage category"); if err: return err
	btn.free()
	return err


func test_move_button_shows_status_effect_badge() -> int:
	var btn := _make_button()
	btn.update_from_move(_make_damage_move(), 1.0)

	var err := OK
	err = assert_eq(btn._badges_container.get_child_count(), 1,
		"Burn move should render exactly one badge"); if err: return err
	var badge_text: String = (btn._badges_container.get_child(0) as Label).text
	err = assert_true(badge_text.contains("Burn"),
		"Badge should name the status effect"); if err: return err
	err = assert_true(badge_text.contains("30%"),
		"Badge should show the trigger chance"); if err: return err
	btn.free()
	return err


func test_move_button_shows_stat_stage_badge() -> int:
	var btn := _make_button()
	btn.update_from_move(_make_stat_move(TypeEnums.StatModTarget.SELF), 1.0)

	var err := OK
	err = assert_eq(btn._badges_container.get_child_count(), 1,
		"Stat move should render exactly one badge"); if err: return err
	var badge_text: String = (btn._badges_container.get_child(0) as Label).text
	err = assert_true(badge_text.contains("DEF"),
		"Badge should show the affected stat"); if err: return err
	err = assert_true(badge_text.contains("+2"),
		"Badge should show the signed stage change"); if err: return err
	err = assert_true(badge_text.contains("(self)"),
		"Self-targeted stat move should show (self)"); if err: return err

	btn.update_from_move(_make_stat_move(TypeEnums.StatModTarget.TARGET), 1.0)
	badge_text = (btn._badges_container.get_child(0) as Label).text
	err = assert_true(badge_text.contains("(target)"),
		"Targeted stat move should show (target)"); if err: return err
	btn.free()
	return err


func test_move_button_shows_healing_recoil_multihit() -> int:
	var btn := _make_button()
	var move := _make_damage_move()
	move.healing = 33
	move.recoil = 25
	move.hit_count = 3
	move.effect = TypeEnums.EffectType.NONE
	move.effect_chance = 0
	btn.update_from_move(move, 1.0)

	var err := OK
	err = assert_eq(btn._badges_container.get_child_count(), 3,
		"Healing + recoil + multi-hit should render three badges"); if err: return err

	var badge_texts: Array[String] = []
	for child: Node in btn._badges_container.get_children():
		badge_texts.append((child as Label).text)

	err = assert_true(badge_texts.any(func(t: String) -> bool: return t.contains("Heal 33%")),
		"Badge should show healing"); if err: return err
	err = assert_true(badge_texts.any(func(t: String) -> bool: return t.contains("Recoil 25%")),
		"Badge should show recoil"); if err: return err
	err = assert_true(badge_texts.any(func(t: String) -> bool: return t.contains("×3 hits")),
		"Badge should show multi-hit count"); if err: return err
	btn.free()
	return err


func test_move_button_hides_unused_badges() -> int:
	var btn := _make_button()
	var move := _make_damage_move()
	move.effect = TypeEnums.EffectType.NONE
	move.effect_chance = 0
	move.stat_mod_stat = -1
	move.healing = 0
	move.recoil = 0
	move.hit_count = 1
	btn.update_from_move(move, 1.0)

	var err := OK
	err = assert_eq(btn._badges_container.get_child_count(), 0,
		"Plain move should render no badges"); if err: return err
	btn.free()
	return err


func test_move_button_effectiveness_formatting() -> int:
	var btn := _make_button()
	var move := _make_damage_move()
	var err := OK

	for eff_text: String in ["×2.0", "×1.25", "×1.0", "×0.5", "×0"]:
		var eff: float = 1.0
		match eff_text:
			"×2.0":
				eff = 2.0
			"×1.25":
				eff = 1.25
			"×1.0":
				eff = 1.0
			"×0.5":
				eff = 0.5
			"×0":
				eff = 0.0
		btn.update_from_move(move, eff)
		err = assert_eq(btn._effect_label.text, eff_text,
			"Effectiveness %s should render as %s" % [eff, eff_text]); if err: return err

	# Unknown target hides the multiplier.
	btn.update_from_move(move, -1.0)
	err = assert_eq(btn._effect_label.text, "",
		"Unknown effectiveness should hide the multiplier"); if err: return err
	btn.free()
	return err


func test_move_button_effectiveness_colors() -> int:
	var btn := _make_button()
	var move := _make_damage_move()
	var err := OK

	btn.update_from_move(move, 2.0)
	err = assert_eq(btn._effect_label.get_theme_color("font_color"),
		Color("#4CAF50"), "Super effective should be green"); if err: return err

	btn.update_from_move(move, 1.0)
	err = assert_eq(btn._effect_label.get_theme_color("font_color"),
		Color(0.8, 0.8, 0.8), "Neutral should be gray"); if err: return err

	btn.update_from_move(move, 0.5)
	err = assert_eq(btn._effect_label.get_theme_color("font_color"),
		Color("#F44336"), "Resisted should be red"); if err: return err

	btn.update_from_move(move, 0.0)
	err = assert_eq(btn._effect_label.get_theme_color("font_color"),
		Color("#B71C1C"), "Immune should be dark red"); if err: return err
	btn.free()
	return err


func test_move_button_tooltip_shows_description() -> int:
	var btn := _make_button()
	btn.update_from_move(_make_damage_move(), 1.0)

	var err := OK
	err = assert_eq(btn.tooltip_text, "A blazing test strike.",
		"Tooltip should show the move description"); if err: return err
	btn.free()
	return err


func test_move_button_build_is_idempotent() -> int:
	var btn := _make_button()
	btn._build_ui()

	var err := OK
	err = assert_eq(btn.get_child_count(), 1,
		"Rebuilding the UI should not duplicate children"); if err: return err
	btn.free()
	return err


## Regression: Button's native get_minimum_size() ignores a GDScript
## _get_minimum_size() override, so MoveButton must expose its content size
## through custom_minimum_size instead. The content size is pinned via the
## content box's custom_minimum_size because theme fonts do not resolve
## outside the tree, which would make label-based sizes zero.
func test_move_button_minimum_size_fits_content() -> int:
	var btn := _make_button()
	btn.update_from_move(_make_damage_move(), 2.0)
	btn._content_box.custom_minimum_size = Vector2(200.0, 63.0)
	btn._refresh_minimum_size()

	var err := OK
	err = assert_true(btn.custom_minimum_size.y >= 63.0 + btn._CONTENT_MARGIN_V * 2.0,
		"Button minimum height should fit content plus margins"); if err: return err
	err = assert_true(btn.custom_minimum_size.x >= 200.0 + btn._CONTENT_MARGIN_H * 2.0,
		"Button minimum width should fit content plus margins"); if err: return err
	btn.free()
	return err


## Tests the pure list navigation helper for 4 moves + switch (5 options).
func test_list_nav_four_moves() -> int:
	var err := OK

	err = assert_eq(BattleSceneScript._next_list_index(0, 1, 4), 1,
		"Down from the first move should go to the second"); if err: return err
	err = assert_eq(BattleSceneScript._next_list_index(3, 1, 4), 4,
		"Down from the last move should go to the switch"); if err: return err
	err = assert_eq(BattleSceneScript._next_list_index(4, 1, 4), 0,
		"Down from the switch should wrap to the first move"); if err: return err
	err = assert_eq(BattleSceneScript._next_list_index(0, -1, 4), 4,
		"Up from the first move should wrap to the switch"); if err: return err
	err = assert_eq(BattleSceneScript._next_list_index(4, -1, 4), 3,
		"Up from the switch should go to the last move"); if err: return err
	err = assert_eq(BattleSceneScript._next_list_index(1, -1, 4), 0,
		"Up from the second move should go to the first"); if err: return err
	return err


## Tests list navigation with odd move counts and edge cases.
func test_list_nav_edge_cases() -> int:
	var err := OK

	err = assert_eq(BattleSceneScript._next_list_index(0, 1, 1), 1,
		"Down with a single move should go to the switch"); if err: return err
	err = assert_eq(BattleSceneScript._next_list_index(1, -1, 1), 0,
		"Up from the switch with a single move should go to the move"); if err: return err
	err = assert_eq(BattleSceneScript._next_list_index(2, 1, 3), 3,
		"Down from the last of three moves should go to the switch"); if err: return err
	err = assert_eq(BattleSceneScript._next_list_index(0, 1, 0), -1,
		"No moves should yield -1"); if err: return err
	err = assert_eq(BattleSceneScript._next_list_index(7, 1, 4), 0,
		"Out-of-range index should clamp to the first move"); if err: return err
	return err


## Verifies the battle scene's move panel structure fits the viewport and
## contains the grid and switch slot.
func test_battle_scene_move_panel_structure() -> int:
	var scene: PackedScene = load("res://scenes/battle_scene.tscn")
	if scene == null:
		return assert_true(false, "battle_scene.tscn should load")
	var instance := scene.instantiate()
	var container := instance.get_node("MoveContainer")
	var err := OK

	err = assert_true(container is VBoxContainer,
		"MoveContainer should be a VBoxContainer"); if err: return err
	err = assert_true(container.anchor_left >= 0.0 and container.anchor_right <= 1.0,
		"MoveContainer horizontal anchors should fit the viewport"); if err: return err
	err = assert_true(container.anchor_top >= 0.0 and container.anchor_bottom <= 1.0,
		"MoveContainer vertical anchors should fit the viewport"); if err: return err
	err = assert_true(container.anchor_bottom - container.anchor_top >= 0.3,
		"MoveContainer should be tall enough for the move grid + switch"); if err: return err

	var move_list := instance.get_node_or_null("MoveContainer/MovePanel/PanelContent/MoveList")
	err = assert_true(move_list != null and move_list is VBoxContainer,
		"MoveList should exist as a VBoxContainer"); if err: return err

	var switch_slot := instance.get_node_or_null("MoveContainer/MovePanel/PanelContent/SwitchSlot")
	err = assert_true(switch_slot != null,
		"SwitchSlot should exist below the grid"); if err: return err

	instance.free()
	return err
