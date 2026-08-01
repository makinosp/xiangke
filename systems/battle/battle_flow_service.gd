class_name BattleFlowService
extends Node

## Emitted when a new turn starts.
signal turn_started(participant: BattleParticipant)

## Emitted after an action is executed.
signal action_executed(result: Dictionary, source: BattleParticipant, target: BattleParticipant)

## Emitted when a participant is defeated.
signal participant_defeated(participant: BattleParticipant)

## Emitted when the battle ends.
signal battle_ended(status: int)

## Emitted when a log message is added.
signal log_updated(message: String)

var _rust_system: RustBattleSystem

var _battle_participants: Array[BattleParticipant] = []


## Initializes the Rust battle system as a child node.
func _init() -> void:
	_rust_system = RustBattleSystem.new()
	add_child(_rust_system)


## Starts a new battle with the given player and enemy characters.
## Returns true if the battle started successfully.
func start_battle(
		player_chars: Array[CharacterData],
		enemy_chars: Array[CharacterData]) -> bool:
	_rust_system = RustBattleSystem.new()
	add_child(_rust_system)
	_battle_participants.clear()

	var player_arr := _serialize_characters(player_chars)
	var enemy_arr := _serialize_characters(enemy_chars)
	var move_registry := _serialize_move_registry()

	var started := _rust_system.start_battle(player_arr, enemy_arr, move_registry)
	if not started:
		return false

	_build_participants(enemy_chars, BattleParticipant.Team.ENEMY)
	_build_participants(player_chars, BattleParticipant.Team.PLAYER)

	return true


## Builds the local participant cache for a team.
func _build_participants(chars: Array[CharacterData], team: BattleParticipant.Team) -> void:
	for i in chars.size():
		var character_data := chars[i].duplicate() as CharacterData
		var participant := BattleParticipant.new()
		participant.character_data = character_data
		participant.current_hp = character_data.hp
		participant.max_hp = character_data.hp
		participant.team = team
		participant.slot_index = i
		participant.is_defeated = false
		participant.stat_stages = [0, 0, 0, 0, 0]
		participant.active_status_effects = []
		_battle_participants.append(participant)


## Executes a player action (move) and returns the result dictionary.
func execute_player_action(move: MoveData) -> Dictionary:
	var move_payload := _serialize_move(move)
	return _rust_system.execute_player_action(move_payload)


## Switches the team's front character with a benched participant.
## Returns true on success.
func execute_switch(team: int, bench_index: int) -> bool:
	return _rust_system.execute_switch(team, bench_index)


## Returns the front participant of the given team, or null if none alive.
func get_front_participant(team: int) -> BattleParticipant:
	var participant_data := _rust_system.get_front_participant(team)
	if participant_data.is_empty():
		return null
	return BattleParticipant.from_dict(participant_data)


## Returns all living benched participants of the given team.
func get_bench_participants(team: int) -> Array[BattleParticipant]:
	var result: Array[BattleParticipant] = []
	var bench_participants_data := _rust_system.get_bench_participants(team)
	for i in bench_participants_data.size():
		result.append(BattleParticipant.from_dict(bench_participants_data[i]))
	return result


## Auto-replaces a defeated front participant with the first living benched one.
## Returns true if a replacement entered the front.
func replace_front_if_defeated(team: int) -> bool:
	return _rust_system.auto_replace_participant(team)


## Advances the turn to the next participant. Returns true on success.
func advance_turn() -> bool:
	return _rust_system.advance_turn()


## Returns all player participants (front + bench).
func get_player_participants() -> Array[BattleParticipant]:
	var result: Array[BattleParticipant] = []
	var player_participants_data := _rust_system.get_player_participants()
	for i in player_participants_data.size():
		result.append(BattleParticipant.from_dict(player_participants_data[i]))
	return result


## Returns all enemy participants (front + bench).
func get_enemy_participants() -> Array[BattleParticipant]:
	var result: Array[BattleParticipant] = []
	var enemy_participants_data := _rust_system.get_enemy_participants()
	for i in enemy_participants_data.size():
		result.append(BattleParticipant.from_dict(enemy_participants_data[i]))
	return result


## Returns the currently active participant, or null.
func get_active_participant() -> BattleParticipant:
	var participant_data := _rust_system.get_active_participant()
	if participant_data.is_empty():
		return null
	return BattleParticipant.from_dict(participant_data)


## Returns the index of the currently active participant.
func get_active_participant_index() -> int:
	return _rust_system.get_active_participant_index()


## Returns the most recent battle log messages.
func get_recent_log(count: int) -> PackedStringArray:
	var result := PackedStringArray()
	var log_messages := _rust_system.get_recent_log(count)
	for i in log_messages.size():
		result.append(log_messages[i])
	return result


## Returns the current battle status code.
func get_battle_status() -> int:
	return _rust_system.get_battle_status()


## Evaluates and returns the battle status code.
func evaluate_battle_status() -> int:
	return _rust_system.evaluate_battle_status()


## Processes start-of-turn effects for a participant.
func process_start_of_turn(participant_index: int) -> PackedStringArray:
	var logs := PackedStringArray()
	var turn_logs := _rust_system.process_start_of_turn(participant_index)
	for i in turn_logs.size():
		logs.append(turn_logs[i])
	return logs


## Processes end-of-turn effects for a participant.
func process_end_of_turn(participant_index: int) -> PackedStringArray:
	var logs := PackedStringArray()
	var turn_logs := _rust_system.process_end_of_turn(participant_index)
	for i in turn_logs.size():
		logs.append(turn_logs[i])
	return logs


## Returns a participant by index, or null if not found.
func get_participant(index: int) -> BattleParticipant:
	var participant_data := _rust_system.get_participant(index)
	if participant_data.is_empty():
		return null
	return BattleParticipant.from_dict(participant_data)


## Returns the total number of participants.
func get_participant_count() -> int:
	return _rust_system.get_participant_count()


## Returns the name of a participant by index.
func get_participant_name(index: int) -> String:
	return _rust_system.get_participant_name(index)


## Checks if a participant is defeated.
func is_participant_defeated(index: int) -> bool:
	return _rust_system.is_participant_defeated(index)


## Stops the battle and clears the Rust system reference.
func stop_battle() -> void:
	_rust_system = null


## Adds a log message to the battle log.
func add_log_message(message: String) -> void:
	_rust_system.add_log_message(message)


## Serializes an array of CharacterData for the Rust boundary.
func _serialize_characters(chars: Array[CharacterData]) -> Array:
	var serialized_characters: Array = []
	for character_data in chars:
		serialized_characters.append({
			"id": character_data.id,
			"name": character_data.name,
			"type": character_data.type,
			"secondary_type": character_data.secondary_type,
			"hp": character_data.hp,
			"attack": character_data.attack,
			"defense": character_data.defense,
			"speed": character_data.speed,
			"intelligence": character_data.intelligence,
			"spirit": character_data.spirit,
			"moves": Array(character_data.moves),
			"description": character_data.description,
		})
	return serialized_characters


## Serializes a single MoveData for the Rust boundary.
func _serialize_move(move: MoveData) -> Dictionary:
	return {
		"id": move.id,
		"name": move.name,
		"type": move.type,
		"power": move.power,
		"accuracy": move.accuracy,
		"effect": move.effect,
		"effect_chance": move.effect_chance,
		"stat_mod_stat": move.stat_mod_stat,
		"stat_mod_stage": move.stat_mod_stage,
		"hit_count": move.hit_count,
		"recoil": move.recoil,
		"healing": move.healing,
		"damage_category": move.damage_category,
		"description": move.description,
	}


## Builds the move registry (ID -> serialized move) for the Rust boundary.
func _serialize_move_registry() -> Dictionary:
	var serialized_move_registry := {}
	for move_id in DataRegistry.get_all_moves():
		var move := DataRegistry.get_move(move_id)
		if move == null:
			continue
		serialized_move_registry[move_id] = _serialize_move(move)
	return serialized_move_registry
