## GameManager autoload singleton.
## Central state machine for managing game flow and scene transitions.
## TITLE is the navigation hub: it can reach CORPS_SETTINGS,
## CHARACTER_SELECT, and SETTINGS. All sub-screens return to TITLE
## via a back button. BATTLE → RESULT → TITLE completes the loop.
extends Node

## Application states for the game state machine.
enum GameState {
	TITLE, ## Title screen is active. Entry point and navigation hub.
	CORPS_SETTINGS, ## Corps settings screen is active (select & save 6-character corps).
	CHARACTER_SELECT, ## Battle preparation screen is active (pick 3 from saved corps).
	BATTLE, ## Battle scene is active (managed by Unit 3).
	RESULT, ## Battle result screen is active.
	SETTINGS ## Settings screen is active (language + volume).
}

## Currently active game state.
var current_state: GameState = GameState.TITLE

## The player's corps roster for battle preparation.
var corps_roster: RefCounted


func _ready() -> void:
	# Initialize corps_roster using preload to ensure class is resolved
	corps_roster = preload("res://scripts/foundation/corps_roster.gd").new()
	# Restore saved corps data if available
	var save_data := SaveManager.current_data
	if save_data.has("corps_characters") and save_data["corps_characters"] is Array:
		if save_data["corps_characters"].size() == 6:
			corps_roster.restore_from_save(save_data)
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

	current_state = target_state
	_process_state(current_state)
	return true


## Returns the scene path for the given game state.
func get_scene_for_state(state: GameState) -> String:
	match state:
		GameState.TITLE:
			return "res://scenes/title_screen.tscn"
		GameState.CORPS_SETTINGS:
			return "res://scenes/corps_creation.tscn"
		GameState.CHARACTER_SELECT:
			return "res://scenes/character_select.tscn"
		GameState.BATTLE:
			return "res://scenes/battle_scene.tscn"
		GameState.RESULT:
			return "res://scenes/result_screen.tscn"
		GameState.SETTINGS:
			return "res://scenes/settings_screen.tscn"
	return ""


## Validates whether a transition between states is allowed.
func _is_valid_transition(from: GameState, to: GameState) -> bool:
	if from == to:
		return false

	match from:
		GameState.TITLE:
			return to == GameState.CORPS_SETTINGS \
				or to == GameState.CHARACTER_SELECT \
				or to == GameState.SETTINGS
		GameState.CORPS_SETTINGS:
			return to == GameState.TITLE
		GameState.CHARACTER_SELECT:
			return to == GameState.TITLE or to == GameState.BATTLE
		GameState.BATTLE:
			return to == GameState.RESULT
		GameState.RESULT:
			return to == GameState.TITLE
		GameState.SETTINGS:
			return to == GameState.TITLE
	return false


## Processes the current state, typically triggering a scene change.
func _process_state(state: GameState) -> void:
	var scene_path: String = get_scene_for_state(state)
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
