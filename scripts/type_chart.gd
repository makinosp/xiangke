## Type effectiveness chart implementing the 7x7 type matrix.
## Based on 五行 (Five Elements) cycles + 陰陽 (Yin-Yang) relationship.
@tool
class_name TypeChart
extends Node

## Type effectiveness matrix.
## Row = defender's type, Column = attacker's type.
## Values: 2.0 (overcoming / 相克 or reverse-generating / 子盗母气),
##         1.25 (generating / 相生), 1.0 (neutral),
##         0.5 (not very effective / 被相克), 0.0 (immune)
const TYPE_CHART: Array = [
	# WOOD defender
	[1.0, 2.0, 0.5, 2.0, 1.25, 1.0, 1.0], # WOOD attacker
	# FIRE defender
	[1.25, 1.0, 2.0, 0.5, 2.0, 1.0, 1.0], # FIRE attacker
	# EARTH defender
	[2.0, 1.25, 1.0, 2.0, 0.5, 1.0, 1.0], # EARTH attacker
	# METAL defender
	[0.5, 2.0, 1.25, 1.0, 2.0, 1.0, 1.0], # METAL attacker
	# WATER defender
	[2.0, 0.5, 2.0, 1.25, 1.0, 1.0, 1.0], # WATER attacker
	# YANG defender
	[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0], # YANG attacker
	# YIN defender
	[1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0], # YIN attacker
]

## Minimum multiplier for dual-type calculations.
const MIN_MULTIPLIER: float = 0.25

## Maximum multiplier for dual-type calculations.
const MAX_MULTIPLIER: float = 4.0

## Resolves the type effectiveness multiplier for a single type matchup.
##
## Parameters:
##   attacker_type: The type of the attacking move (TypeEnums.Type).
##   defender_type: The type of the defending character (TypeEnums.Type).
##
## Returns:
##   The effectiveness multiplier (0.0, 0.5, 1.0, 1.25, or 2.0).
func get_effectiveness(attacker_type: int, defender_type: int) -> float:
	if attacker_type < 0 or attacker_type > 6:
		push_error("TypeChart: invalid attacker_type %d" % attacker_type)
		return 1.0
	if defender_type < 0 or defender_type > 6:
		push_error("TypeChart: invalid defender_type %d" % defender_type)
		return 1.0
	return TYPE_CHART[defender_type][attacker_type]


## Resolves the final type effectiveness multiplier accounting for dual-types.
##
## Parameters:
##   attacker_type: The type of the attacking move (TypeEnums.Type).
##   defender_primary_type: The defender's primary type (TypeEnums.Type).
##   defender_secondary_type: The defender's secondary type, or -1 if none.
##
## Returns:
##   The final effectiveness multiplier, clamped to [0.25, 4.0].
func resolve_type_effectiveness(
		attacker_type: int,
		defender_primary_type: int,
		defender_secondary_type: int = -1) -> float:
	var primary_multiplier: float = get_effectiveness(
			attacker_type, defender_primary_type)

	if defender_secondary_type < 0:
		return primary_multiplier

	var secondary_multiplier: float = get_effectiveness(
			attacker_type, defender_secondary_type)
	var final_multiplier: float = primary_multiplier * secondary_multiplier

	return clamp(final_multiplier, MIN_MULTIPLIER, MAX_MULTIPLIER)
