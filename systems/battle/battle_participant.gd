class_name BattleParticipant
extends RefCounted

enum Team {
	PLAYER,
	ENEMY
}

var character_data: CharacterData
var current_hp: int
var max_hp: int
var team: int
var slot_index: int
var is_defeated: bool
var is_front: bool
var stat_stages: Array[int]
var active_status_effects: Array[int]

## Creates a BattleParticipant from a dictionary (deserializes from Rust).
static func from_dict(data: Dictionary) -> BattleParticipant:
	var participant := BattleParticipant.new()
	participant.character_data = DataRegistry.get_character(data["id"])
	participant.current_hp = data.get("current_hp", 0)
	participant.max_hp = data.get("max_hp", 1)
	participant.team = data.get("team", Team.ENEMY)
	participant.slot_index = data.get("slot_index", 0)
	participant.is_defeated = data.get("is_defeated", false)
	participant.is_front = data.get("is_front", false)
	var raw_stages: Array = data.get("stat_stages", [])
	participant.stat_stages = []
	for stage in raw_stages:
		participant.stat_stages.append(stage)
	var raw_effects: Array = data.get("active_status_effects", [])
	participant.active_status_effects = []
	for effect in raw_effects:
		participant.active_status_effects.append(effect)
	return participant
