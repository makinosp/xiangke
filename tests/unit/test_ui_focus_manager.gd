## Tests for UIFocusManager focus navigation logic.
extends "res://tests/test_base.gd"

var _focus_manager = null
var _signal_emitted: bool = false


func before_each() -> void:
	_focus_manager = load("res://autoloads/ui_focus_manager.gd").new()
	_signal_emitted = false


func test_empty_focus_group_does_not_crash() -> int:
	_focus_manager.focus_group.clear()
	_focus_manager.focus_next()
	_focus_manager.focus_previous()
	_focus_manager.set_focus(null)
	return OK


func test_register_focus_group_sets_index_zero() -> int:
	var mock_controls := _create_mock_controls(3)
	_focus_manager.register_focus_group(mock_controls)
	var err := OK
	err = assert_eq(_focus_manager.focused_index, 0,
		"Focus index should be 0 after registration"); if err: return err
	err = assert_eq(_focus_manager.focus_group.size(), 3,
		"Focus group should have 3 controls"); if err: return err
	return OK


func test_focus_next_wraps_around() -> int:
	var mock_controls := _create_mock_controls(3)
	_focus_manager.register_focus_group(mock_controls)

	_focus_manager.focus_next()
	var err := assert_eq(_focus_manager.focused_index, 1,
		"After one focus_next, index should be 1"); if err: return err

	_focus_manager.focus_next()
	err = assert_eq(_focus_manager.focused_index, 2,
		"After two focus_next, index should be 2"); if err: return err

	_focus_manager.focus_next()
	err = assert_eq(_focus_manager.focused_index, 0,
		"After three focus_next, index should wrap to 0"); if err: return err
	return OK


func test_focus_previous_wraps_around() -> int:
	var mock_controls := _create_mock_controls(3)
	_focus_manager.register_focus_group(mock_controls)

	_focus_manager.focused_index = 2
	_focus_manager.focus_previous()
	var err := assert_eq(_focus_manager.focused_index, 1,
		"After one focus_previous from 2, index should be 1"); if err: return err

	_focus_manager.focus_previous()
	err = assert_eq(_focus_manager.focused_index, 0,
		"After two focus_previous from 2, index should be 0"); if err: return err

	_focus_manager.focus_previous()
	err = assert_eq(_focus_manager.focused_index, 2,
		"After three focus_previous from 2, index should wrap to 2"); if err: return err
	return OK


func test_focus_next_single_element() -> int:
	var mock_controls := _create_mock_controls(1)
	_focus_manager.register_focus_group(mock_controls)

	var err := assert_eq(_focus_manager.focused_index, 0); if err: return err
	_focus_manager.focus_next()
	err = assert_eq(_focus_manager.focused_index, 0,
		"Single element: focus_next should stay at 0"); if err: return err
	return OK


func test_focus_previous_single_element() -> int:
	var mock_controls := _create_mock_controls(1)
	_focus_manager.register_focus_group(mock_controls)

	_focus_manager.focus_previous()
	return assert_eq(_focus_manager.focused_index, 0,
		"Single element: focus_previous should stay at 0")


func test_set_focus_by_control() -> int:
	var mock_controls := _create_mock_controls(4)
	_focus_manager.register_focus_group(mock_controls)

	_focus_manager.set_focus(mock_controls[2])
	return assert_eq(_focus_manager.focused_index, 2,
		"set_focus should update index to 2")


func test_register_focus_group_filters_non_controls() -> int:
	var mixed := []
	mixed.append(Button.new())
	mixed.append("not_a_control")
	mixed.append(Button.new())
	mixed.append(123)

	_focus_manager.register_focus_group(mixed)
	return assert_eq(_focus_manager.focus_group.size(), 2,
		"Only Control instances should be added to focus group")


func test_focus_signal_emitted_on_change() -> int:
	_focus_manager.focus_changed.connect(_on_focus_changed)

	var mock_controls := _create_mock_controls(2)
	_focus_manager.register_focus_group(mock_controls)

	var err := OK
	err = assert_eq(_signal_emitted, true,
		"focus_changed signal should be emitted on register"); if err: return err

	_signal_emitted = false
	_focus_manager.focus_next()
	err = assert_eq(_signal_emitted, true,
		"focus_changed signal should be emitted on focus_next"); if err: return err
	return OK


func _on_focus_changed(_control: Control) -> void:
	_signal_emitted = true


func _create_mock_controls(count: int) -> Array:
	var controls: Array = []
	for i in range(count):
		controls.append(Button.new())
	return controls
