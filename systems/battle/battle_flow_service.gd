class_name BattleFlowService
extends Node

signal turn_started(participant: BattleParticipant)
signal action_executed(result: Dictionary, source: BattleParticipant, target: BattleParticipant)
signal participant_defeated(participant: BattleParticipant)
signal battle_ended(status: int)
signal log_updated(message: String)

var _rust_system: RustBattleSystem

var _battle_participants: Array[BattleParticipant] = []


func _init() -> void:
	_rust_system = RustBattleSystem.new()
	add_child(_rust_system)


func start_battle(
		player_chars: Array[CharacterData],
		enemy_chars: Array[CharacterData]) -> bool:
	_rust_system = RustBattleSystem.new()
	add_child(_rust_system)
	_battle_participants.clear()

	var player_arr := _build_char_array(player_chars)
	var enemy_arr := _build_char_array(enemy_chars)
	var move_lookup := _build_move_lookup()

	var started := _rust_system.start_battle(player_arr, enemy_arr, move_lookup)
	if not started:
		return false

	_build_participants(enemy_chars, BattleParticipant.Team.ENEMY)
	_build_participants(player_chars, BattleParticipant.Team.PLAYER)

	return true


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


func execute_player_action(move: MoveData) -> Dictionary:
	var move_dict := _build_move_dict(move)
	return _rust_system.execute_player_action(move_dict)


## Switches the team's front character with a living benched participant.
## Team: 0 = player, 1 = enemy. Returns true on success.
func execute_switch(team: int, bench_index: int) -> bool:
	return _rust_system.execute_switch(team, bench_index)


## Returns the front participant of the given team (0 = player, 1 = enemy),
## or null if the team has no living front character.
func get_front_participant(team: int) -> BattleParticipant:
	var participant_dict := _rust_system.get_front_participant(team)
	if participant_dict.is_empty():
		return null
	return BattleParticipant.from_dict(participant_dict)


## Returns the living benched participants of the given team (0 = player,
## 1 = enemy).
func get_bench_participants(team: int) -> Array[BattleParticipant]:
	var result: Array[BattleParticipant] = []
	var bench_participant_dicts := _rust_system.get_bench_participants(team)
	for i in bench_participant_dicts.size():
		result.append(BattleParticipant.from_dict(bench_participant_dicts[i]))
	return result


## Automatically brings the first living benched participant of a team to the
## front when the team has no living front character (i.e. the front was
## defeated). Team: 0 = player, 1 = enemy. Returns true if a replacement
## entered.
func replace_front_if_defeated(team: int) -> bool:
	return _rust_system.auto_replace_participant(team)


func advance_turn() -> bool:
	return _rust_system.advance_turn()


func get_player_participants() -> Array[BattleParticipant]:
	var result: Array[BattleParticipant] = []
	var player_participant_dicts := _rust_system.get_player_participants()
	for i in player_participant_dicts.size():
		result.append(BattleParticipant.from_dict(player_participant_dicts[i]))
	return result


func get_enemy_participants() -> Array[BattleParticipant]:
	var result: Array[BattleParticipant] = []
	var enemy_participant_dicts := _rust_system.get_enemy_participants()
	for i in enemy_participant_dicts.size():
		result.append(BattleParticipant.from_dict(enemy_participant_dicts[i]))
	return result


func get_active_participant() -> BattleParticipant:
	var participant_dict := _rust_system.get_active_participant()
	if participant_dict.is_empty():
		return null
	return BattleParticipant.from_dict(participant_dict)


func get_active_participant_index() -> int:
	return _rust_system.get_active_participant_index()


func get_recent_log(count: int) -> PackedStringArray:
	var result := PackedStringArray()
	var log_messages := _rust_system.get_recent_log(count)
	for i in log_messages.size():
		result.append(log_messages[i])
	return result


func get_battle_status() -> int:
	return _rust_system.get_battle_status()


func evaluate_battle_status() -> int:
	return _rust_system.evaluate_battle_status()


func process_start_of_turn(participant_index: int) -> PackedStringArray:
	var logs := PackedStringArray()
	var turn_logs := _rust_system.process_start_of_turn(participant_index)
	for i in turn_logs.size():
		logs.append(turn_logs[i])
	return logs


func process_end_of_turn(participant_index: int) -> PackedStringArray:
	var logs := PackedStringArray()
	var turn_logs := _rust_system.process_end_of_turn(participant_index)
	for i in turn_logs.size():
		logs.append(turn_logs[i])
	return logs


func get_participant(index: int) -> BattleParticipant:
	var participant_dict := _rust_system.get_participant(index)
	if participant_dict.is_empty():
		return null
	return BattleParticipant.from_dict(participant_dict)


func get_participant_count() -> int:
	return _rust_system.get_participant_count()


func get_participant_name(index: int) -> String:
	return _rust_system.get_participant_name(index)


func is_participant_defeated(index: int) -> bool:
	return _rust_system.is_participant_defeated(index)


func stop_battle() -> void:
	_rust_system = null


func add_log_message(message: String) -> void:
	_rust_system.add_log_message(message)


func _build_char_array(chars: Array[CharacterData]) -> Array:
	var character_dicts: Array = []
	for character_data in chars:
		character_dicts.append({
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
	return character_dicts


func _build_move_dict(move: MoveData) -> Dictionary:
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


func _build_move_lookup() -> Dictionary:
	var lookup := {}
	for move_id in DataRegistry.get_all_moves():
		var move := DataRegistry.get_move(move_id) as MoveData
		if move == null:
			continue
		lookup[move_id] = _build_move_dict(move)
	return lookup
