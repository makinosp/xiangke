## UIFocusManager autoload singleton.
## Provides custom keyboard navigation with visual focus highlighting
## for UI screens.
extends Node

## Array of focusable controls in the current screen.
var focus_group: Array[Control] = []
## Index of the currently focused control.
var focused_index: int = 0

## Emitted when focus changes to a different control.
signal focus_changed(control: Control)


## Registers a group of controls as a focus group for keyboard navigation.
##
## Parameters:
##   controls: Array of Control nodes to include in the group.
func register_focus_group(controls: Array[Control]) -> void:
	focus_group = controls
	focused_index = 0
	if focus_group.size() > 0:
		_set_focus(0)


## Moves focus to the next control in the active group.
func focus_next() -> void:
	if focus_group.is_empty():
		return
	focused_index = (focused_index + 1) % focus_group.size()
	_set_focus(focused_index)


## Moves focus to the previous control in the active group.
func focus_previous() -> void:
	if focus_group.is_empty():
		return
	focused_index = (focused_index - 1 + focus_group.size()) % focus_group.size()
	_set_focus(focused_index)


## Directly sets focus to a specific control.
##
## Parameters:
##   control: The control to focus.
func set_focus(control: Control) -> void:
	var index := focus_group.find(control)
	if index >= 0:
		focused_index = index
		_set_focus(index)


## Clears the current focus group.
func clear_focus_group() -> void:
	focus_group.clear()
	focused_index = 0


## Applies visual highlighting to the focused control and resets others.
func _set_focus(index: int) -> void:
	for i in focus_group.size():
		var ctrl := focus_group[i]
		if i == index:
			ctrl.grab_focus()
			_modulate_highlight(ctrl, true)
		else:
			_modulate_highlight(ctrl, false)
	emit_signal("focus_changed", focus_group[index])


## Applies visual highlight to a control.
func _modulate_highlight(control: Control, highlighted: bool) -> void:
	if highlighted:
		control.modulate = Color(1.2, 1.2, 1.0) # Slightly brighter
	else:
		control.modulate = Color(1.0, 1.0, 1.0) # Normal
