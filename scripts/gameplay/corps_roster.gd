## CorpsRoster class.
## Manages the player's two-phase character selection:
## Phase 1 — Select 6 characters to form the corps.
## Phase 2 — Select 3 characters from the corps to deploy in battle.
class_name CorpsRoster
extends RefCounted

## 6 character IDs selected in Phase 1 (corps formation).
var corps_characters: Array[String] = []
## 3 character IDs selected in Phase 2 (battle party).
var battle_characters: Array[String] = []
## 6 character IDs of the opponent's corps (populated by AI between phases).
var opponent_corps: Array[String] = []


## Sets the corps selection (Phase 1).
##
## Parameters:
##   ids: Array of exactly 6 unique character IDs.
##
## Returns:
##   true if the selection is valid, false otherwise.
func set_corps_selection(ids: Array[String]) -> bool:
	if ids.size() != 6:
		push_warning("CorpsRoster: Corps must have exactly 6 characters, got %d" % ids.size())
		return false
	if _has_duplicates(ids):
		push_warning("CorpsRoster: Corps contains duplicate character IDs")
		return false
	corps_characters = ids.duplicate()
	return true


## Sets the battle party selection (Phase 2).
##
## Parameters:
##   ids: Array of exactly 3 character IDs, all from the corps.
##
## Returns:
##   true if the selection is valid, false otherwise.
func set_battle_selection(ids: Array[String]) -> bool:
	if ids.size() != 3:
		push_warning("CorpsRoster: Battle party must have exactly 3 characters, got %d" % ids.size())
		return false
	if _has_duplicates(ids):
		push_warning("CorpsRoster: Battle party contains duplicate character IDs")
		return false
	for id in ids:
		if not corps_characters.has(id):
			push_warning("CorpsRoster: Battle character %s is not in the corps" % id)
			return false
	battle_characters = ids.duplicate()
	return true


## Returns true if the corps selection is complete (Phase 1 done).
func is_corps_selected() -> bool:
	return corps_characters.size() == 6


## Returns true if the battle selection is complete (Phase 2 done).
func is_battle_ready() -> bool:
	return battle_characters.size() == 3


## Resets the entire roster.
func reset() -> void:
	corps_characters.clear()
	battle_characters.clear()
	opponent_corps.clear()


## Serializes corps_characters and opponent_corps to a dictionary for saving.
func to_dict() -> Dictionary:
	return {
		"corps_characters": corps_characters.duplicate(),
		"opponent_corps": opponent_corps.duplicate()
	}


## Restores corps data from a dictionary (e.g., loaded save data).
##
## Parameters:
##   data: Dictionary with optional "corps_characters" and "opponent_corps" keys.
func from_dict(data: Dictionary) -> void:
	if data.has("corps_characters") and data["corps_characters"] is Array:
		var ids: Array[String] = []
		for id in data["corps_characters"]:
			ids.append(str(id))
		if ids.size() == 6:
			corps_characters = ids
	if data.has("opponent_corps") and data["opponent_corps"] is Array:
		var ids: Array[String] = []
		for id in data["opponent_corps"]:
			ids.append(str(id))
		opponent_corps = ids


## Restores corps_characters from save data without affecting other fields.
##
## Parameters:
##   data: Dictionary with optional "corps_characters" key.
func restore_from_save(data: Dictionary) -> void:
	if data.has("corps_characters") and data["corps_characters"] is Array:
		var ids: Array[String] = []
		for id in data["corps_characters"]:
			ids.append(str(id))
		if ids.size() == 6:
			corps_characters = ids


## Generates a random opponent corps of 6 characters, excluding player corps.
## Called when battle preparation starts (title screen Start).
func generate_opponent_corps() -> void:
	var all_chars := DataRegistry.get_all_characters()
	var pool: Array[String] = []
	for char_id in all_chars.keys():
		if not corps_characters.has(char_id):
			pool.append(char_id)

	pool.shuffle()
	var opponent_ids: Array[String] = []
	for i in range(min(6, pool.size())):
		opponent_ids.append(pool[i])
	opponent_corps = opponent_ids


## Checks for duplicate IDs in an array.
func _has_duplicates(ids: Array[String]) -> bool:
	var seen: Dictionary = {}
	for id in ids:
		if seen.has(id):
			return true
		seen[id] = true
	return false
