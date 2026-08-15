## Tests for opponent roster visibility.
##
## Verifies that BattleUnitPanel renders hidden placeholders (identity only,
## no battle state), that update_from_participant() resets placeholder state,
## and that the battle scene's enemy container fits 6 slots.
extends "res://tests/test_base.gd"


func before_all() -> void:
	# Register a test character so participants can resolve CharacterData.
	if not DataRegistry._characters.has("vis_test"):
		var cd := CharacterData.new()
		cd.id = "vis_test"
		cd.name = "Visibility Test"
		cd.type = TypeEnums.Type.FIRE
		cd.secondary_type = -1
		cd.hp = 200
		cd.attack = 50
		cd.defense = 30
		cd.speed = 40
		cd.intelligence = 50
		cd.spirit = 30
		DataRegistry._characters["vis_test"] = cd


func _make_panel() -> BattleUnitPanel:
	var panel: BattleUnitPanel = preload("res://scenes/battle_unit_panel.tscn").instantiate()
	panel._build_ui()
	return panel


func _make_participant(hp: int) -> BattleParticipant:
	var data: Dictionary = {
		"id": "vis_test",
		"current_hp": hp,
		"max_hp": 200,
		"team": BattleParticipant.Team.ENEMY,
		"slot_index": 1,
		"is_defeated": false,
		"is_front": false,
		"stat_stages": [0, 0, 0, 0, 0],
		"active_status_effects": [],
	}
	return BattleParticipant.from_dict(data)


func test_hidden_placeholder_shows_identity_only() -> int:
	var panel := _make_panel()
	var char_data: CharacterData = DataRegistry.get_character("vis_test")
	panel.show_hidden_placeholder(char_data)

	var err := OK
	err = assert_eq(panel._name_label.text, "Visibility Test",
		"Hidden slot should show the character's name"); if err: return err
	err = assert_eq(panel._hp_label.text, "???",
		"Hidden slot should show no HP text"); if err: return err
	err = assert_eq(panel._hp_bar.value, 0.0,
		"Hidden slot should have an empty HP bar"); if err: return err
	err = assert_eq(panel._status_container.get_child_count(), 0,
		"Hidden slot should show no status effects"); if err: return err
	err = assert_eq(panel._stat_container.get_child_count(), 0,
		"Hidden slot should show no stat stages"); if err: return err
	panel.free()
	return err


func test_update_from_participant_resets_hidden_state() -> int:
	var panel := _make_panel()
	panel.show_hidden_placeholder(DataRegistry.get_character("vis_test"))

	var p := _make_participant(120)
	panel.update_from_participant(p)

	var err := OK
	err = assert_eq(panel._name_label.text, "Visibility Test",
		"Revealed slot should keep the character's name"); if err: return err
	err = assert_eq(panel._hp_label.text, "120/200",
		"Revealed slot should show HP text again"); if err: return err
	err = assert_eq(panel._name_label.get_theme_color("font_color"), Color.WHITE,
		"Revealed slot should restore the normal name color"); if err: return err
	err = assert_eq(panel._hp_label.get_theme_color("font_color"), Color(0.8, 0.8, 0.8),
		"Revealed slot should restore the normal HP text color"); if err: return err
	err = assert_eq(panel._hp_bar.modulate, Color("#4CAF50"),
		"Revealed slot should restore the normal HP bar color"); if err: return err
	panel.free()
	return err


func test_defeated_placeholder_shows_defeat_marker() -> int:
	var panel := _make_panel()
	var char_data: CharacterData = DataRegistry.get_character("vis_test")
	panel.show_defeated_placeholder(char_data)

	var err := OK
	err = assert_eq(panel._name_label.text, "Visibility Test",
		"Defeated slot should keep the character's name"); if err: return err
	err = assert_eq(panel._hp_label.text, "DEFEATED",
		"Defeated slot should show a defeat marker"); if err: return err
	err = assert_true(panel._hp_label.text != "???",
		"Defeated slot should not use the hidden placeholder text"); if err: return err
	err = assert_eq(panel._hp_bar.value, 0.0,
		"Defeated slot should have an empty HP bar"); if err: return err
	err = assert_eq(panel._status_container.get_child_count(), 0,
		"Defeated slot should show no status effects"); if err: return err
	err = assert_eq(panel._stat_container.get_child_count(), 0,
		"Defeated slot should show no stat stages"); if err: return err
	panel.free()
	return err


func test_defeated_placeholder_distinct_from_hidden() -> int:
	var panel := _make_panel()
	var char_data: CharacterData = DataRegistry.get_character("vis_test")

	panel.show_hidden_placeholder(char_data)
	var hidden_border: Color = (panel.get_theme_stylebox("panel") as StyleBoxFlat).border_color
	panel.show_defeated_placeholder(char_data)
	var defeated_border: Color = (panel.get_theme_stylebox("panel") as StyleBoxFlat).border_color

	var err := OK
	err = assert_true(defeated_border != hidden_border,
		"Defeated slot should use a different panel border than hidden slots"); if err: return err
	err = assert_eq(panel._hp_label.text, "DEFEATED",
		"Defeated slot should show the defeat marker"); if err: return err
	err = assert_true(panel._hp_label.get_theme_color("font_color") != Color.GRAY,
		"Defeated slot's marker should not use the hidden placeholder's gray"); if err: return err
	panel.free()
	return err


func test_battle_scene_enemy_front_and_bench_structure() -> int:
	var scene: PackedScene = load("res://scenes/battle_scene.tscn")
	if scene == null:
		return assert_true(false, "battle_scene.tscn should load")
	var instance := scene.instantiate()
	var err := OK

	# The enemy front is displayed in a large panel.
	var front_panel := instance.get_node("EnemyFrontPanel")
	err = assert_true(front_panel is BattleUnitPanel,
		"EnemyFrontPanel should be a BattleUnitPanel"); if err: return err

	# The remaining corps members are shown in a small-panel bench row.
	var bench := instance.get_node("EnemyBenchContainer")
	err = assert_true(bench is HBoxContainer,
		"EnemyBenchContainer should be an HBoxContainer for the bench row"); if err: return err

	instance.free()
	return err


func test_size_mode_large_enlarges_portrait() -> int:
	var panel := _make_panel()
	panel.set_size_mode(BattleUnitPanel.SizeMode.LARGE)
	var err := OK
	err = assert_eq(panel._portrait_rect.custom_minimum_size, Vector2(160, 240),
		"LARGE mode should enlarge the portrait to 160x240"); if err: return err
	err = assert_true(panel._status_container.visible,
		"LARGE mode should keep the status row visible"); if err: return err
	err = assert_true(panel._stat_container.visible,
		"LARGE mode should keep the stat row visible"); if err: return err
	panel.free()
	return err


func test_size_mode_small_shrinks_portrait() -> int:
	var panel := _make_panel()
	panel.set_size_mode(BattleUnitPanel.SizeMode.SMALL)
	var err := OK
	err = assert_eq(panel._portrait_rect.custom_minimum_size, Vector2(40, 60),
		"SMALL mode should shrink the portrait to 40x60"); if err: return err
	err = assert_eq(panel.custom_minimum_size, Vector2(0, 0),
		"SMALL mode should not force a wide minimum size"); if err: return err
	err = assert_false(panel._status_container.visible,
		"SMALL mode should hide the status row to save space"); if err: return err
	err = assert_false(panel._stat_container.visible,
		"SMALL mode should hide the stat row to save space"); if err: return err
	panel.free()
	return err


func test_size_mode_standard_is_default() -> int:
	var panel := _make_panel()
	var err := OK
	err = assert_eq(panel._portrait_rect.custom_minimum_size, Vector2(120, 180),
		"Default mode should keep the standard 120x180 portrait"); if err: return err
	err = assert_eq(panel.custom_minimum_size, Vector2(160, 0),
		"Default mode should keep the standard minimum width"); if err: return err
	panel.free()
	return err
