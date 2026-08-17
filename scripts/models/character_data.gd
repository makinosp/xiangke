## CharacterData resource class.
## Defines a playable character or enemy in the battle system.
@tool
class_name CharacterData
extends Resource

## Unique identifier (lowercase snake_case, e.g., "zhuge_liang").
@export var id: String = ""

## Display name (e.g., "諸葛亮").
@export var name: String = ""

## Localization key for the display name (e.g., "char.zhuge_liang.name").
@export var name_key: String = ""

## Primary type (one of 7 types).
@export var type: int = TypeEnums.Type.WOOD

## Optional second type. TypeEnums.Type.MAX indicates no secondary type.
@export var secondary_type: int = -1

## Base HP stat (1-999).
@export var hp: int = 1

## Base attack stat (1-999).
@export var attack: int = 1

## Base defense stat (1-999).
@export var defense: int = 1

## Base speed stat (1-999).
@export var speed: int = 1

## Base intelligence stat (1-999) — attack power for arts and strategies.
@export var intelligence: int = 1

## Base spirit stat (1-999) — damage resistance against arts and strategies.
@export var spirit: int = 1

## List of 4 move IDs this character can use.
@export var moves: PackedStringArray = PackedStringArray()

## Flavor text for the character.
@export var description: String = ""

## Localization key for the flavor description (e.g., "char.zhuge_liang.desc").
@export var desc_key: String = ""

## Path to character portrait image (2:3 aspect ratio recommended).
## Defaults to placeholder if empty or file not found.
@export var portrait_path: String = ""

## Returns true if the character has a secondary type assigned.
func has_secondary_type() -> bool:
	return secondary_type >= 0

## Returns the sum of all six base stats.
func get_stat_sum() -> int:
	return hp + attack + defense + speed + intelligence + spirit
