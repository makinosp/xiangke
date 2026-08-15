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
	err = assert_eq(data.has("language"), true, "Should have language"); if err: return err
	return OK


func test_default_language_is_empty() -> int:
	return assert_eq(_save_manager.current_data.get("language"), "",
		"Default language should be empty so the system locale applies")


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


func test_language_persists_after_save_and_load() -> int:
	var test_data := {"language": "zh_TW"}
	_save_manager.save_game(test_data)
	_save_manager.load_save()
	return assert_eq(_save_manager.current_data.get("language"), "zh_TW",
		"language should persist after save and load")


func test_language_round_trip_via_config_file() -> int:
	_save_manager.save_game({"language": "ja"})
	var config := ConfigFile.new()
	var err: Error = config.load("user://save.cfg")
	if err != OK:
		return assert_true(false, "Save file should exist after save_game")
	return assert_eq(config.get_value("settings", "language", ""), "ja",
		"language should be written to the settings section")


## A legacy save without a language key loads without error and defaults to an
## empty language so the system locale applies (backward compatibility).
func test_legacy_save_without_language_loads() -> int:
	var config := ConfigFile.new()
	config.set_value("settings", "master_volume", 0.5)
	var save_err: Error = config.save("user://save.cfg")
	if save_err != OK:
		return assert_true(false, "Test fixture save should write")

	_save_manager.load_save()
	var err := OK
	err = assert_eq(_save_manager.current_data.has("language"), true,
		"Loaded data should include language"); if err: return err
	return assert_eq(_save_manager.current_data.get("language"), "",
		"Missing language key should default to empty so the system locale applies")
