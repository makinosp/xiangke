## TitleScreen script.
## Controls the title screen UI: displays game title, a "Start" button,
## and initializes audio on first click (required for Web autoplay policy).
extends Control

## Reference to the version label.
@onready var version_label: Label = $VersionLabel
## Reference to the start button.
@onready var start_button: Button = $StartButton


func _ready() -> void:
	version_label.text = "v1.0.0"
	start_button.grab_focus()

	# Register with focus manager if available
	if UIFocusManager:
		UIFocusManager.register_focus_group([start_button])


## Called when the "Start" button is pressed.
func _on_start_button_pressed() -> void:
	# Initialize audio on first user interaction (Web autoplay policy)
	AudioManager.initialize_audio()

	# Load save data
	SaveManager.load_save()

	# Reset battle data but preserve saved corps
	GameManager.corps_roster.battle_characters.clear()
	GameManager.corps_roster.opponent_corps.clear()

	# If saved corps exists, restore it on the roster
	var save_data := SaveManager.current_data
	if save_data.has("corps_characters") and save_data["corps_characters"] is Array:
		if save_data["corps_characters"].size() == 6:
			GameManager.corps_roster.restore_from_save(save_data)
		else:
			GameManager.corps_roster.corps_characters.clear()
	else:
		GameManager.corps_roster.corps_characters.clear()

	# Transition to corps creation
	GameManager.transition_to_state(GameManager.GameState.CORPS_CREATION)


## Called when keyboard navigation is used.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()
