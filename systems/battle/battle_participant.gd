## BattleParticipant class.
## Represents a mutable battle entity wrapping CharacterData with runtime state.
class_name BattleParticipant
extends RefCounted

## Team affiliation.
enum Team {
	PLAYER, ## Human-controlled characters.
	ENEMY ## AI-controlled characters.
}

## Maximum stat stage modifier (+6).
const MAX_STAT_STAGE: int = 6
## Minimum stat stage modifier (-6).
const MIN_STAT_STAGE: int = -6
## Default stat stage (neutral).
const DEFAULT_STAT_STAGE: int = 0
## Number of modifiable stats (ATTACK, DEFENSE, SPEED, INTELLIGENCE, SPIRIT).
const STAT_COUNT: int = 5

## Reference to the immutable character data resource.
var character_data: CharacterData
## Current health points (0..max_hp).
var current_hp: int
## Maximum health points.
var max_hp: int
## Stat stage modifiers (indexed by TypeEnums.Stat). 0 = neutral.
var stat_stages: Array[int]
## Active status effects on this participant.
var active_status_effects: Array[StatusEffectData]
## Team affiliation (PLAYER or ENEMY).
var team: int
## Whether this participant is defeated (current_hp <= 0).
var is_defeated: bool
## Display index for UI targeting (0-based within team).
var slot_index: int


## Creates a new BattleParticipant from character data.
##
## Parameters:
##   data: The CharacterData resource to wrap.
##   participant_team: Team.PLAYER or Team.ENEMY.
##   index: Slot index for UI targeting.
static func create(data: CharacterData, participant_team: int, index: int) -> BattleParticipant:
	assert(data != null, "BattleParticipant: character_data must not be null")
	assert(participant_team == Team.PLAYER or participant_team == Team.ENEMY,
			"BattleParticipant: invalid team %d" % participant_team)
	assert(index >= 0, "BattleParticipant: slot_index must be >= 0")

	var participant := BattleParticipant.new()
	participant.character_data = data
	participant.max_hp = data.hp
	participant.current_hp = data.hp
	participant.team = participant_team
	participant.slot_index = index
	participant.is_defeated = false
	participant.active_status_effects = []
	participant.stat_stages = _create_default_stages()
	return participant


## Resets all stat stages to neutral (0).
func reset_stat_stages() -> void:
	stat_stages = _create_default_stages()


## Applies a stat stage change, clamped to [-6, +6].
##
## Parameters:
##   stat: The stat to modify (TypeEnums.Stat value).
##   change: The stage change amount (-6 to +6).
func apply_stat_stage(stat: int, change: int) -> void:
	assert(stat >= 0 and stat < STAT_COUNT,
			"BattleParticipant: invalid stat index %d" % stat)
	stat_stages[stat] = clampi(stat_stages[stat] + change, MIN_STAT_STAGE, MAX_STAT_STAGE)


## Gets the effective stat stage for a given stat.
##
## Parameters:
##   stat: The stat to query (TypeEnums.Stat value).
##
## Returns:
##   The current stage value (-6 to +6).
func get_stat_stage(stat: int) -> int:
	assert(stat >= 0 and stat < STAT_COUNT,
			"BattleParticipant: invalid stat index %d" % stat)
	return stat_stages[stat]


## Gets the stat stage multiplier for damage calculation.
##
## Returns:
##   A float multiplier based on the current stage:
##   Positive stages: (2 + stage) / 2
##   Negative stages: 2 / (2 - stage)
func get_stat_stage_multiplier(stat: int) -> float:
	assert(stat >= 0 and stat < STAT_COUNT,
			"BattleParticipant: invalid stat index %d" % stat)
	var stage := stat_stages[stat]
	if stage == 0:
		return 1.0
	elif stage > 0:
		return (2.0 + stage) / 2.0
	else:
		return 2.0 / (2.0 - stage)


## Applies damage to this participant.
##
## Parameters:
##   amount: The amount of damage to deal (must be >= 0).
##
## Returns:
##   The actual damage dealt (after capping to current_hp).
func take_damage(amount: int) -> int:
	assert(amount >= 0, "BattleParticipant: damage amount must be >= 0, got %d" % amount)
	var actual_damage := mini(amount, current_hp)
	current_hp -= actual_damage
	if current_hp <= 0:
		current_hp = 0
		is_defeated = true
	return actual_damage


## Heals this participant.
##
## Parameters:
##   amount: The amount of HP to restore (must be >= 0).
##
## Returns:
##   The actual HP restored (after capping to max_hp).
func heal(amount: int) -> int:
	assert(amount >= 0, "BattleParticipant: heal amount must be >= 0, got %d" % amount)
	var actual_heal := mini(amount, max_hp - current_hp)
	current_hp += actual_heal
	return actual_heal


## Applies a status effect to this participant.
##
## Parameters:
##   effect: The status effect to apply.
func apply_status(effect: StatusEffectData) -> void:
	assert(effect != null, "BattleParticipant: status effect must not be null")
	active_status_effects.append(effect)


## Returns the effective attack value (base attack * stage multiplier).
func get_effective_attack() -> float:
	return character_data.attack * get_stat_stage_multiplier(TypeEnums.Stat.ATTACK)


## Returns the effective defense value (base defense * stage multiplier).
func get_effective_defense() -> float:
	return character_data.defense * get_stat_stage_multiplier(TypeEnums.Stat.DEFENSE)


## Returns the effective intelligence value (base int * stage multiplier).
func get_effective_intelligence() -> float:
	return character_data.intelligence * get_stat_stage_multiplier(TypeEnums.Stat.INTELLIGENCE)


## Returns the effective spirit value (base spirit * stage multiplier).
func get_effective_spirit() -> float:
	return character_data.spirit * get_stat_stage_multiplier(TypeEnums.Stat.SPIRIT)


## Returns the effective speed value (base speed * stage multiplier).
func get_effective_speed() -> float:
	return character_data.speed * get_stat_stage_multiplier(TypeEnums.Stat.SPEED)


## Creates a default stat stages array (all zeros).
static func _create_default_stages() -> Array[int]:
	var stages: Array[int] = []
	stages.resize(STAT_COUNT)
	for i in range(STAT_COUNT):
		stages[i] = DEFAULT_STAT_STAGE
	return stages
