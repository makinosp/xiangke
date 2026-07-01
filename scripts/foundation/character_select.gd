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
	var char_data := DataRegistry.get_character(char_id)
	if char_data == null:
		return

	preview_name.text = char_data.character_name
	# Update other stats fields in the preview panel
	stats_preview.show()


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
	_update_ui()


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
