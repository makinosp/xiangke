extends Control

@onready var battle_log_label: RichTextLabel = $BattleLog
@onready var action_container: VBoxContainer = $ActionContainer
@onready var move_container: VBoxContainer = $MoveContainer
@onready var status_label: Label = $StatusLabel
@onready var player_hp_container: HBoxContainer = $PlayerHPContainer
@onready var enemy_hp_container: HBoxContainer = $EnemyHPContainer

var _flow_service: BattleFlowService = null
var _selected_move: MoveData = null
var _is_selecting_switch: bool = false


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

	var enemy_ids: Array[String] = _select_enemy_battle_team(roster.opponent_corps)
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

	# If the active participant was defeated by status effects, skip ahead.
	var active := _flow_service.get_active_participant()
	if active == null or active.is_defeated:
		call_deferred("_advance_turn")
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

	_is_selecting_switch = false
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

	# Switch option: swap the front character with a living benched character.
	var switch_btn := Button.new()
	switch_btn.text = "Switch (Bench)"
	switch_btn.connect("pressed", Callable(self, "_on_switch_selected"))
	move_container.add_child(switch_btn)


## Displays the living benched characters for the player to choose a switch.
func _show_switch_selection() -> void:
	move_container.hide()
	_is_selecting_switch = true
	status_label.text = "Choose a character to switch in:"

	for child: Node in action_container.get_children():
		child.queue_free()

	var bench := _flow_service.get_bench_participants(BattleParticipant.Team.PLAYER)
	if bench.is_empty():
		status_label.text = "No benched characters available!"
		_is_selecting_switch = false
		action_container.hide()
		_show_move_selection()
		return

	for p: BattleParticipant in bench:
		var btn := Button.new()
		var name := "Unknown" if p.character_data == null else p.character_data.name
		btn.text = "%s (HP: %d/%d)" % [name, p.current_hp, p.max_hp]
		btn.connect("pressed", Callable(self, "_on_switch_target_selected").bind(p.slot_index))
		action_container.add_child(btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.connect("pressed", Callable(self, "_on_cancel_switch_selection"))
	action_container.add_child(cancel_btn)

	action_container.show()


func _on_move_selected(move_data: MoveData) -> void:
	_selected_move = move_data
	_is_selecting_switch = false
	# No target selection: the move always hits the opponent's front character.
	var result := _flow_service.execute_player_action(move_data)
	status_label.text = result.get("log_message", "Action executed.")
	_update_hp_displays()
	_update_log_display()
	_advance_turn()


func _on_switch_selected() -> void:
	_selected_move = null
	_show_switch_selection()


func _on_switch_target_selected(bench_index: int) -> void:
	_is_selecting_switch = false
	action_container.hide()

	if _flow_service.execute_switch(BattleParticipant.Team.PLAYER, bench_index):
		status_label.text = "Switched characters!"
	else:
		status_label.text = "Switch failed!"

	_update_hp_displays()
	_update_log_display()
	_advance_turn()


func _on_cancel_switch_selection() -> void:
	_is_selecting_switch = false
	action_container.hide()
	_show_move_selection()


func _advance_turn() -> void:
	# Ensure both teams have a living front before advancing. This covers
	# defeats caused by status effects (e.g. poison) outside direct attacks.
	_flow_service.replace_front_if_defeated(BattleParticipant.Team.PLAYER)
	_flow_service.replace_front_if_defeated(BattleParticipant.Team.ENEMY)
	_update_hp_displays()
	_update_log_display()

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

	# Decide whether to switch: low HP or a type disadvantage.
	var enemy_front := _flow_service.get_front_participant(BattleParticipant.Team.PLAYER)
	if enemy_front != null and _should_ai_switch(participant, enemy_front):
		var bench := _flow_service.get_bench_participants(BattleParticipant.Team.ENEMY)
		if not bench.is_empty():
			var switched := _flow_service.execute_switch(BattleParticipant.Team.ENEMY, bench[0].slot_index)
			if switched:
				status_label.text = "Enemy switched characters!"
				_update_hp_displays()
				_update_log_display()
				call_deferred("_advance_turn")
				return

	var move := _select_best_move(participant)
	var player_front := _flow_service.get_front_participant(BattleParticipant.Team.PLAYER)

	if move != null and player_front != null:
		var result := _flow_service.execute_player_action(move)
		status_label.text = result.get("log_message", "Enemy acted.")
		_update_hp_displays()
		_update_log_display()

		# If the player's front was defeated, bring in a replacement.
		if _flow_service.get_front_participant(BattleParticipant.Team.PLAYER) == null:
			if _flow_service.replace_front_if_defeated(BattleParticipant.Team.PLAYER):
				_update_hp_displays()
				_update_log_display()

	call_deferred("_advance_turn")


## Returns true if the AI front should switch: front HP is low or the front
## holds a type disadvantage against the opponent front.
func _should_ai_switch(ai_front: BattleParticipant, opponent_front: BattleParticipant) -> bool:
	if ai_front.character_data == null or opponent_front.character_data == null:
		return false
	var hp_ratio := float(ai_front.current_hp) / float(ai_front.max_hp)
	if hp_ratio < 0.3:
		return true

	var type_chart := TypeChart.new()
	var best_eff := 0.0
	for move_id: String in ai_front.character_data.moves:
		var move_data: MoveData = DataRegistry.get_move(move_id)
		if move_data == null or move_data.power <= 0:
			continue
		var eff := type_chart.resolve_type_effectiveness(
				move_data.type,
				opponent_front.character_data.type,
				opponent_front.character_data.secondary_type)
		best_eff = max(best_eff, eff)
	return best_eff > 0.0 and best_eff <= 0.5


## Selects the 3 enemy characters to field in battle from the 6-character
## opponent corps. Picks the strongest 3 by combined stats; the strongest is
## the first (initial front).
func _select_enemy_battle_team(opponent_ids: Array[String]) -> Array[String]:
	var ranked: Array[Dictionary] = []
	for char_id: String in opponent_ids:
		var char_data: CharacterData = DataRegistry.get_character(char_id)
		if char_data == null:
			continue
		var total := char_data.hp + char_data.attack + char_data.defense \
				+ char_data.speed + char_data.intelligence + char_data.spirit
		ranked.append({"id": char_id, "total": total})

	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["total"] > b["total"])

	var result: Array[String] = []
	for i in range(min(3, ranked.size())):
		result.append(ranked[i]["id"])
	return result


func _select_best_move(participant: BattleParticipant) -> MoveData:
	var best_move: MoveData = null
	var best_score: float = -1.0

	# Only the opponent's front character is a valid target.
	var opponent_front := _flow_service.get_front_participant(BattleParticipant.Team.PLAYER)
	if opponent_front == null or opponent_front.character_data == null:
		return null

	var type_chart := TypeChart.new()

	for move_id: String in participant.character_data.moves:
		var move_data: MoveData = DataRegistry.get_move(move_id)
		if move_data == null or move_data.power <= 0:
			continue

		var eff := type_chart.resolve_type_effectiveness(
				move_data.type,
				opponent_front.character_data.type,
				opponent_front.character_data.secondary_type)
		var score := float(move_data.power) * eff * (float(move_data.accuracy) / 100.0)
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

	var dmg: int = result.get("damage_dealt", 0)
	if dmg > 0:
		_tween_damage_feedback(target, dmg, Color.RED)
	var heal: int = result.get("healing_done", 0)
	if heal > 0:
		_tween_damage_feedback(target, heal, Color.GREEN_YELLOW)
	var recoil: int = result.get("recoil_damage", 0)
	if recoil > 0:
		_tween_damage_feedback(source, recoil, Color.ORANGE_RED)


## Provides visual tween animation feedback for damage/healing.
## Temporarily flashes the HP label with the given color.
func _tween_damage_feedback(participant: BattleParticipant, amount: int, flash_color: Color) -> void:
	# Find the HP label for this participant
	var hp_labels: Array[Label] = []
	hp_labels.append_array(_find_hp_labels(player_hp_container, participant))
	hp_labels.append_array(_find_hp_labels(enemy_hp_container, participant))

	for label: Label in hp_labels:
		var original_color := label.modulate
		label.modulate = flash_color
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate", original_color, 0.4)
		tween.play()


## Searches an HP container for a label matching the given participant.
static func _find_hp_labels(container: HBoxContainer, participant: BattleParticipant) -> Array[Label]:
	var result: Array[Label] = []
	if participant.character_data == null:
		return result
	var target_name: String = participant.character_data.name
	for child in container.get_children():
		var label := child as Label
		if label != null and label.text.begins_with(target_name):
			result.append(label)
	return result


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

	_update_team_hp(player_hp_container, BattleParticipant.Team.PLAYER)
	_update_team_hp(enemy_hp_container, BattleParticipant.Team.ENEMY)


## Renders the team's HP: the front character highlighted, benched characters
## dimmed below.
func _update_team_hp(container: HBoxContainer, team: int) -> void:
	for child: Node in container.get_children():
		child.queue_free()

	var front := _flow_service.get_front_participant(team)
	if front != null:
		var front_label := Label.new()
		if front.character_data == null:
			front_label.text = "Unknown"
		elif front.is_defeated:
			front_label.text = "%s: DEFEATED" % front.character_data.name
			front_label.modulate = Color.GRAY
		else:
			front_label.text = "%s: %d/%d" % [front.character_data.name, front.current_hp, front.max_hp]
			var hp_ratio: float = float(front.current_hp) / float(front.max_hp)
			if hp_ratio < 0.25:
				front_label.modulate = Color.RED
			elif hp_ratio < 0.5:
				front_label.modulate = Color.YELLOW
			else:
				front_label.modulate = Color.WHITE
		container.add_child(front_label)

	for p: BattleParticipant in _flow_service.get_bench_participants(team):
		var label := Label.new()
		if p.character_data == null:
			label.text = "Unknown (bench)"
		elif p.is_defeated:
			label.text = "%s: DEFEATED" % p.character_data.name
			label.modulate = Color.GRAY
		else:
			label.text = "%s: %d/%d" % [p.character_data.name, p.current_hp, p.max_hp]
			label.modulate = Color(0.6, 0.6, 0.6)
		container.add_child(label)


func _update_log_display() -> void:
	if _flow_service == null:
		return
	var recent: PackedStringArray = _flow_service.get_recent_log(10)
	battle_log_label.text = "\n".join(recent)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_selecting_switch:
			_on_cancel_switch_selection()
