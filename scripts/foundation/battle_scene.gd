## BattleScene script.
## Main battle scene that connects the BattleFlowService with UI components.
## Handles player input for action selection and displays battle state.
extends Control

## Reference to the battle log RichTextLabel.
@onready var battle_log_label: RichTextLabel = $BattleLog
## Reference to the action buttons container.
@onready var action_container: VBoxContainer = $ActionContainer
## Reference to the move selection container.
@onready var move_container: VBoxContainer = $MoveContainer
## Reference to the status label for current turn info.
@onready var status_label: Label = $StatusLabel
## Reference to the player HP container for displaying party status.
@onready var player_hp_container: HBoxContainer = $PlayerHPContainer
## Reference to the enemy HP container.
@onready var enemy_hp_container: HBoxContainer = $EnemyHPContainer

## The battle flow service instance managing this battle.
var _flow_service: BattleFlowService = null
## The currently selected move for the active participant.
var _selected_move: MoveData = null
## The currently chosen target for the selected move.
var _selected_target_index: int = -1
## Whether the player is currently selecting a target.
var _is_selecting_target: bool = false
## Reference to the enemy participants for targeting.
var _enemy_participants: Array[BattleParticipant] = []


func _ready() -> void:
	# Create the battle flow service
	_flow_service = BattleFlowService.new()
	add_child(_flow_service)

	# Connect signals
	_flow_service.turn_started.connect(_on_turn_started)
	_flow_service.action_executed.connect(_on_action_executed)
	_flow_service.participant_defeated.connect(_on_participant_defeated)
	_flow_service.battle_ended.connect(_on_battle_ended)
	_flow_service.log_updated.connect(_on_log_updated)

	# Initialize the battle with player and enemy data
	_setup_battle()


## Sets up the battle with characters from corps roster.
func _setup_battle() -> void:
	# Get player character data from corps roster
	var roster: CorpsRoster = GameManager.corps_roster as CorpsRoster
	if roster == null:
		push_error("BattleScene: No corps roster found")
		return

	var battle_ids: Array[String] = roster.battle_characters
	if battle_ids.is_empty():
		push_error("BattleScene: No battle characters selected")
		return

	# Load player character data
	var player_chars: Array[CharacterData] = []
	for char_id: String in battle_ids:
		var char_data: CharacterData = DataRegistry.get_character(char_id)
		if char_data != null:
			player_chars.append(char_data)
		else:
			push_error("BattleScene: Character data not found: %s" % char_id)

	if player_chars.is_empty():
		push_error("BattleScene: No valid player characters")
		return

	# Use opponent corps as enemies
	var enemy_ids: Array[String] = roster.opponent_corps
	var enemy_chars: Array[CharacterData] = []
	for char_id: String in enemy_ids:
		var char_data: CharacterData = DataRegistry.get_character(char_id)
		if char_data != null:
			enemy_chars.append(char_data)

	if enemy_chars.is_empty():
		push_error("BattleScene: No enemy characters loaded")
		return

	# Start the battle
	var started := _flow_service.start_battle(player_chars, enemy_chars)
	if not started:
		status_label.text = "Failed to start battle!"
		return

	# Cache enemy participants for targeting
	_enemy_participants = _flow_service.get_enemy_participants()

	# Update HP displays
	_update_hp_displays()
	_update_log_display()

	# Start the battle loop after a brief delay for scene setup
	status_label.text = "%s's turn!" % _flow_service.battle_state.active_participant.character_data.name
	call_deferred("_show_move_selection")


## Shows the move selection UI for the current active participant.
func _show_move_selection() -> void:
	if _flow_service == null or _flow_service.battle_state == null:
		return

	var participant: BattleParticipant = _flow_service.battle_state.active_participant
	if participant == null:
		return

	_is_selecting_target = false
	action_container.hide()
	move_container.show()
	status_label.text = "Choose a move for %s:" % participant.character_data.name

	# Clear existing move buttons
	for child: Node in move_container.get_children():
		child.queue_free()

	# Create buttons for each move
	for i in range(participant.character_data.moves.size()):
		var move_id: String = participant.character_data.moves[i]
		var move_data: MoveData = DataRegistry.get_move(move_id)
		if move_data == null:
			continue

		var btn := Button.new()
		btn.text = "%s (Power: %d, Acc: %d%%)" % [move_data.name, move_data.power, move_data.accuracy]
		btn.connect("pressed", Callable(self, "_on_move_selected").bind(move_data))
		btn.size_flags_horizontal = Control.SIZE_EXPAND
		move_container.add_child(btn)

	# Add "Wait" option (skip turn)
	var wait_btn := Button.new()
	wait_btn.text = "Wait (Skip Turn)"
	wait_btn.connect("pressed", Callable(self, "_on_wait_selected"))
	move_container.add_child(wait_btn)


## Shows target selection for the selected move.
func _show_target_selection() -> void:
	move_container.hide()
	_is_selecting_target = true
	status_label.text = "Select a target for %s:" % _selected_move.name

	# Clear existing target buttons
	for child: Node in action_container.get_children():
		child.queue_free()

	# Enemy targets
	for i in _enemy_participants.size():
		var enemy: BattleParticipant = _enemy_participants[i]
		if enemy.is_defeated:
			continue

		var btn := Button.new()
		btn.text = "%s (HP: %d/%d)" % [
				enemy.character_data.name,
				enemy.current_hp,
				enemy.max_hp]
		btn.connect("pressed", Callable(self, "_on_target_selected").bind(i))
		action_container.add_child(btn)

	# Cancel button
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.connect("pressed", Callable(self, "_on_cancel_target_selection"))
	action_container.add_child(cancel_btn)

	action_container.show()


## Called when the player selects a move.
func _on_move_selected(move_data: MoveData) -> void:
	_selected_move = move_data
	_show_target_selection()


## Called when the player selects "Wait" (skip turn).
func _on_wait_selected() -> void:
	_selected_move = null
	_is_selecting_target = false
	_advance_turn()


## Called when the player selects a target.
func _on_target_selected(target_index: int) -> void:
	_selected_target_index = target_index
	_is_selecting_target = false

	if _selected_move != null and target_index >= 0 and target_index < _enemy_participants.size():
		var target: BattleParticipant = _enemy_participants[target_index]
		_flow_service.execute_player_action(_selected_move, target)
		_advance_turn()


## Called when cancelling target selection.
func _on_cancel_target_selection() -> void:
	_is_selecting_target = false
	action_container.hide()
	_show_move_selection()


## Advances the turn after a player action.
func _advance_turn() -> void:
	# Process end-of-turn for the current participant
	var participant := _flow_service.battle_state.active_participant if _flow_service.battle_state != null else null

	# Advance turn
	var has_next := BattleManager.advance_to_next_turn(_flow_service.battle_state)
	if not has_next:
		if _flow_service.battle_state != null:
			_flow_service.battle_state.battle_status = BattleState.Status.DEFEAT
		return

	_update_hp_displays()
	_update_log_display()

	# Evaluate win/loss
	if _flow_service.battle_state.evaluate_battle_status():
		_on_battle_ended(_flow_service.battle_state.battle_status)
		return

	# Start next turn
	status_label.text = "%s's turn!" % _flow_service.battle_state.active_participant.character_data.name
	_show_move_selection()


## Called when a participant's turn starts.
func _on_turn_started(participant: BattleParticipant) -> void:
	status_label.text = "%s is acting..." % participant.character_data.name
	_update_hp_displays()


## Called when an action is executed.
func _on_action_executed(result: ActionResult, source: BattleParticipant, target: BattleParticipant) -> void:
	_update_hp_displays()
	_update_log_display()
	if not result.log_message.is_empty():
		status_label.text = result.log_message

	# Animate damage/healing (simplified — just update display)
	if result.damage_dealt > 0:
		_tween_damage(source, target, result.damage_dealt)
	if result.recoil_damage > 0:
		_tween_damage(source, source, result.recoil_damage, Color.RED)


## Called when a participant is defeated.
func _on_participant_defeated(participant: BattleParticipant) -> void:
	status_label.text = "%s is defeated!" % participant.character_data.name
	_update_hp_displays()
	_update_log_display()


## Called when the battle ends.
func _on_battle_ended(status: int) -> void:
	# Save battle result
	var won: bool = (status == BattleState.Status.VICTORY)
	var data: Dictionary = SaveManager.current_data.duplicate()
	data["last_battle_won"] = won
	data["last_battle_time"] = Time.get_datetime_string_from_system()
	SaveManager.save_game(data)

	# Transition to result screen
	await get_tree().create_timer(0.5).timeout
	GameManager.transition_to_state(GameManager.GameState.RESULT)


## Called when a log message is updated.
func _on_log_updated(message: String) -> void:
	_update_log_display()


## Updates the HP displays for all participants.
func _update_hp_displays() -> void:
	if _flow_service == null or _flow_service.battle_state == null:
		return

	# Update player HPs
	_update_team_hp(player_hp_container, _flow_service.get_player_participants())

	# Update enemy HPs
	_update_team_hp(enemy_hp_container, _flow_service.get_enemy_participants())


## Updates HP labels for a team's container.
static func _update_team_hp(container: HBoxContainer, participants: Array[BattleParticipant]) -> void:
	for child: Node in container.get_children():
		child.queue_free()

	for p: BattleParticipant in participants:
		var label := Label.new()
		if p.is_defeated:
			label.text = "%s: DEFEATED" % p.character_data.name
			label.modulate = Color.GRAY
		else:
			label.text = "%s: %d/%d" % [p.character_data.name, p.current_hp, p.max_hp]
			# Color based on HP percentage
			var hp_ratio: float = float(p.current_hp) / float(p.max_hp)
			if hp_ratio < 0.25:
				label.modulate = Color.RED
			elif hp_ratio < 0.5:
				label.modulate = Color.YELLOW
			else:
				label.modulate = Color.WHITE
		container.add_child(label)


## Updates the battle log display.
func _update_log_display() -> void:
	if _flow_service == null or _flow_service.battle_state == null:
		return
	var recent: PackedStringArray = _flow_service.battle_state.get_recent_log(10)
	battle_log_label.text = "\n".join(recent)


## Tweens damage display for visual feedback.
static func _tween_damage(
		_source: BattleParticipant,
		_target: BattleParticipant,
		_amount: int,
		_color: Color = Color.WHITE) -> void:
	# Visual damage tween — placeholder for rich animation
	pass


## Handles keyboard input for UI navigation.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_selecting_target:
			_on_cancel_target_selection()
