## MoveData resource class.
## Defines a battle action a character can perform.
@tool
class_name MoveData
extends Resource

## Unique identifier (lowercase snake_case, e.g., "fire_strike").
@export var id: String = ""

## Display name (e.g., "火撃").
@export var name: String = ""

## Move's type (one of 7 types).
@export var type: int = TypeEnums.Type.WOOD

## Base power (0-255, 0 = non-damage).
@export var power: int = 0

## Hit chance percentage (1-100).
@export var accuracy: int = 100

## Special effect category.
@export var effect: int = TypeEnums.EffectType.NONE

## Percentage chance of effect triggering (0-100).
@export var effect_chance: int = 0

## Stat to modify (if any). TypeEnums.Stat value.
@export var stat_mod_stat: int = -1

## Stat stage change per move application (-3 to +3).
@export var stat_mod_stage: int = 0

## Number of hits (1 for single, 2-5 for multi-hit).
@export var hit_count: int = 1

## Fraction of damage dealt returned to user (0-100).
@export var recoil: int = 0

## HP restored to user as percentage of power (0-100).
@export var healing: int = 0

## Whether the move deals physical or arts damage.
@export var damage_category: int = TypeEnums.DamageCategory.PHYSICAL

## Flavor text for the move.
@export var description: String = ""

## Returns true if this move has a stat modification effect.
func has_stat_mod() -> bool:
	return stat_mod_stat >= 0 and stat_mod_stage != 0

## Returns true if this move deals damage.
func is_damaging() -> bool:
	return power > 0
