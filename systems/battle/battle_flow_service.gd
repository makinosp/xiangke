## BattleFlowService class.
## Coordinates the high-level battle loop: orchestrates turns, actions, and win/loss evaluation.
## Designed to be attached to a Node for signal emission.
class_name BattleFlowService
extends Node

## Emitted when a participant's turn begins.
signal turn_started(participant: BattleParticipant)
## Emitted when an action has been executed and resolved.
signal action_executed(result: ActionSystem.ActionResult, source: BattleParticipant, target: BattleParticipant)
## Emitted when a participant is defeated.
signal participant_defeated(participant: BattleParticipant)
## Emitted when the battle ends with a final status.
signal battle_ended(status: int)
## Emitted when a log entry is added.
signal log_updated(message: String)

## The battle state for the current battle.
var battle_state: BattleState = null
## Whether the battle is currently running its loop.
var _is_running: bool = false
## Whether the battle loop should stop.
var _should_stop: bool = false

## Holds the most recent player action target (set by UI)
var _last_player_target: BattleParticipant = null


## Initializes and starts a new battle.
##
## Parameters:
##   player_chars: Array of CharacterData for the player's team.
##   enemy_chars: Array of CharacterData for the enemy's team.
##
## Returns:
##   true if the battle started successfully.
func start_battle(
		player_chars: Array[CharacterData],
		enemy_chars: Array[CharacterData]) -> bool:
	assert(not player_chars.is_empty(), "BattleFlowService: must have at least 1 player character")
	assert(not enemy_chars.is_empty(), "BattleFlowService: must have at least 1 enemy character")

	# Create participants from character data
	var player_participants: Array[BattleParticipant] = []
	for i in player_chars.size():
		var p := BattleParticipant.create(player_chars[i], BattleParticipant.Team.PLAYER, i)
		player_participants.append(p)

	var enemy_participants: Array[BattleParticipant] = []
	for i in enemy_chars.size():
		var p := BattleParticipant.create(enemy_chars[i], BattleParticipant.Team.ENEMY, i)
		enemy_participants.append(p)

	# Create battle state
	battle_state = BattleState.create(player_participants, enemy_participants)

	# Start the battle
	var started = BattleManager.start_battle(battle_state)
	if not started:
		push_error("BattleFlowService: failed to start battle")
		return false

	_is_running = true
	_should_stop = false
	return true


## Processes the full battle loop asynchronously.
## Yield points allow the UI to update between turns.
##
## This should be called from a coroutine context (await).
func run_battle_loop() -> void:
	assert(battle_state != null, "BattleFlowService: battle not initialized, call start_battle first")
	assert(_is_running, "BattleFlowService: battle not running")

	while _is_running and not _should_stop:
		# Check win/loss at start of each turn
		if battle_state.evaluate_battle_status():
			_end_battle()
			return

		var current_participant: BattleParticipant = battle_state.active_participant
		battle_state.add_log("%s's turn begins." % current_participant.character_data.name)
		emit_signal("log_updated", battle_state.battle_log[battle_state.battle_log.size() - 1])

		# Emit turn started signal (UI listens to this)
		emit_signal("turn_started", current_participant)

		# Process start-of-turn effects (status effects, etc.)
		_process_start_of_turn(current_participant)

		# Yield to allow UI to update
		await get_tree().process_frame

		# Request action: AI for enemies, signal for player
		var action_result: ActionSystem.ActionResult = null
		var target: BattleParticipant = null

		if current_participant.team == BattleParticipant.Team.ENEMY:
			var action: Dictionary = _get_ai_action(current_participant)
			if action == null:
				# AI skipped turn (e.g., confused and hit self)
				action_result = ActionSystem.ActionResult.new()
				action_result.log_message = "%s is confused and can't move!" % current_participant.character_data.name
			else:
				target = action["target"] as BattleParticipant
				var move := action["move"] as MoveData
				action_result = ActionSystem.calculate_damage(current_participant, target, move)
		else:
			# Player action: must be provided externally via execute_player_action()
			action_result = await _wait_for_player_action()
			# After waiting, check if battle should stop
			if _should_stop or action_result == null:
				return
		# Retrieve the target that was set by execute_player_action()
		target = _pending_target
		# Advance to next turn
		var has_next: bool = BattleManager.advance_to_next_turn(battle_state)
		if not has_next:
			battle_state.battle_status = BattleState.Status.DEFEAT
			battle_state.add_log("No active participants remaining!")
			_end_battle()
			return

		# Yield to allow UI updates between turns
		await get_tree().process_frame


## Executes a player's chosen action.
## Called by the UI layer when the player selects a move and target.
##
## Parameters:
##   move: The MoveData to use.
##   target: The target BattleParticipant.
##
## Returns:
##   The ActionSystem.ActionResult from the executed move.
func execute_player_action(move: MoveData, target: BattleParticipant) -> ActionSystem.ActionResult:
	assert(move != null, "BattleFlowService: move must not be null")
	assert(target != null, "BattleFlowService: target must not be null")

	var participant = battle_state.active_participant as BattleParticipant
	assert(participant != null, "BattleFlowService: no active participant")
	assert(participant.team == BattleParticipant.Team.PLAYER,
			"BattleFlowService: cannot execute player action for enemy team")

	var result := ActionSystem.calculate_damage(participant, target, move)
	_pending_action_result = result
	_pending_target = target
	_has_pending_action = true
	return result


## Stops the battle loop.
func stop_battle() -> void:
	_should_stop = true


## Returns player participants from the battle state.
func get_player_participants() -> Array[BattleParticipant]:
	assert(battle_state != null, "BattleFlowService: battle not initialized")
	return battle_state.get_player_participants()


## Returns enemy participants from the battle state.
func get_enemy_participants() -> Array[BattleParticipant]:
	assert(battle_state != null, "BattleFlowService: battle not initialized")
	return battle_state.get_enemy_participants()


# --- Private members ---

var _has_pending_action: bool = false
var _pending_action_result: ActionSystem.ActionResult = null
var _pending_target: BattleParticipant = null


## Waits for the player to provide an action via execute_player_action().
## This is a non-static method that yields until player input is received.
func _wait_for_player_action() -> ActionSystem.ActionResult:
	# Yield until player provides an action
	while not _has_pending_action and not _should_stop:
		await get_tree().process_frame
	
	if _should_stop:
		return null
	
	# Retrieve and clear the pending action
	var result := _pending_action_result
	var target := _pending_target
	
	_has_pending_action = false
	_pending_action_result = null
	_pending_target = null
	
	return result


## Gets an AI-controlled action for an enemy participant.
##
## Parameters:
##   participant: The enemy BattleParticipant.
##
## Returns:
##   Dictionary with "move" (MoveData) and "target" (BattleParticipant) keys, or null.
func _get_ai_action(participant: BattleParticipant) -> Dictionary:
	assert(participant != null, "BattleFlowService: participant must not be null")
	assert(participant.team == BattleParticipant.Team.ENEMY,
			"BattleFlowService: AI action requested for non-enemy participant")

	# Cannot act if no battle state
	if battle_state == null:
		return {}

	var target: BattleParticipant = _find_weakest_enemy(participant)
	var move: MoveData = _select_best_move(participant, target)

	if move == null or target == null:
		# Fallback: use first move on first target
		var enemy_participants: Array[BattleParticipant] = battle_state.get_player_participants()
		if enemy_participants.is_empty():
			return {}

		target = enemy_participants[0]
		var move_id: String = participant.character_data.moves[0] if not participant.character_data.moves.is_empty() else ""
		if move_id.is_empty():
			return {}
		move = DataRegistry.get_move(move_id)
		if move == null:
			return {}

	return {"move": move, "target": target}


## Finds the weakest (lowest HP percentage) non-defeated player participant.
func _find_weakest_enemy(_self_participant: BattleParticipant) -> BattleParticipant:
	if battle_state == null:
		return null

	var players: Array[BattleParticipant] = battle_state.get_player_participants()
	var weakest: BattleParticipant = null
	var lowest_hp_ratio: float = 999.0

	for p: BattleParticipant in players:
		if p.is_defeated:
			continue
		var hp_ratio: float = float(p.current_hp) / float(p.max_hp)
		if hp_ratio < lowest_hp_ratio:
			lowest_hp_ratio = hp_ratio
			weakest = p

	return weakest


## Selects the best move for the AI to use.
func _select_best_move(participant: BattleParticipant, target: BattleParticipant) -> MoveData:
	if target == null:
		return null

	# Simple AI: find the most damaging move considering type effectiveness
	var best_move: MoveData = null
	var best_score: float = -1.0

	for move_id: String in participant.character_data.moves:
		var move_data: MoveData = DataRegistry.get_move(move_id)
		if move_data == null:
			continue

		# Skip healing moves for now (AI only attacks)
		if move_data.healing > 0:
			continue

		# Score based on power and type effectiveness
		var score: float = float(move_data.power)
		if score <= 0.0:
			continue

		# Factor in type effectiveness
		var type_chart := TypeChart.new()
		var effectiveness: float = type_chart.resolve_type_effectiveness(
				move_data.type,
				target.character_data.type,
				target.character_data.secondary_type)
		score *= effectiveness

		# Factor in accuracy as a discount
		score *= float(move_data.accuracy) / 100.0

		if score > best_score:
			best_score = score
			best_move = move_data

	return best_move


## Processes start-of-turn effects (status effects, etc.).
static func _process_start_of_turn(participant: BattleParticipant) -> void:
	# Check for confusion
	for effect: StatusEffectData in participant.active_status_effects:
		if effect.effect_type == TypeEnums.EffectType.CONFUSION:
			# Confusion may cause the participant to skip their turn
			pass


## Processes end-of-turn effects (damage-over-time, duration decrement).
static func _process_end_of_turn(participant: BattleParticipant) -> void:
	var expired_effects: Array[int] = []

	for i in participant.active_status_effects.size():
		var effect: StatusEffectData = participant.active_status_effects[i]
		if effect == null:
			continue

		# Process damage-over-time
		if effect.has_damage_over_time():
			var damage: int = maxi(1, int(participant.max_hp * effect.damage_per_turn))
			participant.take_damage(damage)

	# Remove expired effects (simplified — duration tracking in future iterations)


## Ends the battle and cleans up.
func _end_battle() -> void:
	_is_running = false
	var status: int = battle_state.battle_status if battle_state != null else BattleState.Status.DEFEAT
	emit_signal("battle_ended", status)
