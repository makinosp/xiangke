## Tests for GameManager state transitions.
## Tests the 5-state loop:
## TITLE → CORPS_CREATION → CHARACTER_SELECT → BATTLE → RESULT → TITLE
extends "res://tests/test_base.gd"

var _game_manager = null


## A lightweight GameManager subclass that suppresses scene changes.
class TestGameManager:
	const GameState = preload("res://autoloads/game_manager.gd").GameState

	static func new_instance():
		var gd = load("res://autoloads/game_manager.gd").new()
		# Replace _process_state with no-op via script-level override
		var mock_script = GDScript.new()
		mock_script.source_code = 'extends "res://autoloads/game_manager.gd"\nfunc _process_state(_state):\n\tpass'
		mock_script.reload()
		gd.set_script(mock_script)
		return gd


func before_each() -> void:
	_game_manager = TestGameManager.new_instance()


func test_initial_state_is_title() -> int:
	return assert_eq(_game_manager.current_state, _game_manager.GameState.TITLE,
		"Initial state should be TITLE")


func test_title_to_corps_creation_valid() -> int:
	return assert_eq(
		_game_manager.transition_to_state(_game_manager.GameState.CORPS_CREATION),
		true, "TITLE -> CORPS_CREATION should be valid")


func test_skip_corps_creation_invalid() -> int:
	_game_manager.current_state = _game_manager.GameState.TITLE
	return assert_eq(
		_game_manager.transition_to_state(_game_manager.GameState.CHARACTER_SELECT),
		false, "TITLE -> CHARACTER_SELECT (skip CORPS_CREATION) should be invalid")


func test_corps_creation_to_character_select_valid() -> int:
	_game_manager.transition_to_state(_game_manager.GameState.CORPS_CREATION)
	return assert_eq(
		_game_manager.transition_to_state(_game_manager.GameState.CHARACTER_SELECT),
		true, "CORPS_CREATION -> CHARACTER_SELECT should be valid")


func test_character_select_to_battle_valid() -> int:
	_game_manager.transition_to_state(_game_manager.GameState.CORPS_CREATION)
	_game_manager.transition_to_state(_game_manager.GameState.CHARACTER_SELECT)
	return assert_eq(
		_game_manager.transition_to_state(_game_manager.GameState.BATTLE),
		true, "CHARACTER_SELECT -> BATTLE should be valid")


func test_battle_to_result_valid() -> int:
	_game_manager.transition_to_state(_game_manager.GameState.CORPS_CREATION)
	_game_manager.transition_to_state(_game_manager.GameState.CHARACTER_SELECT)
	_game_manager.transition_to_state(_game_manager.GameState.BATTLE)
	return assert_eq(
		_game_manager.transition_to_state(_game_manager.GameState.RESULT),
		true, "BATTLE -> RESULT should be valid")


func test_result_to_title_valid() -> int:
	_game_manager.transition_to_state(_game_manager.GameState.CORPS_CREATION)
	_game_manager.transition_to_state(_game_manager.GameState.CHARACTER_SELECT)
	_game_manager.transition_to_state(_game_manager.GameState.BATTLE)
	_game_manager.transition_to_state(_game_manager.GameState.RESULT)
	return assert_eq(
		_game_manager.transition_to_state(_game_manager.GameState.TITLE),
		true, "RESULT -> TITLE should be valid (full cycle)")


func test_direct_to_same_state_invalid() -> int:
	_game_manager.current_state = _game_manager.GameState.TITLE
	return assert_eq(
		_game_manager.transition_to_state(_game_manager.GameState.TITLE),
		false, "Transition to same state should be invalid")


func test_skip_battle_from_select_invalid() -> int:
	_game_manager.current_state = _game_manager.GameState.CHARACTER_SELECT
	return assert_eq(
		_game_manager.transition_to_state(_game_manager.GameState.RESULT),
		false, "CHARACTER_SELECT -> RESULT (skip BATTLE) should be invalid")


func test_get_scene_for_state() -> int:
	var err := OK
	err = assert_eq(_game_manager.get_scene_for_state(_game_manager.GameState.TITLE),
		"res://scenes/title_screen.tscn", "TITLE scene path"); if err: return err
	err = assert_eq(_game_manager.get_scene_for_state(_game_manager.GameState.CORPS_CREATION),
		"res://scenes/corps_creation.tscn", "CORPS_CREATION scene path"); if err: return err
	err = assert_eq(_game_manager.get_scene_for_state(_game_manager.GameState.CHARACTER_SELECT),
		"res://scenes/character_select.tscn", "CHARACTER_SELECT scene path"); if err: return err
	err = assert_eq(_game_manager.get_scene_for_state(_game_manager.GameState.BATTLE),
		"res://scenes/battle_scene.tscn", "BATTLE scene path"); if err: return err
	err = assert_eq(_game_manager.get_scene_for_state(_game_manager.GameState.RESULT),
		"res://scenes/result_screen.tscn", "RESULT scene path"); if err: return err
	return OK


func after_all() -> void:
	if not Engine.has_singleton("GameManager"):
		_game_manager.free()
