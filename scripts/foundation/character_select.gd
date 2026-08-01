## CharacterSelect script.
## Manages Phase 2 of character selection: select 3 characters from the
## pre-selected corps for battle deployment.
## Displays opponent's corps as read-only.
extends Control

## Reference to the character grid container.
@onready var character_grid: GridContainer = $CharacterGrid
## Reference to the deploy button.
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
## Reference to the Intelligence stat in stats preview.
@onready var preview_intelligence: Label = $StatsPreview/IntelligenceLabel
## Reference to the Spirit stat in stats preview.
@onready var preview_spirit: Label = $StatsPreview/SpiritLabel
## Reference to the move labels container in stats preview.
@onready var preview_moves_container: VBoxContainer = $StatsPreview/MovesContainer
## Reference to individual move labels.
@onready var preview_move_1: Label = $StatsPreview/MovesContainer/Move1Label
@onready var preview_move_2: Label = $StatsPreview/MovesContainer/Move2Label
@onready var preview_move_3: Label = $StatsPreview/MovesContainer/Move3Label
@onready var preview_move_4: Label = $StatsPreview/MovesContainer/Move4Label
## Reference to the description in stats preview.
@onready var preview_desc: Label = $StatsPreview/DescLabel
## Reference to the opponent corps labels container.
@onready var opponent_label_container: VBoxContainer = $OpponentPanel/ScrollContainer/OpponentList

## Selected character IDs (Phase 2: 3 from corps).
var _selected_ids: Array[String] = []
## All character buttons for focus management.
var _character_buttons: Array[Control] = []


func _ready() -> void:
	_load_characters()
	_load_opponent_display()
	_update_ui()
	_setup_preview_colors()
	stats_preview.hide()


## Sets up the colors for the stats preview labels.
func _setup_preview_colors() -> void:
	var white := Color(1, 1, 1)
	var light_gray := Color(0.8, 0.8, 0.8)
	var desc_color := Color(0.9, 0.9, 0.9)
	var move_color := Color(0.85, 0.85, 0.7)
	preview_name.add_theme_color_override(&"font_color", white)
	preview_type.add_theme_color_override(&"font_color", light_gray)
	preview_hp.add_theme_color_override(&"font_color", light_gray)
	preview_attack.add_theme_color_override(&"font_color", light_gray)
	preview_defense.add_theme_color_override(&"font_color", light_gray)
	preview_speed.add_theme_color_override(&"font_color", light_gray)
	preview_intelligence.add_theme_color_override(&"font_color", light_gray)
	preview_spirit.add_theme_color_override(&"font_color", light_gray)
	preview_move_1.add_theme_color_override(&"font_color", move_color)
	preview_move_2.add_theme_color_override(&"font_color", move_color)
	preview_move_3.add_theme_color_override(&"font_color", move_color)
	preview_move_4.add_theme_color_override(&"font_color", move_color)
	preview_desc.add_theme_color_override(&"font_color", desc_color)


## Loads only the corps characters (from CorpsRoster) for Phase 2 selection.
func _load_characters() -> void:
	var corps_ids: Array[String] = GameManager.corps_roster.corps_characters
	for char_id in corps_ids:
		var char_data := DataRegistry.get_character(char_id)
		if char_data == null:
			continue

		var btn := Button.new()
		btn.text = char_data.name
		btn.set_meta(&"char_id", char_id)
		btn.connect("pressed", Callable(self, "_on_character_pressed").bind(char_id))
		btn.connect("mouse_entered", Callable(self, "_on_character_hovered").bind(char_id))
		btn.connect("mouse_exited", Callable(self, "_on_character_hover_exit"))
		btn.size_flags_horizontal = Control.SIZE_EXPAND
		character_grid.add_child(btn)
		_character_buttons.append(btn)

	UIFocusManager.register_focus_group(_character_buttons)


## Loads the opponent corps display (read-only labels).
func _load_opponent_display() -> void:
	var opponent_ids: Array[String] = GameManager.corps_roster.opponent_corps
	# Clear existing opponent labels
	for child in opponent_label_container.get_children():
		child.queue_free()

	for char_id in opponent_ids:
		var char_data := DataRegistry.get_character(char_id)
		if char_data == null:
			continue

		var label := Label.new()
		label.text = "%s (%s)" % [char_data.name, _format_type(char_data.type, char_data.secondary_type)]
		label.add_theme_color_override(&"font_color", Color(0.9, 0.7, 0.7)) # Reddish tint for enemy
		opponent_label_container.add_child(label)


## Called when a character button is pressed.
func _on_character_pressed(char_id: String) -> void:
	# Only allow selection from corps_characters
	if not GameManager.corps_roster.corps_characters.has(char_id):
		return

	if _selected_ids.has(char_id):
		_selected_ids.erase(char_id)
	else:
		if _selected_ids.size() >= 3:
			return
		_selected_ids.append(char_id)

	_update_ui()


## Called when hovering over a character to show stats preview.
func _on_character_hovered(char_id: String) -> void:
	var char_data := DataRegistry.get_character(char_id)
	if char_data == null:
		return

	preview_name.text = char_data.name
	preview_type.text = "Type: %s" % _format_type(char_data.type, char_data.secondary_type)
	preview_hp.text = "HP: %d" % char_data.hp
	preview_attack.text = "Attack: %d" % char_data.attack
	preview_defense.text = "Defense: %d" % char_data.defense
	preview_speed.text = "Speed: %d" % char_data.speed
	preview_intelligence.text = "Intelligence: %d" % char_data.intelligence
	preview_spirit.text = "Spirit: %d" % char_data.spirit

	# Load and display move list
	var move_labels := [preview_move_1, preview_move_2, preview_move_3, preview_move_4]
	for i in range(4):
		if i < char_data.moves.size():
			var move := DataRegistry.get_move(char_data.moves[i])
			if move != null:
				move_labels[i].text = "%s (%s)" % [move.name, TypeEnums.Type.keys()[move.type]]
				move_labels[i].show()
			else:
				move_labels[i].text = "???"
				move_labels[i].show()
		else:
			move_labels[i].hide()

	preview_desc.text = char_data.description if char_data.description else ""
	stats_preview.show()


## Formats character types for display.
func _format_type(primary: int, secondary: int) -> String:
	var result: String = TypeEnums.Type.keys()[primary]
	if secondary >= 0:
		result += "/" + TypeEnums.Type.keys()[secondary]
	return result


## Called when the mouse exits a character button.
func _on_character_hover_exit() -> void:
	stats_preview.hide()


## Called when the Deploy button is pressed.
func _on_deploy_pressed() -> void:
	if _selected_ids.size() != 3:
		return

	# Register battle party selection
	GameManager.corps_roster.set_battle_selection(_selected_ids)

	# Transition to battle
	GameManager.transition_to_state(GameManager.GameState.BATTLE)


## Updates UI elements based on current selection state.
func _update_ui() -> void:
	phase_label.text = "Select 3 Characters to Deploy (%d/3)" % _selected_ids.size()
	deploy_button.disabled = _selected_ids.size() != 3

	# Update button visual states — highlight selected buttons
	for btn in _character_buttons:
		var char_id: String = btn.get_meta(&"char_id", "")
		if char_id.is_empty():
			continue
		if _selected_ids.has(char_id):
			(btn as Button).modulate = Color(0.7, 1.0, 0.7) # Green tint for selected
		else:
			(btn as Button).modulate = Color(1, 1, 1) # Normal
