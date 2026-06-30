## Data loader that discovers and loads .tres resource files.
## Implements graceful degradation with placeholder fallback (NFR pattern RP-1).
extends Node

class_name DataLoader

## Base directory for character resource files.
const CHARACTERS_DIR: String = "res://resources/characters/"

## Base directory for move resource files.
const MOVES_DIR: String = "res://resources/moves/"

## DLC directory for character resource files (optional).
const DLC_CHARACTERS_DIR: String = "res://dlc/characters/"

## DLC directory for move resource files (optional).
const DLC_MOVES_DIR: String = "res://dlc/moves/"

## File extension for resource files.
const RESOURCE_EXTENSION: String = ".tres"


## Creates a placeholder CharacterData for missing or corrupted files.
static func create_placeholder_character(id: String) -> CharacterData:
	var character = CharacterData.new()
	character.id = id
	character.name = "Unknown"
	character.type = TypeEnums.Type.WOOD
	character.secondary_type = -1
	character.hp = 1
	character.attack = 1
	character.defense = 1
	character.speed = 1
	character.intelligence = 1
	character.spirit = 1
	character.moves = PackedStringArray()
	character.description = "Data missing or corrupted"
	return character


## Creates a placeholder MoveData for missing or corrupted files.
static func create_placeholder_move(id: String) -> MoveData:
	var move = MoveData.new()
	move.id = id
	move.name = "Unknown"
	move.type = TypeEnums.Type.WOOD
	move.power = 0
	move.accuracy = 100
	move.effect = TypeEnums.EffectType.NONE
	move.effect_chance = 0
	move.hit_count = 1
	move.recoil = 0
	move.healing = 0
	move.damage_category = TypeEnums.DamageCategory.PHYSICAL
	move.description = "Data missing or corrupted"
	return move


## Discovers all character IDs by scanning the characters directory.
##
## Returns:
##   PackedStringArray of character IDs (filenames without extension).
func discover_characters() -> PackedStringArray:
	var ids := _discover_ids_in_dir(CHARACTERS_DIR)
	# Include DLC characters if directory exists
	if DirAccess.dir_exists_absolute(DLC_CHARACTERS_DIR):
		var dlc_ids := _discover_ids_in_dir(DLC_CHARACTERS_DIR)
		for dlc_id in dlc_ids:
			if not ids.has(dlc_id):
				ids.append(dlc_id)
	return ids


## Discovers all move IDs by scanning the moves directory.
##
## Returns:
##   PackedStringArray of move IDs (filenames without extension).
func discover_moves() -> PackedStringArray:
	var ids := _discover_ids_in_dir(MOVES_DIR)
	# Include DLC moves if directory exists
	if DirAccess.dir_exists_absolute(DLC_MOVES_DIR):
		var dlc_ids := _discover_ids_in_dir(DLC_MOVES_DIR)
		for dlc_id in dlc_ids:
			if not ids.has(dlc_id):
				ids.append(dlc_id)
	return ids


## Loads a single character by ID with graceful degradation.
##
## Parameters:
##   id: The character ID to load.
##
## Returns:
##   CharacterData if found and valid, placeholder CharacterData if missing or corrupted.
func load_character(id: String) -> CharacterData:
	var path := CHARACTERS_DIR + id + RESOURCE_EXTENSION
	if not ResourceLoader.exists(path):
		# Try DLC directory
		path = DLC_CHARACTERS_DIR + id + RESOURCE_EXTENSION
		if not ResourceLoader.exists(path):
			push_warning("DataLoader: Character not found: %s" % id)
			return create_placeholder_character(id)

	var resource = ResourceLoader.load(path)
	if resource == null or not resource is CharacterData:
		push_warning("DataLoader: Corrupted character file: %s" % id)
		return create_placeholder_character(id)

	return resource as CharacterData


## Loads a single move by ID with graceful degradation.
##
## Parameters:
##   id: The move ID to load.
##
## Returns:
##   MoveData if found and valid, placeholder MoveData if missing or corrupted.
func load_move(id: String) -> MoveData:
	var path := MOVES_DIR + id + RESOURCE_EXTENSION
	if not ResourceLoader.exists(path):
		# Try DLC directory
		path = DLC_MOVES_DIR + id + RESOURCE_EXTENSION
		if not ResourceLoader.exists(path):
			push_warning("DataLoader: Move not found: %s" % id)
			return create_placeholder_move(id)

	var resource = ResourceLoader.load(path)
	if resource == null or not resource is MoveData:
		push_warning("DataLoader: Corrupted move file: %s" % id)
		return create_placeholder_move(id)

	return resource as MoveData


## Loads all characters from the characters directory.
##
## Returns:
##   Dictionary of CharacterData keyed by character ID.
func load_all_characters() -> Dictionary:
	var characters := {}
	var ids := discover_characters()
	for id in ids:
		characters[id] = load_character(id)
	return characters


## Loads all moves from the moves directory.
##
## Returns:
##   Dictionary of MoveData keyed by move ID.
func load_all_moves() -> Dictionary:
	var moves := {}
	var ids := discover_moves()
	for id in ids:
		moves[id] = load_move(id)
	return moves


## Loads all data (characters and moves) into a single structure.
##
## Returns:
##   Dictionary with "characters" and "moves" keys containing respective dictionaries.
func load_all() -> Dictionary:
	return {
		"characters": load_all_characters(),
		"moves": load_all_moves(),
	}


# --- Private methods ---

## Discovers all resource IDs in a directory by listing .tres files.
func _discover_ids_in_dir(dir_path: String) -> PackedStringArray:
	var ids := PackedStringArray()
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return ids
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(RESOURCE_EXTENSION):
			var id = file_name.get_basename()
			ids.append(id)
		file_name = dir.get_next()
	dir.list_dir_end()
	return ids
