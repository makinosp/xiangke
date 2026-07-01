## BattleScene placeholder script.
## Placeholder for Unit 3 (Battle System). Provides a minimal battle screen
## that simulates battle completion to allow navigation through the game loop.
extends Control

## Reference to the battle status label.
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	status_label.text = "Battle in progress... (Unit 3 placeholder)"
	
	# Simulate battle end for testing the game loop
	await get_tree().create_timer(1.0).timeout
	_on_battle_ended(true)


## Called when the battle ends.
func _on_battle_ended(won: bool) -> void:
	# Record battle result in save data
	var data := SaveManager.current_data.duplicate()
	data["last_battle_won"] = won
	data["last_battle_time"] = Time.get_datetime_string_from_system()
	SaveManager.save_game(data)
	
	# Transition to result screen
	GameManager.transition_to_state(GameManager.GameState.RESULT)
