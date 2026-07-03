## BattleState class.
## Central state object representing the current status of a battle.
class_name BattleState
extends RefCounted

## Battle outcome status.
enum Status {
	ACTIVE,  ## Battle is ongoing.
	VICTORY, ## Player side has won.
	DEFEAT,  ## Player side has lost.
	DRAW,    ## Turn limit reached or mutual defeat.
	ESCAPED  ## Player successfully fled.
}

## Maximum turns before forced draw.
const MAX_TURNS: int = 50

## Unique identifier for the battle.
var battle_id: String
## Current turn number (1-indexed).
var turn_count: int = 0
## Current round number.
var round_count: int = 0
## List of all BattleParticipants in the battle.
var participants: Array[BattleParticipant] = []
## The BattleParticipant whose turn it currently is.
var active_participant: BattleParticipant = null
## Current battle status (ACTIVE, VICTORY, DEFEAT, DRAW, ESCAPED).
var battle_status: int = Status.ACTIVE
## Turn queue: ordered list of participant indices for the current round.
var turn_queue: Array[int] = []
## Position in the turn queue.
var turn_queue_index: int = 0
## Combat log entries for this battle.
var battle_log: PackedStringArray = PackedStringArray()


## Creates a new BattleState with the given participants.
##
## Parameters:
##   player_participants: Array of player-controlled BattleParticipants.
##   enemy_participants: Array of enemy-controlled BattleParticipants.
##   id: Optional battle ID. Auto-generated if empty.
static func create(
		player_participants: Array[BattleParticipant],
		enemy_participants: Array[BattleParticipant],
		id: String = "") -> BattleState:
	assert(player_participants.size() > 0, "BattleState: must have at least 1 player participant")
	assert(enemy_participants.size() > 0, "BattleState: must have at least 1 enemy participant")

	var state := BattleState.new()
	state.battle_id = id if not id.is_empty() else "battle_%s" % Time.get_datetime_string_from_system()
	state.participants = []
	state.participants.append_array(player_participants)
	state.participants.append_array(enemy_participants)
	state.turn_count = 0
	state.round_count = 0
	state.battle_status = Status.ACTIVE
	state.battle_log = PackedStringArray()
	return state


## Returns all player-controlled participants.
func get_player_participants() -> Array[BattleParticipant]:
	var result: Array[BattleParticipant] = []
	for p in participants:
		if p.team == BattleParticipant.Team.PLAYER:
			result.append(p)
	return result


## Returns all enemy-controlled participants.
func get_enemy_participants() -> Array[BattleParticipant]:
	var result: Array[BattleParticipant] = []
	for p in participants:
		if p.team == BattleParticipant.Team.ENEMY:
			result.append(p)
	return result


## Returns all non-defeated participants.
func get_active_participants() -> Array[BattleParticipant]:
	var result: Array[BattleParticipant] = []
	for p in participants:
		if not p.is_defeated:
			result.append(p)
	return result


## Returns true if all enemies are defeated.
func are_all_enemies_defeated() -> bool:
	for p in participants:
		if p.team == BattleParticipant.Team.ENEMY and not p.is_defeated:
			return false
	return true


## Returns true if all players are defeated.
func are_all_players_defeated() -> bool:
	for p in participants:
		if p.team == BattleParticipant.Team.PLAYER and not p.is_defeated:
			return false
	return true


## Checks win/loss/draw conditions and updates battle_status if needed.
##
## Returns:
##   true if the battle has ended, false if still active.
func evaluate_battle_status() -> bool:
	if battle_status != Status.ACTIVE:
		return true

	if are_all_enemies_defeated():
		battle_status = Status.VICTORY
		add_log("All enemies defeated! Victory!")
		return true

	if are_all_players_defeated():
		battle_status = Status.DEFEAT
		add_log("All allies defeated! Defeat...")
		return true

	if turn_count >= MAX_TURNS:
		battle_status = Status.DRAW
		add_log("Turn limit reached! The battle ends in a draw.")
		return true

	return false


## Adds an entry to the battle log.
func add_log(message: String) -> void:
	battle_log.append("[T%d/R%d] %s" % [turn_count, round_count, message])


## Returns the last N log entries.
func get_recent_log(count: int = 10) -> PackedStringArray:
	var start := maxi(0, battle_log.size() - count)
	var result := PackedStringArray()
	for i in range(start, battle_log.size()):
		result.append(battle_log[i])
	return result


## Resets the state for a new battle.
func reset() -> void:
	turn_count = 0
	round_count = 0
	battle_status = Status.ACTIVE
	active_participant = null
	turn_queue.clear()
	turn_queue_index = 0
	battle_log.clear()
	for p in participants:
		p.current_hp = p.max_hp
		p.is_defeated = false
		p.active_status_effects.clear()
		p.reset_stat_stages()
