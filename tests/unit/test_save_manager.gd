## Tests for SaveManager data logic.
extends "res://tests/test_base.gd"

var _save_manager = null


func before_each() -> void:
	_save_manager = load("res://autoloads/save_manager.gd").new()
	_save_manager._ready()
	# Reset save data to defaults
	_save_manager.current_data = _save_manager._create_default_save()


func test_default_save_has_expected_keys() -> int:
	var data = _save_manager.current_data
	var err := OK
	err = assert_eq(data is Dictionary, true, "current_data should be a Dictionary"); if err: return err
	err = assert_eq(data.has("master_volume"), true, "Should have master_volume"); if err: return err
	err = assert_eq(data.has("selected_character"), true, "Should have selected_character"); if err: return err
	err = assert_eq(data.has("last_battle_won"), true, "Should have last_battle_won"); if err: return err
	return OK


func test_save_game_updates_master_volume() -> int:
	var test_data := {"master_volume": 0.5}
	_save_manager.save_game(test_data)
	return assert_eq(_save_manager.current_data.get("master_volume"), 0.5,
		"master_volume should be 0.5 after save")


func test_save_game_without_data_keeps_current() -> int:
	var test_data := {"master_volume": 0.25}
	_save_manager.save_game(test_data)
	_save_manager.save_game()
	return assert_eq(_save_manager.current_data.get("master_volume"), 0.25,
		"Saving without data should keep previous master_volume")


func test_loaded_data_persists_keys() -> int:
	var test_data := {"master_volume": 0.75, "last_battle_won": true}
	_save_manager.save_game(test_data)
	_save_manager.load_save()
	var loaded = _save_manager.current_data
	var err := OK
	err = assert_eq(loaded.get("master_volume"), 0.75, "master_volume should persist after load"); if err: return err
	err = assert_eq(loaded.get("last_battle_won"), true, "last_battle_won should persist after load"); if err: return err
	return OK
