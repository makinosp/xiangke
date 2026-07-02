## ResultScreen script.
## Displays the outcome of a battle (Win/Loss) and allows returning to the title screen.
extends Control

## Reference to the result label (Win/Loss).
@onready var result_label: Label = $ResultLabel
## Reference to the return to title button.
@onready var return_button: Button = $ReturnButton


func _ready() -> void:
	var last_won: bool = SaveManager.current_data.get("last_battle_won", false)
	result_label.text = "Victory!" if last_won else "Defeat..."
	return_button.grab_focus()

	UIFocusManager.register_focus_group([return_button])


## Called when the "Return to Title" button is pressed.
func _on_return_button_pressed() -> void:
	GameManager.transition_to_state(GameManager.GameState.TITLE)
