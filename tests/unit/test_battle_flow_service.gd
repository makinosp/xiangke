## Tests for the front-line battle flow via BattleFlowService.
##
## Verifies that only the front character of each team acts, that switching
## with a benched character works for both teams, and that a defeated front is
## automatically replaced by the first living benched character.
extends "res://tests/test_base.gd"

var _service: BattleFlowService = null


func before_all() -> void:
	_register_test_characters()
	_service = BattleFlowService.new()


## Registers the fictional test characters in DataRegistry so that
## BattleParticipant.from_dict() can resolve their CharacterData.
func _register_test_characters() -> void:
	var specs := {
		"p_front": {"type": TypeEnums.Type.FIRE, "hp": 200},
		"p_bench1": {"type": TypeEnums.Type.WOOD, "hp": 150},
		"p_bench2": {"type": TypeEnums.Type.EARTH, "hp": 150},
		"e_front": {"type": TypeEnums.Type.WOOD, "hp": 200},
		"e_bench1": {"type": TypeEnums.Type.METAL, "hp": 150},
		"e_bench2": {"type": TypeEnums.Type.WATER, "hp": 150},
	}
	var registry := DataRegistry
	for char_id: String in specs:
		if not registry._characters.has(char_id):
			var cd := CharacterData.new()
			cd.id = char_id
			cd.name = char_id
			cd.type = specs[char_id]["type"]
			cd.secondary_type = -1
			cd.hp = specs[char_id]["hp"]
			cd.attack = 50
			cd.defense = 30
			cd.speed = 40
			cd.intelligence = 50
			cd.spirit = 30
			registry._characters[char_id] = cd


func test_rust_battle_system_class_available() -> int:
	return assert_true(ClassDB.class_exists("RustBattleSystem"),
		"RustBattleSystem GDExtension class should be registered")


func after_all() -> void:
	if _service != null:
		_service.stop_battle()
		_service.free()
		_service = null


## Builds a CharacterData with the given stats and moves.
func _make_char(id: String, type: int, hp: int, moves: PackedStringArray) -> CharacterData:
	var cd := CharacterData.new()
	cd.id = id
	cd.name = id
	cd.type = type
	cd.secondary_type = -1
	cd.hp = hp
	cd.attack = 50
	cd.defense = 30
	cd.speed = 40
	cd.intelligence = 50
	cd.spirit = 30
	cd.moves = moves
	return cd


## Builds a 3v3 battle where each team fields 3 characters.
func _start_3v3() -> bool:
	var fire_move := PackedStringArray(["fire_strike"])
	var wood_move := PackedStringArray(["wood_heal"])
	var player_chars: Array[CharacterData] = [
		_make_char("p_front", TypeEnums.Type.FIRE, 200, fire_move),
		_make_char("p_bench1", TypeEnums.Type.WOOD, 150, wood_move),
		_make_char("p_bench2", TypeEnums.Type.EARTH, 150, wood_move),
	]
	var enemy_chars: Array[CharacterData] = [
		_make_char("e_front", TypeEnums.Type.WOOD, 200, wood_move),
		_make_char("e_bench1", TypeEnums.Type.METAL, 150, fire_move),
		_make_char("e_bench2", TypeEnums.Type.WATER, 150, fire_move),
	]
	return _service.start_battle(player_chars, enemy_chars)


func test_start_battle_marks_one_front_per_team() -> int:
	if not _start_3v3():
		return assert_true(false, "start_battle should succeed")
	var err := OK
	err = assert_true(_service.get_front_participant(BattleParticipant.Team.PLAYER) != null,
		"Player team should have a front"); if err: return err
	err = assert_true(_service.get_front_participant(BattleParticipant.Team.ENEMY) != null,
		"Enemy team should have a front"); if err: return err
	err = assert_eq(_service.get_bench_participants(BattleParticipant.Team.PLAYER).size(), 2,
		"Player team should have 2 benched"); if err: return err
	return assert_eq(_service.get_bench_participants(BattleParticipant.Team.ENEMY).size(), 2,
		"Enemy team should have 2 benched")


func test_player_switch_moves_bench_to_front() -> int:
	if not _start_3v3():
		return assert_true(false, "start_battle should succeed")
	var front_before := _service.get_front_participant(BattleParticipant.Team.PLAYER)
	var bench := _service.get_bench_participants(BattleParticipant.Team.PLAYER)
	var err := OK
	err = assert_true(bench.size() > 0, "Player team should have bench members"); if err: return err

	var switched := _service.execute_switch(BattleParticipant.Team.PLAYER, bench[0].slot_index)
	err = assert_true(switched, "Player switch should succeed"); if err: return err

	var front_after := _service.get_front_participant(BattleParticipant.Team.PLAYER)
	err = assert_ne(front_after.character_data.id, front_before.character_data.id,
		"Front character should change after switch"); if err: return err
	return assert_eq(front_after.character_data.id, bench[0].character_data.id,
		"Switched-in bench member should now be front")


func test_enemy_switch_moves_bench_to_front() -> int:
	if not _start_3v3():
		return assert_true(false, "start_battle should succeed")
	var front_before := _service.get_front_participant(BattleParticipant.Team.ENEMY)
	var bench := _service.get_bench_participants(BattleParticipant.Team.ENEMY)
	var err := OK
	err = assert_true(bench.size() > 0, "Enemy team should have bench members"); if err: return err

	var switched := _service.execute_switch(BattleParticipant.Team.ENEMY, bench[0].slot_index)
	err = assert_true(switched, "Enemy switch should succeed"); if err: return err

	var front_after := _service.get_front_participant(BattleParticipant.Team.ENEMY)
	err = assert_ne(front_after.character_data.id, front_before.character_data.id,
		"Enemy front character should change after switch"); if err: return err
	return assert_eq(front_after.character_data.id, bench[0].character_data.id,
		"Switched-in enemy bench member should now be front")


func test_switch_preserves_stats_and_status() -> int:
	if not _start_3v3():
		return assert_true(false, "start_battle should succeed")
	var bench := _service.get_bench_participants(BattleParticipant.Team.PLAYER)
	var err := OK
	err = assert_true(bench.size() > 0, "Player team should have bench members"); if err: return err
	var target_id: String = bench[0].character_data.id

	var switched := _service.execute_switch(BattleParticipant.Team.PLAYER, bench[0].slot_index)
	err = assert_true(switched, "Player switch should succeed"); if err: return err

	var front := _service.get_front_participant(BattleParticipant.Team.PLAYER)
	err = assert_eq(front.character_data.id, target_id, "Front should be the switched-in member"); if err: return err
	return assert_eq(front.current_hp, front.max_hp,
		"Switched-in member should keep its HP")


func test_player_action_targets_enemy_front() -> int:
	if not _start_3v3():
		return assert_true(false, "start_battle should succeed")
	_ensure_player_turn()
	var enemy_front := _service.get_front_participant(BattleParticipant.Team.ENEMY)
	var err := OK
	err = assert_true(enemy_front != null, "Enemy front should exist"); if err: return err
	var front_id: String = enemy_front.character_data.id
	var enemy_hp_before: int = enemy_front.current_hp

	var fire_strike := DataRegistry.get_move("fire_strike")
	err = assert_true(fire_strike != null, "fire_strike move should exist"); if err: return err

	var result := _service.execute_player_action(fire_strike)
	err = assert_true(result.has("log_message"), "Action result should have a log message"); if err: return err

	var enemy_front_after := _service.get_front_participant(BattleParticipant.Team.ENEMY)
	err = assert_true(enemy_front_after != null, "Enemy front should still exist"); if err: return err
	err = assert_eq(enemy_front_after.character_data.id, front_id,
		"Enemy front should be unchanged (only front is targeted)"); if err: return err
	return assert_true(enemy_front_after.current_hp < enemy_hp_before,
		"Enemy front HP should decrease after the attack")


func test_defeated_front_auto_replaced() -> int:
	if not _start_3v3():
		return assert_true(false, "start_battle should succeed")
	var enemy_front := _service.get_front_participant(BattleParticipant.Team.ENEMY)
	var err := OK
	err = assert_true(enemy_front != null, "Enemy front should exist"); if err: return err
	var front_id: String = enemy_front.character_data.id

	# Repeatedly attack the enemy front with a strong move until it is defeated.
	var metal_slash := DataRegistry.get_move("metal_slash")
	err = assert_true(metal_slash != null, "metal_slash move should exist"); if err: return err

	var defeated := false
	for i in 40:
		_ensure_player_turn()
		var active := _service.get_active_participant()
		if active == null or active.team != BattleParticipant.Team.PLAYER:
			break
		var result := _service.execute_player_action(metal_slash)
		if not result.has("log_message"):
			break
		var front := _service.get_front_participant(BattleParticipant.Team.ENEMY)
		if front == null:
			break
		if front.character_data.id != front_id:
			defeated = true
			break

	err = assert_true(defeated, "Enemy front should eventually be defeated"); if err: return err

	# The first living benched enemy should have been promoted automatically.
	var new_front := _service.get_front_participant(BattleParticipant.Team.ENEMY)
	err = assert_true(new_front != null, "Enemy should still have a front after auto-replace"); if err: return err
	return assert_ne(new_front.character_data.id, front_id,
		"Enemy front should be replaced by a bench member")


## Advances turns until it is the player team's turn, or the turn cannot
## advance further.
func _ensure_player_turn() -> void:
	for i in 10:
		var active := _service.get_active_participant()
		if active == null or active.team == BattleParticipant.Team.PLAYER:
			return
		if not _service.advance_turn():
			return
