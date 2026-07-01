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

	# Transition to character select
	GameManager.transition_to_state(GameManager.GameState.CHARACTER_SELECT)


## Called when keyboard navigation is used.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()
