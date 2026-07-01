## GameManager autoload singleton.
## Central state machine for managing game flow and scene transitions.
## Handles the four-state loop: TITLE → CHARACTER_SELECT → BATTLE → RESULT → TITLE.
extends Node

## Application states for the game state machine.
enum GameState {
	TITLE, ## Title screen is active. Entry point.
	CHARACTER_SELECT, ## Character selection screen is active.
	BATTLE, ## Battle scene is active (managed by Unit 3).
	RESULT ## Battle result screen is active.
}

## Emitted when the game state changes.
signal game_state_changed(new_state: GameState)
## Emitted when a scene transition is requested.
signal transition_requested(from_state: GameState, to_state: GameState)

## Currently active game state.
var current_state: GameState = GameState.TITLE

## The player's corps roster for battle preparation.
var corps_roster: RefCounted


func _ready() -> void:
	# Initialize corps_roster using preload to ensure class is resolved
	corps_roster = preload("res://scripts/foundation/corps_roster.gd").new()
	_process_state(current_state)


## Requests a transition to the target state.
##
## Parameters:
##   target_state: The state to transition to.
##
## Returns:
##   true if the transition was valid and initiated, false otherwise.
func transition_to_state(target_state: GameState) -> bool:
	if not _is_valid_transition(current_state, target_state):
		if OS.is_debug_build():
			push_error("GameManager: Invalid state transition: %s → %s" % [
				GameState.keys()[current_state],
				GameState.keys()[target_state]
			])
		return false

	emit_signal("transition_requested", current_state, target_state)
	current_state = target_state
	emit_signal("game_state_changed", current_state)
	_process_state(current_state)
	return true


## Returns the scene path for the given game state.
func get_scene_for_state(state: GameState) -> String:
	match state:
		GameState.TITLE:
			return "res://scenes/title_screen.tscn"
		GameState.CHARACTER_SELECT:
			return "res://scenes/character_select.tscn"
		GameState.BATTLE:
			return "res://scenes/battle_scene.tscn"
		GameState.RESULT:
			return "res://scenes/result_screen.tscn"
	return ""


## Validates whether a transition between states is allowed.
func _is_valid_transition(from: GameState, to: GameState) -> bool:
	if from == to:
		return false

	match from:
		GameState.TITLE:
			return to == GameState.CHARACTER_SELECT
		GameState.CHARACTER_SELECT:
			return to == GameState.BATTLE
		GameState.BATTLE:
			return to == GameState.RESULT
		GameState.RESULT:
			return to == GameState.TITLE
	return false


## Processes the current state, typically triggering a scene change.
func _process_state(state: GameState) -> void:
	var scene_path := get_scene_for_state(state)
	if scene_path.is_empty():
		push_error("GameManager: No scene path for state: %s" % GameState.keys()[state])
		return
	
	# Use SceneTransition for animated transitions
	var transition := get_node("/root/SceneTransitionLayer") as Node
	if transition and transition.has_method("transition_to"):
		transition.transition_to(scene_path)
	else:
		# Fallback to direct scene change if transition layer not available
		get_tree().change_scene_to_file(scene_path)
