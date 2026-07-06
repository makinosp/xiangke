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
var stat_stages: Array[int]
var active_status_effects: Array[int]

static func from_dict(data: Dictionary) -> BattleParticipant:
	var p := BattleParticipant.new()
	p.character_data = DataRegistry.get_character(data["id"])
	p.current_hp = data.get("current_hp", 0)
	p.max_hp = data.get("max_hp", 1)
	p.team = data.get("team", Team.ENEMY)
	p.slot_index = data.get("slot_index", 0)
	p.is_defeated = data.get("is_defeated", false)
	p.stat_stages = data.get("stat_stages", [])
	p.active_status_effects = data.get("active_status_effects", [])
	return p
