extends Control

@onready var battle_log_label: RichTextLabel = $BattleLog
@onready var action_container: VBoxContainer = $ActionContainer
@onready var move_container: VBoxContainer = $MoveContainer
@onready var status_label: Label = $StatusLabel
@onready var player_hp_container: HBoxContainer = $PlayerHPContainer
@onready var enemy_hp_container: Container = $EnemyHPContainer

var _flow_service: BattleFlowService = null
var _is_selecting_switch: bool = false
var _player_panels: Array[BattleUnitPanel] = []
var _enemy_panels: Array[BattleUnitPanel] = []
## Opponent corps character IDs in corps order (used for hidden slot display).
var _enemy_corps_ids: Array[String] = []
## Per corps index: whether the character has ever appeared on the field.
var _revealed_enemy_slots: Array[bool] = []


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

	# Initialize opponent visibility state from the corps.
	_enemy_corps_ids = roster.opponent_corps.duplicate()
	_revealed_enemy_slots.clear()
	for i in _enemy_corps_ids.size():
		_revealed_enemy_slots.append(false)

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
		# The enemy AI decision and execution live in the Rust battle engine.
		var result := _flow_service.perform_ai_turn()
		status_label.text = result.get("log_message", "Enemy acted.")
		_update_hp_displays()
		_update_log_display()
		call_deferred("_advance_turn")


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
		var type_color: Color = TypeColors.get_type_color(move_data.type)
		var type_name: String = TypeColors.get_type_name(move_data.type)
		var cat_name: String = TypeColors.get_category_name(move_data.damage_category)
		btn.text = "[%s] %s (P:%d A:%d%% %s)" % [type_name, move_data.name, move_data.power, move_data.accuracy, cat_name]
		btn.add_theme_color_override("font_color", type_color)
		btn.add_theme_color_override("font_hover_color", type_color.lightened(0.3))
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
		var wrapper := VBoxContainer.new()
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND

		var panel: BattleUnitPanel = preload("res://scenes/battle_unit_panel.tscn").instantiate()
		panel.update_from_participant(p)
		panel.size_flags_horizontal = Control.SIZE_EXPAND
		wrapper.add_child(panel)

		var btn := Button.new()
		btn.text = "Switch In"
		btn.size_flags_horizontal = Control.SIZE_EXPAND
		btn.connect("pressed", Callable(self, "_on_switch_target_selected").bind(p.slot_index))
		wrapper.add_child(btn)

		action_container.add_child(wrapper)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.connect("pressed", Callable(self, "_on_cancel_switch_selection"))
	action_container.add_child(cancel_btn)

	action_container.show()


func _on_move_selected(move_data: MoveData) -> void:
	_is_selecting_switch = false
	# No target selection: the move always hits the opponent's front character.
	var result := _flow_service.execute_player_action(move_data)
	status_label.text = result.get("log_message", "Action executed.")
	_update_hp_displays()
	_update_log_display()
	_advance_turn()


func _on_switch_selected() -> void:
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

		var end_status := _flow_service.evaluate_battle_status()
		if end_status != BattleState.Status.ACTIVE:
			_on_battle_ended(end_status)
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


func _on_battle_ended(status: int) -> void:
	var won: bool = (status == BattleState.Status.VICTORY)
	var data: Dictionary = SaveManager.current_data.duplicate()
	data["last_battle_won"] = won
	data["last_battle_time"] = Time.get_datetime_string_from_system()
	SaveManager.save_game(data)

	await get_tree().create_timer(0.5).timeout
	GameManager.transition_to_state(GameManager.GameState.RESULT)


func _on_log_updated(_message: String) -> void:
	_update_log_display()


func _update_hp_displays() -> void:
	if _flow_service == null:
		return

	_update_team_hp(player_hp_container, BattleParticipant.Team.PLAYER)
	_update_team_hp(enemy_hp_container, BattleParticipant.Team.ENEMY)


## Updates the team's HP display using BattleUnitPanel instances.
## Creates panels on first call; reuses and reorders them on subsequent calls.
## The player team renders all fielded participants; the opponent team renders
## one slot per corps member, hiding unrevealed characters.
func _update_team_hp(container: Container, team: int) -> void:
	if team == BattleParticipant.Team.PLAYER:
		_update_player_team_hp(container, _player_panels)
	else:
		_update_enemy_team_hp(container, _enemy_panels)


## Updates the player's team display: front first, then bench, full identity.
func _update_player_team_hp(container: Container, panels: Array[BattleUnitPanel]) -> void:
	# Collect all participants in order: front first, then bench.
	var all_participants: Array[BattleParticipant] = []
	var front := _flow_service.get_front_participant(BattleParticipant.Team.PLAYER)
	if front != null:
		all_participants.append(front)
	for p: BattleParticipant in _flow_service.get_bench_participants(BattleParticipant.Team.PLAYER):
		all_participants.append(p)

	_resize_panels(panels, all_participants.size())

	# Rebuild the container with panels in the correct order.
	for child: Node in container.get_children():
		container.remove_child(child)

	for i in range(all_participants.size()):
		var p: BattleParticipant = all_participants[i]
		var panel: BattleUnitPanel = panels[i]
		panel.update_from_participant(p)
		panel.set_front_highlight(p.is_front)
		container.add_child(panel)


## Updates the opponent's team display: one slot per corps member in corps
## order. Slots whose character has never appeared on the field are grayed out
## (identity only, no battle state); the rest are fully displayed.
func _update_enemy_team_hp(container: Container, panels: Array[BattleUnitPanel]) -> void:
	# Mark the current front's corps slot as revealed: every path that changes
	# the front funnels through this update. The Rust bridge reports global
	# participant indices in slot_index, so resolve the corps position by id.
	var front := _flow_service.get_front_participant(BattleParticipant.Team.ENEMY)
	if front != null:
		var front_corps_idx: int = _enemy_corps_ids.find(front.character_data.id)
		if front_corps_idx >= 0 and front_corps_idx < _revealed_enemy_slots.size():
			_revealed_enemy_slots[front_corps_idx] = true

	# Map corps index -> participant for revealed slots.
	var by_corps: Dictionary = {}
	var all_participants: Array[BattleParticipant] = []
	if front != null:
		all_participants.append(front)
	for p: BattleParticipant in _flow_service.get_bench_participants(BattleParticipant.Team.ENEMY):
		all_participants.append(p)
	for p: BattleParticipant in all_participants:
		var corps_idx: int = _enemy_corps_ids.find(p.character_data.id)
		if corps_idx >= 0:
			by_corps[corps_idx] = p

	_resize_panels(panels, _enemy_corps_ids.size())

	# Rebuild the container with one panel per corps member.
	for child: Node in container.get_children():
		container.remove_child(child)

	for i in range(_enemy_corps_ids.size()):
		var panel: BattleUnitPanel = panels[i]
		var p: BattleParticipant = by_corps.get(i)
		var char_data: CharacterData = DataRegistry.get_character(_enemy_corps_ids[i])
		if _revealed_enemy_slots[i] and p != null:
			panel.update_from_participant(p)
			panel.set_front_highlight(p.is_front)
		elif _revealed_enemy_slots[i]:
			# Revealed earlier but no longer among the living participants:
			# the character was defeated (the bridge only reports living
			# bench participants). Render a distinct defeated state so it
			# never looks like an unselected slot.
			panel.show_defeated_placeholder(char_data)
			panel.set_front_highlight(false)
		else:
			panel.show_hidden_placeholder(char_data)
			panel.set_front_highlight(false)
		container.add_child(panel)


## Grows or shrinks a panel array to the target size, freeing any extras.
func _resize_panels(panels: Array[BattleUnitPanel], count: int) -> void:
	while panels.size() < count:
		var panel: BattleUnitPanel = preload("res://scenes/battle_unit_panel.tscn").instantiate()
		panels.append(panel)
	while panels.size() > count:
		var old: BattleUnitPanel = panels.pop_back()
		if old.get_parent() != null:
			old.get_parent().remove_child(old)
		old.queue_free()


func _update_log_display() -> void:
	if _flow_service == null:
		return
	var recent: PackedStringArray = _flow_service.get_recent_log(10)
	battle_log_label.text = "\n".join(recent)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_selecting_switch:
			_on_cancel_switch_selection()
