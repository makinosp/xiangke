## SaveManager autoload singleton.
## Manages local persistence using Godot's ConfigFile API with checksum validation.
## Stores settings (volume), progress (last character, battle result), and metadata.
extends Node

## Path to the save file in the user data directory.
const SAVE_PATH: String = "user://save.cfg"
## Current save file format version. Mismatch triggers a reset to defaults.
const SAVE_VERSION: int = 1

## Emitted when save data is loaded or reset.
signal save_loaded(save_data: Dictionary)
## Emitted when save data is written to disk.
signal save_written()

## Currently loaded save data dictionary.
var current_data: Dictionary = {}


func _ready() -> void:
	load_save()


## Loads save data from disk with checksum validation.
##
## Returns:
##   Dictionary with loaded save data, or defaults on error.
func load_save() -> Dictionary:
	var config := ConfigFile.new()
	var err: Error = config.load(SAVE_PATH)

	if err != OK:
		# First launch: file does not exist
		current_data = _create_default_save()
		return current_data

	# Validate checksum
	var stored_checksum: String = config.get_value("meta", "checksum", "")
	var calculated_checksum := _calculate_checksum(config)

	if not stored_checksum.is_empty() and stored_checksum != calculated_checksum:
		push_warning("SaveManager: Save file checksum mismatch — resetting to defaults")
		current_data = _create_default_save()
		current_data["_warning"] = "Save file was corrupted and has been reset to defaults"
		emit_signal("save_loaded", current_data)
		return current_data

	# Parse sections
	current_data = _parse_save_data(config)
	emit_signal("save_loaded", current_data)
	return current_data


## Saves game data to disk.
##
## Parameters:
##   data: Optional dictionary to save. Uses current_data if omitted.
func save_game(data: Dictionary = {}) -> void:
	if data.is_empty():
		data = current_data

	var config := ConfigFile.new()

	# Settings section
	config.set_value("settings", "master_volume", data.get("master_volume", 1.0))
	config.set_value("settings", "bgm_volume", data.get("bgm_volume", 1.0))
	config.set_value("settings", "sfx_volume", data.get("sfx_volume", 1.0))
	config.set_value("settings", "master_muted", data.get("master_muted", false))

	# Progress section
	config.set_value("progress", "selected_character", data.get("selected_character", ""))
	config.set_value("progress", "last_battle_won", data.get("last_battle_won", false))
	config.set_value("progress", "last_battle_time", data.get("last_battle_time", ""))
	# Store corps_characters as JSON string (ConfigFile does not natively support arrays)
	var corps_data: Array = data.get("corps_characters", [])
	config.set_value("progress", "corps_characters", JSON.stringify(corps_data))

	# Meta section
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("meta", "checksum", _calculate_checksum(config))

	var err: Error = config.save(SAVE_PATH)
	if err != OK:
		push_warning("SaveManager: Failed to save game (error %d)" % err)
		return

	current_data = data
	emit_signal("save_written")


## Resets all save data to defaults and writes to disk.
func reset_to_defaults() -> void:
	current_data = _create_default_save()
	save_game(current_data)


## Returns the default save data dictionary.
func _create_default_save() -> Dictionary:
	return {
		"master_volume": 1.0,
		"bgm_volume": 1.0,
		"sfx_volume": 1.0,
		"master_muted": false,
		"selected_character": "",
		"last_battle_won": false,
		"last_battle_time": "",
		"corps_characters": [],
		"_warning": ""
	}


## Calculates a checksum for integrity validation.
##
## Parameters:
##   config: ConfigFile to calculate checksum from.
func _calculate_checksum(config: ConfigFile) -> String:
	var data_str := ""
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			if key == "checksum":
				continue
			data_str += "%s.%s=%s" % [section, key, config.get_value(section, key)]
	return data_str.md5_text()


## Parses save data from a ConfigFile into a dictionary.
func _parse_save_data(config: ConfigFile) -> Dictionary:
	var data := _create_default_save()

	# Settings
	data["master_volume"] = config.get_value("settings", "master_volume", 1.0)
	data["bgm_volume"] = config.get_value("settings", "bgm_volume", 1.0)
	data["sfx_volume"] = config.get_value("settings", "sfx_volume", 1.0)
	data["master_muted"] = config.get_value("settings", "master_muted", false)

	# Progress
	data["selected_character"] = config.get_value("progress", "selected_character", "")
	data["last_battle_won"] = config.get_value("progress", "last_battle_won", false)
	data["last_battle_time"] = config.get_value("progress", "last_battle_time", "")
	# Load corps_characters from JSON string
	var corps_json: String = config.get_value("progress", "corps_characters", "[]")
	if not corps_json.is_empty():
		var parsed = JSON.parse_string(corps_json)
		if parsed is Array:
			data["corps_characters"] = parsed

	# Validate version
	var save_version: int = config.get_value("meta", "save_version", 0)
	if save_version != SAVE_VERSION:
		push_warning("SaveManager: Save version mismatch (got %d, expected %d) — resetting" % [save_version, SAVE_VERSION])
		return _create_default_save()

	return data
