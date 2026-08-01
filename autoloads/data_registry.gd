## DataRegistry autoload singleton.
## Central in-memory store for all game data (characters, moves).
## Provides lookup methods for other systems to access game data.
extends Node

## Dictionary of all loaded characters keyed by ID.
var _characters: Dictionary = {}

## Dictionary of all loaded moves keyed by ID.
var _moves: Dictionary = {}


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
	data_loader.free()
	_characters = data["characters"]
	_moves = data["moves"]

	# Run validation and log results
	var validator = DataValidator.new()
	var result = validator.validate_all(_characters, _moves)
	validator.free()
	if not result.is_valid():
		push_warning("DataRegistry: Validation issues found:\n%s" % result.get_summary())
	else:
		print("DataRegistry: All data loaded and validated successfully.")
		print("  Characters: %d | Moves: %d" % [_characters.size(), _moves.size()])


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


## Checks if a character with the given ID exists.
func has_character(id: String) -> bool:
	return _characters.has(id)
