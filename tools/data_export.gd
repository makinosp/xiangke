## Dev tool: exports all .tres game data to a single JSON file.
##
## Runs headless as a scene (NOT -s script mode; the GDExtension hangs with -s):
##   godot --headless res://tools/data_export.tscn -- --export-path=/tmp/xiangke_data.json
##
## The output JSON matches the serde schema of the Rust core types
## (extensions/core/src/character.rs, moves.rs) so the Rust checker can
## deserialize and validate the real resource data. Enum values are mapped
## from the GDScript integer codes to the Rust variant names.
##
## Exit codes: 0 = success, 1 = export/data error, 2 = usage error.
extends Node

## Enum name arrays in the same order as TypeEnums and the Rust enums.
const TYPE_NAMES: Array[String] = ["Wood", "Fire", "Earth", "Metal", "Water", "Yang", "Yin"]
const EFFECT_NAMES: Array[String] = ["None", "Burn", "Poison", "Confusion", "Chain", "Charm"]
const STAT_NAMES: Array[String] = ["Attack", "Defense", "Speed", "Intelligence", "Spirit"]
const STAT_MOD_TARGET_NAMES: Array[String] = ["Self_", "Target"]
const CATEGORY_NAMES: Array[String] = ["Physical", "Arts"]

## Marker used by DataLoader placeholders for missing/corrupted files.
const PLACEHOLDER_NAME: String = "Unknown"
const PLACEHOLDER_DESC: String = "Data missing or corrupted"


func _ready() -> void:
	var export_path := _get_export_path()
	if export_path.is_empty():
		printerr("Usage: godot --headless res://tools/data_export.tscn -- --export-path=<abs path>")
		get_tree().quit(2)
		return

	var loader := DataLoader.new()
	var data: Dictionary = loader.load_all()
	loader.free()

	var errors: Array[String] = []
	var characters: Array = _export_characters(data.get("characters", {}), errors)
	var moves: Array = _export_moves(data.get("moves", {}), errors)
	if not errors.is_empty():
		for err in errors:
			printerr("DataExport: ", err)
		printerr("DataExport: export failed with ", errors.size(), " error(s)")
		get_tree().quit(1)
		return

	var payload := {
		"characters": characters,
		"moves": moves,
	}
	var json_text := JSON.stringify(payload, "\t")
	if json_text == "":
		printerr("DataExport: JSON serialization produced empty output")
		get_tree().quit(1)
		return

	var file := FileAccess.open(export_path, FileAccess.WRITE)
	if file == null:
		printerr("DataExport: failed to open export path for writing: ", export_path)
		get_tree().quit(1)
		return
	file.store_string(json_text)
	file.close()

	print("DataExport: wrote ", characters.size(), " characters and ",
			moves.size(), " moves to ", export_path)
	get_tree().quit(0)


## Extracts the --export-path=<abs> argument from the command line.
func _get_export_path() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--export-path="):
			return arg.trim_prefix("--export-path=")
	return ""


## Serializes all loaded characters (sorted by id) to core-schema dictionaries.
func _export_characters(characters: Dictionary, errors: Array[String]) -> Array:
	var result: Array = []
	var ids := characters.keys()
	ids.sort()
	for id in ids:
		var c: CharacterData = characters[id]
		if _is_placeholder_character(c):
			errors.append("placeholder data substituted for character '" + id + "'")
			continue
		result.append(_character_to_dict(c, errors))
	return result


## Serializes all loaded moves (sorted by id) to core-schema dictionaries.
func _export_moves(moves: Dictionary, errors: Array[String]) -> Array:
	var result: Array = []
	var ids := moves.keys()
	ids.sort()
	for id in ids:
		var m: MoveData = moves[id]
		if _is_placeholder_move(m):
			errors.append("placeholder data substituted for move '" + id + "'")
			continue
		result.append(_move_to_dict(m, errors))
	return result


## Maps a character resource to the core CharacterData JSON schema.
func _character_to_dict(c: CharacterData, errors: Array[String]) -> Dictionary:
	if c.name.contains("\uFFFD"):
		errors.append("character '" + c.id + "' name contains U+FFFD replacement character (encoding corruption)")
	return {
		"id": c.id,
		"name": c.name,
		"element": _enum_name(TYPE_NAMES, c.type, "character '" + c.id + "' type", errors),
		"secondary_element": _optional_enum_name(TYPE_NAMES, c.secondary_type,
				"character '" + c.id + "' secondary_type", errors),
		"base_stats": {
			"hp": c.hp,
			"attack": c.attack,
			"defense": c.defense,
			"speed": c.speed,
			"intelligence": c.intelligence,
			"spirit": c.spirit,
		},
		"moves": Array(c.moves),
		"description": c.description,
	}


## Maps a move resource to the core MoveData JSON schema.
func _move_to_dict(m: MoveData, errors: Array[String]) -> Dictionary:
	if m.name.contains("\uFFFD"):
		errors.append("move '" + m.id + "' name contains U+FFFD replacement character (encoding corruption)")
	return {
		"id": m.id,
		"name": m.name,
		"element": _enum_name(TYPE_NAMES, m.type, "move '" + m.id + "' type", errors),
		"power": m.power,
		"accuracy": m.accuracy,
		"effect": _enum_name(EFFECT_NAMES, m.effect, "move '" + m.id + "' effect", errors),
		"effect_chance": m.effect_chance,
		"stat_mod_stat": _optional_enum_name(STAT_NAMES, m.stat_mod_stat,
				"move '" + m.id + "' stat_mod_stat", errors),
		"stat_mod_stage": m.stat_mod_stage,
		"stat_mod_target": _enum_name(STAT_MOD_TARGET_NAMES, m.stat_mod_target,
				"move '" + m.id + "' stat_mod_target", errors),
		"hit_count": m.hit_count,
		"recoil": m.recoil,
		"healing": m.healing,
		"damage_category": _enum_name(CATEGORY_NAMES, m.damage_category,
				"move '" + m.id + "' damage_category", errors),
		"description": m.description,
	}


## Returns the enum name for a value, or "" and records an error if out of range.
func _enum_name(names: Array[String], value: int, context: String, errors: Array[String]) -> String:
	if value < 0 or value >= names.size():
		var message := "enum value " + str(value) + " out of range for " + context
		printerr("DataExport: ", message)
		errors.append(message)
		return ""
	return names[value]


## Returns the enum name or null when the value is -1 (unset).
func _optional_enum_name(names: Array[String], value: int, context: String, errors: Array[String]):
	if value < 0:
		return null
	return _enum_name(names, value, context, errors)


## Returns true when a character came from DataLoader's placeholder fallback.
func _is_placeholder_character(c: CharacterData) -> bool:
	return c.name == PLACEHOLDER_NAME and c.description == PLACEHOLDER_DESC


## Returns true when a move came from DataLoader's placeholder fallback.
func _is_placeholder_move(m: MoveData) -> bool:
	return m.name == PLACEHOLDER_NAME and m.description == PLACEHOLDER_DESC
