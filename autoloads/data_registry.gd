## DataRegistry autoload singleton.
## Central in-memory store for all game data (characters, moves).
## Provides lookup methods for other systems to access game data.
extends Node

## Dictionary of all loaded characters keyed by ID.
var _characters: Dictionary = {}

## Dictionary of all loaded moves keyed by ID.
var _moves: Dictionary = {}

## Whether data has been loaded into the registry.
var _is_loaded: bool = false


## Called when the node enters the tree. Automatically loads all data.
func _ready() -> void:
	load_all()


## Loads all game data from resource files into memory.
##
## Uses DataLoader to discover and load all .tres files from the
## characters and moves directories.
func load_all() -> void:
	var data_loader = DataLoader.new()
	var data: Dictionary = data_loader.load_all()
	_characters = data["characters"]
	_moves = data["moves"]
	_is_loaded = true

	# Run validation and log results
	var validator = DataValidator.new()
	var result = validator.validate_all(_characters, _moves)
	if not result.is_valid():
		push_warning("DataRegistry: Validation issues found:\n%s" % result.get_summary())
	else:
		print("DataRegistry: All data loaded and validated successfully.")
		print("  Characters: %d | Moves: %d" % [_characters.size(), _moves.size()])


## Reloads all data from disk. Useful for hot-reloading during development.
func reload() -> void:
	_is_loaded = false
	_characters.clear()
	_moves.clear()
	load_all()


## Returns true if data has been loaded into the registry.
func is_loaded() -> bool:
	return _is_loaded


## Retrieves a character by ID.
##
## Parameters:
##   id: The character ID to look up.
##
## Returns:
##   CharacterData if found, null otherwise.
func get_character(id: String) -> CharacterData:
	if _characters.has(id):
		return _characters[id]
	push_warning("DataRegistry: Character not found: %s" % id)
	return null


## Retrieves a move by ID.
##
## Parameters:
##   id: The move ID to look up.
##
## Returns:
##   MoveData if found, null otherwise.
func get_move(id: String) -> MoveData:
	if _moves.has(id):
		return _moves[id]
	push_warning("DataRegistry: Move not found: %s" % id)
	return null


## Returns all loaded characters.
##
## Returns:
##   Dictionary of CharacterData keyed by ID.
func get_all_characters() -> Dictionary:
	return _characters.duplicate()


## Returns all loaded moves.
##
## Returns:
##   Dictionary of MoveData keyed by ID.
func get_all_moves() -> Dictionary:
	return _moves.duplicate()


## Returns the number of loaded characters.
func get_character_count() -> int:
	return _characters.size()


## Returns the number of loaded moves.
func get_move_count() -> int:
	return _moves.size()


## Checks if a character with the given ID exists.
func has_character(id: String) -> bool:
	return _characters.has(id)


## Checks if a move with the given ID exists.
func has_move(id: String) -> bool:
	return _moves.has(id)


## Resolves type effectiveness for a move against a character.
## Convenience method combining TypeChart with character data.
##
## Parameters:
##   move_id: The move ID to resolve.
##   defender_id: The defending character's ID.
##
## Returns:
##   The effectiveness multiplier, or -1.0 if move or character not found.
func get_type_effectiveness_against(move_id: String, defender_id: String) -> float:
	var move := get_move(move_id)
	if move == null:
		return -1.0
	var defender := get_character(defender_id)
	if defender == null:
		return -1.0
	var type_chart = TypeChart.new()
	return type_chart.resolve_type_effectiveness(
			move.type, defender.type, defender.secondary_type)
