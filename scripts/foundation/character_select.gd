## CharacterSelect script.
## Manages the two-phase character selection flow:
## Phase 1: Select 6 characters to form the corps.
## Phase 2: Select 3 characters from the corps for battle deployment.
extends Control

## Reference to the character grid container.
@onready var character_grid: GridContainer = $CharacterGrid
## Reference to the confirm button for Phase 1 (Corps selection).
@onready var confirm_corps_button: Button = $ConfirmCorpsButton
## Reference to the deploy button for Phase 2 (Battle selection).
@onready var deploy_button: Button = $DeployButton
## Reference to the phase indicator label.
@onready var phase_label: Label = $PhaseLabel
## Reference to the stats preview panel.
@onready var stats_preview: Panel = $StatsPreview
## Reference to the character name in stats preview.
@onready var preview_name: Label = $StatsPreview/NameLabel
## Reference to the character type in stats preview.
@onready var preview_type: Label = $StatsPreview/TypeLabel
## Reference to the HP stat in stats preview.
@onready var preview_hp: Label = $StatsPreview/HPLabel
## Reference to the Attack stat in stats preview.
@onready var preview_attack: Label = $StatsPreview/AttackLabel
## Reference to the Defense stat in stats preview.
@onready var preview_defense: Label = $StatsPreview/DefenseLabel
## Reference to the Speed stat in stats preview.
@onready var preview_speed: Label = $StatsPreview/SpeedLabel
## Reference to the description in stats preview.
@onready var preview_desc: Label = $StatsPreview/DescLabel

## Current selection phase.
var _phase: int = 1 # 1 = Corps selection, 2 = Battle selection
## Selected character IDs in current phase.
var _selected_ids: Array[String] = []
## All character buttons for focus management.
var _character_buttons: Array[Button] = []


func _ready() -> void:
	_load_characters()
	_update_ui()


## Loads character data from DataRegistry and creates selection buttons.
func _load_characters() -> void:
	var characters := DataRegistry.get_all_characters()
	for char_id in characters.keys():
		var char_data := characters[char_id] as CharacterData
		if char_data == null:
			continue

		var btn := Button.new()
		btn.text = char_data.character_name
		btn.connect("pressed", Callable(self, "_on_character_pressed").bind(char_id))
		btn.connect("mouse_entered", Callable(self, "_on_character_hovered").bind(char_id))
		btn.connect("mouse_exited", Callable(self, "_on_character_hover_exit"))
		btn.size_flags_horizontal = Control.SIZE_EXPAND
		character_grid.add_child(btn)
		_character_buttons.append(btn)

	UIFocusManager.register_focus_group(_character_buttons)


## Called when a character button is pressed.
func _on_character_pressed(char_id: String) -> void:
	# Phase 2: only allow selection from corps_characters
	if _phase == 2:
		if not GameManager.corps_roster.corps_characters.has(char_id):
			return # Cannot select character not in corps

	var max_per_phase := 6 if _phase == 1 else 3

	if _selected_ids.has(char_id):
		_selected_ids.erase(char_id)
	else:
		if _selected_ids.size() >= max_per_phase:
			return # Max selected
		_selected_ids.append(char_id)

	_update_ui()


## Called when hovering over a character to show stats preview.
func _on_character_hovered(char_id: String) -> void:
	var char_data := DataRegistry.get_character(char_id) as CharacterData
	if char_data == null:
		return

	preview_name.text = char_data.character_name
	# Update stats fields
	preview_type.text = "Type: %s" % _format_types(char_data.types)
	preview_hp.text = "HP: %d" % char_data.base_stats.hp
	preview_attack.text = "Attack: %d" % char_data.base_stats.attack
	preview_defense.text = "Defense: %d" % char_data.base_stats.defense
	preview_speed.text = "Speed: %d" % char_data.base_stats.speed
	preview_desc.text = char_data.description if char_data.description else ""
	stats_preview.show()


## Formats character types for display.
func _format_types(types: Array) -> String:
	var result := ""
	for i in range(min(types.size(), 2)):
		if i > 0:
			result += "/"
		result += TypeEnums.Type.keys()[types[i]]
	return result


## Called when the mouse exits a character button.
func _on_character_hover_exit() -> void:
	stats_preview.hide()


## Called when the Confirm Corps button is pressed (Phase 1 completion).
func _on_confirm_corps_pressed() -> void:
	if _selected_ids.size() != 6:
		return # Cannot confirm until exactly 6 selected

	# Register corps selection
	GameManager.corps_roster.set_corps_selection(_selected_ids)

	# Move to Phase 2
	_phase = 2
	_selected_ids.clear()
	
	# Clear and reload only corps characters for Phase 2
	_character_buttons.clear()
	for child in character_grid.get_children():
		child.queue_free()
	character_grid.remove_from_group("character_buttons")
	
	# Load only the 6 corps characters
	_load_corps_characters()
	_update_ui()


## Loads only the corps characters for Phase 2 selection.
func _load_corps_characters() -> void:
	var corps_ids := GameManager.corps_roster.corps_characters
	for char_id in corps_ids:
		var char_data := DataRegistry.get_character(char_id) as CharacterData
		if char_data == null:
			continue

		var btn := Button.new()
		btn.text = char_data.character_name
		btn.connect("pressed", Callable(self, "_on_character_pressed").bind(char_id))
		btn.connect("mouse_entered", Callable(self, "_on_character_hovered").bind(char_id))
		btn.connect("mouse_exited", Callable(self, "_on_character_hover_exit"))
		btn.size_flags_horizontal = Control.SIZE_EXPAND
		character_grid.add_child(btn)
		_character_buttons.append(btn)

	UIFocusManager.register_focus_group(_character_buttons)


## Called when the Deploy button is pressed (Phase 2 completion).
func _on_deploy_pressed() -> void:
	if _selected_ids.size() != 3:
		return # Cannot deploy until exactly 3 selected

	# Register battle party selection
	GameManager.corps_roster.set_battle_selection(_selected_ids)

	# Transition to battle
	GameManager.transition_to_state(GameManager.GameState.BATTLE)


## Updates UI elements based on current phase and selection state.
func _update_ui() -> void:
	if _phase == 1:
		phase_label.text = "Select 6 Characters for Your Corps (%d/6)" % _selected_ids.size()
		confirm_corps_button.disabled = _selected_ids.size() != 6
		confirm_corps_button.show()
		deploy_button.hide()
	else:
		phase_label.text = "Select 3 Characters to Deploy (%d/3)" % _selected_ids.size()
		deploy_button.disabled = _selected_ids.size() != 3
		deploy_button.show()
		confirm_corps_button.hide()
