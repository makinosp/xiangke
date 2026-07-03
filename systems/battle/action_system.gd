## ActionSystem class.
## Core battle action execution: damage calculation, effect application, and move processing.
class_name ActionSystem
extends RefCounted

## STAB (Same-Type Attack Bonus) multiplier.
const STAB_MULTIPLIER: float = 1.2
## Minimum random variance multiplier.
const MIN_VARIANCE: float = 0.85
## Maximum random variance multiplier.
const MAX_VARIANCE: float = 1.0
## Minimum guaranteed damage per hit.
const MIN_DAMAGE: int = 1

## Result of a single move execution.
class ActionResult:
	extends RefCounted

	## Total damage dealt (0 if healing or no damage).
	var damage_dealt: int = 0
	## Total HP restored (0 if damaging move).
	var healing_done: int = 0
	## Whether the move hit (false if accuracy check failed).
	var hit: bool = true
	## Whether the move was a critical hit.
	var critical_hit: bool = false
	## Type effectiveness multiplier applied.
	var type_effectiveness: float = 1.0
	## Whether the move was super effective (>1.0).
	var is_super_effective: bool = false
	## Whether the move was not very effective (<1.0).
	var is_not_very_effective: bool = false
	## Whether the move was immune (0.0).
	var is_immune: bool = false
	## Status effect applied (if any), or TypeEnums.EffectType.NONE.
	var status_applied: int = TypeEnums.EffectType.NONE
	## Status effect was resisted (already has it or invalid).
	var status_resisted: bool = false
	## Recoil damage dealt to the attacker.
	var recoil_damage: int = 0
	## Log message describing the action result.
	var log_message: String = ""
	## Raw damage before type/STAB/variance modifiers.
	var raw_damage: int = 0


## Calculates damage for a single move action.
##
## Parameters:
##   attacker: The attacking BattleParticipant.
##   defender: The defending BattleParticipant.
##   move: The MoveData being used.
##
## Returns:
##   An ActionResult with all computed values.
static func calculate_damage(
		attacker: BattleParticipant,
		defender: BattleParticipant,
		move: MoveData) -> ActionResult:
	assert(attacker != null, "ActionSystem: attacker must not be null")
	assert(defender != null, "ActionSystem: defender must not be null")
	assert(move != null, "ActionSystem: move must not be null")
	assert(not attacker.is_defeated, "ActionSystem: attacker is defeated")
	assert(not defender.is_defeated, "ActionSystem: defender is defeated")

	var result := ActionResult.new()

	# --- Accuracy check ---
	if not _check_accuracy(move.accuracy):
		result.hit = false
		result.log_message = "%s used %s but it missed!" % [
				attacker.character_data.name, move.name]
		return result

	# --- Damage calculation (only for damaging moves) ---
	if move.power > 0:
		# Determine effective offensive and defensive stats
		var effective_atk: float
		var effective_def: float
		if move.damage_category == TypeEnums.DamageCategory.PHYSICAL:
			effective_atk = attacker.get_effective_attack()
			effective_def = defender.get_effective_defense()
		else:
			effective_atk = attacker.get_effective_intelligence()
			effective_def = defender.get_effective_spirit()

		# Clamp defense to prevent division by zero
		effective_def = maxf(effective_def, 1.0)

		# Base damage formula: (atk * power * 0.4) / (def * 0.5)
		# Equivalent to: (atk * power * 0.8) / def
		result.raw_damage = maxi(1, int(effective_atk * move.power * 0.8 / effective_def))

		# --- Type effectiveness ---
		var type_chart := TypeChart.new()
		result.type_effectiveness = type_chart.resolve_type_effectiveness(
				move.type,
				defender.character_data.type,
				defender.character_data.secondary_type)
		result.is_super_effective = result.type_effectiveness > 1.0
		result.is_not_very_effective = result.type_effectiveness < 1.0 and result.type_effectiveness > 0.0
		result.is_immune = result.type_effectiveness == 0.0

		# --- STAB (Same-Type Attack Bonus) ---
		var stab_multiplier: float = 1.0
		if _has_stab(attacker, move):
			stab_multiplier = STAB_MULTIPLIER

		# --- Random variance ---
		var variance: float = _calculate_variance()

		# --- Final damage ---
		var final_damage: int = maxi(
				MIN_DAMAGE,
				int(result.raw_damage * result.type_effectiveness * stab_multiplier * variance))

		# Immune moves deal 0 damage
		if result.is_immune:
			final_damage = 0

		# --- Critical hit ---
		if randi() % 100 < 6: # 6% critical hit chance
			result.critical_hit = true
			final_damage = int(final_damage * 1.5) # 1.5x damage

		result.damage_dealt = defender.take_damage(final_damage)

		# --- Recoil ---
		if move.recoil > 0 and result.damage_dealt > 0:
			var recoil_amount: int = maxi(1, int(result.damage_dealt * move.recoil / 100))
			result.recoil_damage = attacker.take_damage(recoil_amount)

		# Build log message
		result.log_message = _build_damage_log(attacker, defender, move, result)

	# --- Healing (for healing moves) ---
	if move.healing > 0:
		var heal_amount: int = maxi(1, int(attacker.character_data.hp * move.healing / 100))
		result.healing_done = attacker.heal(heal_amount)
		result.log_message = "%s used %s and restored %d HP!" % [
				attacker.character_data.name, move.name, result.healing_done]

	# --- Status effect application ---
	if move.effect != TypeEnums.EffectType.NONE and move.effect_chance > 0:
		var resisted: bool = _has_status_effect(defender, move.effect)
		if not resisted and _check_effect_chance(move.effect_chance):
			# Look up StatusEffectData and apply
			var effect := StatusEffectData.new()
			effect.effect_type = move.effect
			effect.name = _get_effect_name(move.effect)
			defender.apply_status(effect)
			result.status_applied = move.effect
		else:
			result.status_resisted = resisted

	return result


## Checks accuracy against a percentage value.
static func _check_accuracy(accuracy: int) -> bool:
	assert(accuracy >= 1 and accuracy <= 100,
			"ActionSystem: accuracy must be 1-100, got %d" % accuracy)
	return randf() * 100.0 < accuracy


## Checks if a random effect triggers.
static func _check_effect_chance(chance: int) -> bool:
	assert(chance >= 0 and chance <= 100,
			"ActionSystem: effect chance must be 0-100, got %d" % chance)
	return randf() * 100.0 < chance


## Checks if the attacker's move type matches their primary type (STAB).
static func _has_stab(attacker: BattleParticipant, move: MoveData) -> bool:
	return attacker.character_data.type == move.type


## Checks if a participant already has a given status effect type.
static func _has_status_effect(participant: BattleParticipant, effect_type: int) -> bool:
	for effect: StatusEffectData in participant.active_status_effects:
		if effect.effect_type == effect_type:
			return true
	return false


## Calculates random variance multiplier.
static func _calculate_variance() -> float:
	return randf_range(MIN_VARIANCE, MAX_VARIANCE)


## Returns the display name for an effect type.
static func _get_effect_name(effect_type: int) -> String:
	match effect_type:
		TypeEnums.EffectType.BURN:
			return "Burn"
		TypeEnums.EffectType.POISON:
			return "Poison"
		TypeEnums.EffectType.CONFUSION:
			return "Confusion"
		TypeEnums.EffectType.CHAIN:
			return "Chain"
		TypeEnums.EffectType.CHARM:
			return "Charm"
		_:
			return "Unknown"


## Builds a damage action log message.
static func _build_damage_log(
		attacker: BattleParticipant,
		defender: BattleParticipant,
		move: MoveData,
		result: ActionResult) -> String:
	var parts: PackedStringArray = []
	parts.append("%s used %s!" % [attacker.character_data.name, move.name])

	if result.is_immune:
		parts.append("It doesn't affect %s..." % defender.character_data.name)
	elif result.is_super_effective:
		parts.append("It's super effective!")
	elif result.is_not_very_effective:
		parts.append("It's not very effective...")

	if result.critical_hit:
		parts.append("A critical hit!")

	if result.recoil_damage > 0:
		parts.append("%s took %d recoil damage!" % [
				attacker.character_data.name, result.recoil_damage])

	return " ".join(parts)
