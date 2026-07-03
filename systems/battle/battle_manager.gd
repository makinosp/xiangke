## BattleManager class.
## Manages the turn loop, initiative calculation, and turn queue generation.
class_name BattleManager
extends RefCounted

## Tie-breaking buffer for speed comparison (avoids float precision issues).
const SPEED_TIE_EPSILON: float = 0.001


## Calculates the turn queue for a round.
## Participants are sorted in descending order of effective speed.
## In case of ties, order is randomized among tied participants.
##
## Parameters:
##   state: The current BattleState containing participants.
##
## Returns:
##   Array of participant indices sorted by speed (descending).
static func calculate_turn_queue(state: BattleState) -> Array[int]:
	assert(state != null, "BattleManager: state must not be null")

	var active_participants: Array[BattleParticipant] = state.get_active_participants()
	if active_participants.is_empty():
		return []

	# Build list of (index, speed) pairs
	typealiasSpeedEntry = Dictionary # {index: int, speed: float}
	var entries: Array[SpeedEntry] = []

	for i in state.participants.size():
		var p: BattleParticipant = state.participants[i]
		if not p.is_defeated:
			entries.append({"index": i, "speed": p.get_effective_speed()})

	# Shuffle to randomize ties before sorting
	entries.shuffle()

	# Sort by speed descending (stable sort preserves shuffle for ties)
	entries.sort_cu(_compare_speed_descending)

	var queue: Array[int] = []
	for entry: SpeedEntry in entries:
		queue.append(entry["index"])

	return queue


## Advances the turn queue to the next active participant.
## Skips defeated participants. Call once per turn to progress the battle.
##
## Parameters:
##   state: The current BattleState to advance.
##
## Returns:
##   true if there is a next active participant, false if no valid participants remain.
static func advance_to_next_turn(state: BattleState) -> bool:
	assert(state != null, "BattleManager: state must not be null")

	# If queue is empty or exhausted, start a new round
	if state.turn_queue.is_empty() or state.turn_queue_index >= state.turn_queue.size():
		if not start_new_round(state):
			return false

	state.turn_queue_index += 1

	# If we've exhausted this round's queue, start a new round
	if state.turn_queue_index >= state.turn_queue.size():
		if not start_new_round(state):
			return false

	# Find next active participant in queue (skip defeated)
	while state.turn_queue_index < state.turn_queue.size():
		var idx: int = state.turn_queue[state.turn_queue_index]
		if idx >= 0 and idx < state.participants.size():
			var p: BattleParticipant = state.participants[idx]
			if not p.is_defeated:
				state.active_participant = p
				state.turn_count += 1
				return true
		state.turn_queue_index += 1

	# Remaining participants in queue are all defeated - try new round
	if not start_new_round(state):
		return false

	state.active_participant = state.participants[state.turn_queue[0]]
	state.turn_count += 1
	return true


## Starts a new round: recalculates turn queue and resets the index.
##
## Parameters:
##   state: The current BattleState.
##
## Returns:
##   true if a new round was started, false if no active participants exist.
static func start_new_round(state: BattleState) -> bool:
	assert(state != null, "BattleManager: state must not be null")

	state.round_count += 1
	state.turn_queue = calculate_turn_queue(state)
	state.turn_queue_index = 0

	if state.turn_queue.is_empty():
		return false

	return true


## Starts the battle by initializing the first round and setting the first participant.
##
## Parameters:
##   state: The current BattleState (must be freshly created).
##
## Returns:
##   true if the battle started successfully.
static func start_battle(state: BattleState) -> bool:
	assert(state != null, "BattleManager: state must not be null")
	assert(state.battle_status == BattleState.Status.ACTIVE,
			"BattleManager: cannot start a battle with status %d" % state.battle_status)

	if not start_new_round(state):
		state.battle_status = BattleState.Status.DEFEAT
		state.add_log("No active participants! Battle cannot start.")
		return false

	state.turn_queue_index = 0
	if state.turn_queue.is_empty():
		state.battle_status = BattleState.Status.DEFEAT
		return false

	state.active_participant = state.participants[state.turn_queue[0]]
	state.turn_count = 1
	state.add_log("Battle started! Round 1.")
	return true


## Gets the current active participant.
##
## Parameters:
##   state: The current BattleState.
##
## Returns:
##   The active BattleParticipant, or null if none.
static func get_active_participant(state: BattleState) -> BattleParticipant:
	assert(state != null, "BattleManager: state must not be null")
	return state.active_participant


## Comparison function for sorting speed entries (descending by speed).
static func _compare_speed_descending(a: Dictionary, b: Dictionary) -> bool:
	var speed_a: float = a["speed"] as float
	var speed_b: float = b["speed"] as float
	return speed_a > speed_b + SPEED_TIE_EPSILON
