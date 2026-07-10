extends Control

@onready var battle_log_label: RichTextLabel = $BattleLog
@onready var action_container: VBoxContainer = $ActionContainer
@onready var move_container: VBoxContainer = $MoveContainer
@onready var status_label: Label = $StatusLabel
@onready var player_hp_container: HBoxContainer = $PlayerHPContainer
@onready var enemy_hp_container: HBoxContainer = $EnemyHPContainer

var _flow_service: BattleFlowService = null
var _selected_move: MoveData = null
var _selected_target_index: int = -1
var _is_selecting_target: bool = false


func _ready() -> void:
	_flow_service = BattleFlowService.new()
	add_child(_flow_service)
	_setup_battle()


func _setup_battle() -> void:
	var roster: CorpsRoster = GameManager.corps_roster as CorpsRoster
	if roster == null:
		push_error("BattleScene: No corps roster found")
		return

	var battle_ids: Array[String] = roster.battle_characters
	if battle_ids.is_empty():
		push_error("BattleScene: No battle characters selected")
		return

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

	var enemy_ids: Array[String] = roster.opponent_corps
	var enemy_chars: Array[CharacterData] = []
	for char_id: String in enemy_ids:
		var char_data: CharacterData = DataRegistry.get_character(char_id)
		if char_data != null:
			enemy_chars.append(char_data)

	if enemy_chars.is_empty():
		push_error("BattleScene: No enemy characters loaded")
		return

	var started := _flow_service.start_battle(player_chars, enemy_chars)
	if not started:
		status_label.text = "Failed to start battle!"
		return

	_update_hp_displays()
	_update_log_display()

	var participant := _flow_service.get_active_participant()
	if participant != null:
		status_label.text = "%s's turn!" % participant.character_data.name
	call_deferred("_handle_current_turn")


func _handle_current_turn() -> void:
	var participant := _flow_service.get_active_participant()
	if participant == null:
		return

	var active_idx := _flow_service.get_active_participant_index()
	var start_logs := _flow_service.process_start_of_turn(active_idx)
	for msg in start_logs:
		_on_log_updated(msg)

	_update_hp_displays()
	_update_log_display()

	var status := _flow_service.evaluate_battle_status()
	if status != BattleState.Status.ACTIVE:
		_on_battle_ended(status)
		return

	if participant.team == BattleParticipant.Team.PLAYER:
		status_label.text = "%s's turn!" % participant.character_data.name
		_show_move_selection()
	else:
		_execute_ai_turn()


func _show_move_selection() -> void:
	if _flow_service == null:
		return

	var participant := _flow_service.get_active_participant()
	if participant == null or participant.character_data == null:
		return

	_is_selecting_target = false
	action_container.hide()
	move_container.show()

	for child: Node in move_container.get_children():
		child.queue_free()

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

	var wait_btn := Button.new()
	wait_btn.text = "Wait (Skip Turn)"
	wait_btn.connect("pressed", Callable(self, "_on_wait_selected"))
	move_container.add_child(wait_btn)


func _show_target_selection() -> void:
	move_container.hide()
	_is_selecting_target = true
	status_label.text = "Select a target for %s:" % _selected_move.name

	for child: Node in action_container.get_children():
		child.queue_free()

	var total := _flow_service.get_participant_count()
	for i in total:
		if _flow_service.is_participant_defeated(i):
			continue
		var p := _flow_service.get_participant(i)
		if p == null or p.team != BattleParticipant.Team.ENEMY:
			continue

		var btn := Button.new()
		btn.text = "%s (HP: %d/%d)" % [
				p.character_data.name if p.character_data != null else "Unknown",
				p.current_hp,
				p.max_hp]
		btn.connect("pressed", Callable(self, "_on_target_selected").bind(i))
		action_container.add_child(btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.connect("pressed", Callable(self, "_on_cancel_target_selection"))
	action_container.add_child(cancel_btn)

	action_container.show()


func _on_move_selected(move_data: MoveData) -> void:
	_selected_move = move_data
	_show_target_selection()


func _on_wait_selected() -> void:
	_selected_move = null
	_is_selecting_target = false
	_advance_turn()


func _on_target_selected(target_index: int) -> void:
	_selected_target_index = target_index
	_is_selecting_target = false

	if _selected_move != null:
		var result := _flow_service.execute_player_action(_selected_move, target_index)
		status_label.text = result.get("log_message", "Action executed.")
		_update_hp_displays()
		_update_log_display()
		_advance_turn()


func _on_cancel_target_selection() -> void:
	_is_selecting_target = false
	action_container.hide()
	_show_move_selection()


func _advance_turn() -> void:
	var current_idx := _flow_service.get_active_participant_index()
	if current_idx >= 0:
		var logs := _flow_service.process_end_of_turn(current_idx)
		for msg in logs:
			_on_log_updated(msg)
		_update_hp_displays()
		_update_log_display()

		var status := _flow_service.evaluate_battle_status()
		if status != BattleState.Status.ACTIVE:
			_on_battle_ended(status)
			return

	var has_next := _flow_service.advance_turn()
	if not has_next:
		_on_battle_ended(_flow_service.get_battle_status())
		return

	var active_idx := _flow_service.get_active_participant_index()
	if active_idx >= 0:
		var logs := _flow_service.process_start_of_turn(active_idx)
		for msg in logs:
			_on_log_updated(msg)

	_update_hp_displays()
	_update_log_display()

	var status := _flow_service.evaluate_battle_status()
	if status != BattleState.Status.ACTIVE:
		_on_battle_ended(status)
		return

	_handle_current_turn()


func _execute_ai_turn() -> void:
	var participant := _flow_service.get_active_participant()
	if participant == null or participant.character_data == null:
		call_deferred("_advance_turn")
		return

	var move := _select_best_move(participant)
	var target_idx := _find_weakest_target_index()

	if move != null and target_idx >= 0:
		var result := _flow_service.execute_player_action(move, target_idx)
		status_label.text = result.get("log_message", "Enemy acted.")
		_update_hp_displays()
		_update_log_display()

	call_deferred("_advance_turn")


func _find_weakest_target_index() -> int:
	var total := _flow_service.get_participant_count()
	var weakest: int = -1
	var lowest_hp_ratio: float = 999.0

	for i in total:
		if _flow_service.is_participant_defeated(i):
			continue
		var p := _flow_service.get_participant(i)
		if p == null or p.team != BattleParticipant.Team.PLAYER:
			continue
		var hp_ratio := float(p.current_hp) / float(p.max_hp)
		if hp_ratio < lowest_hp_ratio:
			lowest_hp_ratio = hp_ratio
			weakest = i

	return weakest


func _select_best_move(participant: BattleParticipant) -> MoveData:
	var best_move: MoveData = null
	var best_score: float = -1.0

	for move_id: String in participant.character_data.moves:
		var move_data: MoveData = DataRegistry.get_move(move_id)
		if move_data == null or move_data.power <= 0:
			continue

		var type_chart := TypeChart.new()
		var total := _flow_service.get_participant_count()
		var best_effectiveness: float = 0.0

		for i in total:
			if _flow_service.is_participant_defeated(i):
				continue
			var p := _flow_service.get_participant(i)
			if p == null or p.team != BattleParticipant.Team.PLAYER:
				continue
			var eff := type_chart.resolve_type_effectiveness(
					move_data.type,
					p.character_data.type if p.character_data != null else -1,
					p.character_data.secondary_type if p.character_data != null else -1)
			if eff > best_effectiveness:
				best_effectiveness = eff

		var score := float(move_data.power) * best_effectiveness * (float(move_data.accuracy) / 100.0)
		if score > best_score:
			best_score = score
			best_move = move_data

	return best_move


func _on_turn_started(participant: BattleParticipant) -> void:
	status_label.text = "%s is acting..." % participant.character_data.name
	_update_hp_displays()


func _on_action_executed(result: Dictionary, source: BattleParticipant, target: BattleParticipant) -> void:
	_update_hp_displays()
	_update_log_display()
	if not result.get("log_message", "").is_empty():
		status_label.text = result["log_message"]

	if result.get("damage_dealt", 0) > 0:
		_tween_damage(source, target, result["damage_dealt"])
	if result.get("recoil_damage", 0) > 0:
		_tween_damage(source, source, result["recoil_damage"], Color.RED)


func _on_participant_defeated(participant: BattleParticipant) -> void:
	status_label.text = "%s is defeated!" % participant.character_data.name
	_update_hp_displays()
	_update_log_display()


func _on_battle_ended(status: int) -> void:
	var won: bool = (status == BattleState.Status.VICTORY)
	var data: Dictionary = SaveManager.current_data.duplicate()
	data["last_battle_won"] = won
	data["last_battle_time"] = Time.get_datetime_string_from_system()
	SaveManager.save_game(data)

	await get_tree().create_timer(0.5).timeout
	GameManager.transition_to_state(GameManager.GameState.RESULT)


func _on_log_updated(message: String) -> void:
	_update_log_display()


func _update_hp_displays() -> void:
	if _flow_service == null:
		return

	_update_team_hp(player_hp_container, _flow_service.get_player_participants())
	_update_team_hp(enemy_hp_container, _flow_service.get_enemy_participants())


static func _update_team_hp(container: HBoxContainer, participants: Array[BattleParticipant]) -> void:
	for child: Node in container.get_children():
		child.queue_free()

	for p: BattleParticipant in participants:
		var label := Label.new()
		if p.character_data == null:
			label.text = "Unknown"
		elif p.is_defeated:
			label.text = "%s: DEFEATED" % p.character_data.name
			label.modulate = Color.GRAY
		else:
			label.text = "%s: %d/%d" % [p.character_data.name, p.current_hp, p.max_hp]
			var hp_ratio: float = float(p.current_hp) / float(p.max_hp)
			if hp_ratio < 0.25:
				label.modulate = Color.RED
			elif hp_ratio < 0.5:
				label.modulate = Color.YELLOW
			else:
				label.modulate = Color.WHITE
		container.add_child(label)


func _update_log_display() -> void:
	if _flow_service == null:
		return
	var recent: PackedStringArray = _flow_service.get_recent_log(10)
	battle_log_label.text = "\n".join(recent)


static func _tween_damage(
		_source: BattleParticipant,
		_target: BattleParticipant,
		_amount: int,
		_color: Color = Color.WHITE) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_selecting_target:
			_on_cancel_target_selection()
