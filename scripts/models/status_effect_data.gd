## StatusEffectData resource class.
## Defines a status effect that can be applied to characters in battle.
@tool
class_name StatusEffectData
extends Resource

## Status effect type identifier.
@export var effect_type: int = TypeEnums.EffectType.NONE

## Display name of the status effect.
@export var name: String = ""

## Localization key for the display name (e.g., "effect.burn.name").
@export var name_key: String = ""

## Description of the status effect's behavior.
@export var description: String = ""

## Localization key for the description (e.g., "effect.burn.desc").
@export var desc_key: String = ""

## Per-turn damage as fraction of max HP (0.0-1.0). 0 if no damage.
@export var damage_per_turn: float = 0.0

## Whether damage increases each turn (escalating poison).
@export var escalating: bool = false

## Maximum damage cap as fraction of max HP (0.0-1.0).
@export var max_damage_cap: float = 0.25

## Stat modification applied by this status (if any).
@export var stat_mod_stat: int = -1

## Stat multiplier applied (e.g., 0.5 for Burn's attack reduction).
@export var stat_mod_multiplier: float = 1.0

## Returns true if this status effect deals damage over time.
func has_damage_over_time() -> bool:
	return damage_per_turn > 0.0

## Returns true if this status effect modifies a stat.
func has_stat_modification() -> bool:
	return stat_mod_stat >= 0 and stat_mod_multiplier != 1.0
