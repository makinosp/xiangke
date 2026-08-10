## Data validator implementing batch validation with summary reporting.
## Validates all character, move, and type chart data against business rules.
##
## @deprecated Use Rust validator (core/src/validator.rs) instead.
## Both validators exist during migration; Rust version is authoritative.
extends Node

class_name DataValidator

## Validation error with rule code, message, and context.
class ValidationError:
	var code: String
	var message: String
	var context: String

	## Creates a validation error with rule code, message, and optional context.
	func _init(p_code: String, p_message: String, p_context: String = ""):
		code = p_code
		message = p_message
		context = p_context

	## Formats the error as "[code] message" or "[code] message: context".
	func _to_string() -> String:
		if context.is_empty():
			return "[%s] %s" % [code, message]
		return "[%s] %s: %s" % [code, context, message]

## Validation warning with rule code, message, and context.
class ValidationWarning:
	var code: String
	var message: String
	var context: String

	## Creates a validation warning with rule code, message, and optional context.
	func _init(p_code: String, p_message: String, p_context: String = ""):
		code = p_code
		message = p_message
		context = p_context

	## Formats the warning as "[code] message" or "[code] message: context".
	func _to_string() -> String:
		if context.is_empty():
			return "[%s] %s" % [code, message]
		return "[%s] %s: %s" % [code, context, message]

## Complete validation result with errors, warnings, and summary.
class ValidationResult:
	var errors: Array[ValidationError] = []
	var warnings: Array[ValidationWarning] = []
	var total_files_scanned: int = 0
	var valid_files: int = 0
	var invalid_files: int = 0

	## Adds an error to the result.
	func add_error(code: String, message: String, context: String = "") -> void:
		errors.append(ValidationError.new(code, message, context))

	## Adds a warning to the result.
	func add_warning(code: String, message: String, context: String = "") -> void:
		warnings.append(ValidationWarning.new(code, message, context))

	## Returns true if validation passed with no errors.
	func is_valid() -> bool:
		return errors.is_empty()

	## Generates a human-readable summary of the validation results.
	func get_summary() -> String:
		var result = "=== Data Validation Summary ===\n"
		result += "Files scanned: %d\n" % total_files_scanned
		result += "Valid: %d | Invalid: %d\n" % [valid_files, invalid_files]
		if not errors.is_empty():
			result += "\n--- Errors (%d) ---\n" % errors.size()
			for err in errors:
				result += err._to_string() + "\n"
		if not warnings.is_empty():
			result += "\n--- Warnings (%d) ---\n" % warnings.size()
			for warn in warnings:
				result += warn._to_string() + "\n"
		result += "\nValidation complete. %d errors, %d warnings." % [
				errors.size(), warnings.size()]
		return result


## Validates all data (characters, moves, type chart) and returns a summary.
## Returns a ValidationResult with all errors, warnings, and counts.
func validate_all(
		characters: Dictionary,
		moves: Dictionary) -> ValidationResult:
	var result = ValidationResult.new()

	# Validate type chart
	_validate_type_chart(result)

	# Validate all moves
	for move_id in moves:
		var move: MoveData = moves[move_id]
		result.total_files_scanned += 1
		var move_errors = _validate_move(move, moves)
		if move_errors.is_empty():
			result.valid_files += 1
		else:
			result.invalid_files += 1
			for err in move_errors:
				result.add_error(err.code, err.message, err.context)

	# Validate all characters
	for char_id in characters:
		var character: CharacterData = characters[char_id]
		result.total_files_scanned += 1
		var char_errors = _validate_character(character, characters, moves)
		if char_errors.is_empty():
			result.valid_files += 1
		else:
			result.invalid_files += 1
			for err in char_errors:
				result.add_error(err.code, err.message, err.context)

	return result


# --- Private validation methods ---

## Implements character validation.
func _validate_character(
		character: CharacterData,
		_characters: Dictionary,
		_moves: Dictionary) -> Array[ValidationError]:
	var errors: Array[ValidationError] = []

	# Character Identity
	if not DataValidationUtils.is_valid_id_format(character.id):
		errors.append(ValidationError.new(
				"CR-1", "Invalid ID format (must be lowercase snake_case)",
				character.id))
	if not DataValidationUtils.is_valid_string(character.name, 1, 20):
		errors.append(ValidationError.new(
				"CR-1", "Name must be 1-20 characters", character.id))

	# Character Stats
	var stat_names = ["hp", "attack", "defense", "speed",
			"intelligence", "spirit"]
	var stat_values = [character.hp, character.attack, character.defense,
			character.speed, character.intelligence, character.spirit]
	for i in range(stat_names.size()):
		if not DataValidationUtils.is_in_range(stat_values[i], 1, 999):
			errors.append(ValidationError.new(
					"CR-2", "%s must be in range [1, 999], got %d" % [
							stat_names[i], stat_values[i]],
					character.id))
		if stat_values[i] > 500:
			errors.append(ValidationError.new(
					"CR-2", "%s exceeds maximum of 500, got %d" % [
							stat_names[i], stat_values[i]],
					character.id))
	if character.get_stat_sum() > 3000:
		errors.append(ValidationError.new(
				"CR-2", "Stat sum %d exceeds maximum 3000" % character.get_stat_sum(),
				character.id))

	# Character Type Assignment
	if not DataValidationUtils.is_valid_type(character.type):
		errors.append(ValidationError.new(
				"CR-3", "Invalid primary type: %d" % character.type,
				character.id))
	if character.has_secondary_type():
		if not DataValidationUtils.is_valid_type(character.secondary_type):
			errors.append(ValidationError.new(
					"CR-3", "Invalid secondary type: %d" % character.secondary_type,
					character.id))
		if character.secondary_type == character.type:
			errors.append(ValidationError.new(
					"CR-3", "Secondary type same as primary (%d)" % character.type,
					character.id))

	# Character Move Assignment
	if character.moves.size() != 4:
		errors.append(ValidationError.new(
				"CR-4", "Must have exactly 4 moves, got %d" % character.moves.size(),
				character.id))
	var has_damaging_move = false
	for move_id in character.moves:
		if not _moves.has(move_id):
			errors.append(ValidationError.new(
					"CR-4", "Move '%s' does not exist in move registry" % move_id,
					character.id))
		else:
			var move: MoveData = _moves[move_id]
			if move.power > 0:
				has_damaging_move = true
	if not has_damaging_move:
		errors.append(ValidationError.new(
				"CR-4", "Must have at least one move with power > 0",
				character.id))

	return errors


## Implements move validation.
func _validate_move(move: MoveData, _moves: Dictionary) -> Array[ValidationError]:
	var errors: Array[ValidationError] = []

	# Move Identity
	if not DataValidationUtils.is_valid_id_format(move.id):
		errors.append(ValidationError.new(
				"MR-1", "Invalid ID format (must be lowercase snake_case)",
				move.id))
	if not DataValidationUtils.is_valid_string(move.name, 1, 20):
		errors.append(ValidationError.new(
				"MR-1", "Name must be 1-20 characters", move.id))

	# Move Power and Accuracy
	if not DataValidationUtils.is_in_range(move.power, 0, 255):
		errors.append(ValidationError.new(
				"MR-2", "Power must be in range [0, 255], got %d" % move.power,
				move.id))
	if not DataValidationUtils.is_in_range(move.accuracy, 1, 100):
		errors.append(ValidationError.new(
				"MR-2", "Accuracy must be in range [1, 100], got %d" % move.accuracy,
				move.id))

	# Move Effect
	if not DataValidationUtils.is_valid_effect_type(move.effect):
		errors.append(ValidationError.new(
				"MR-3", "Invalid effect type: %d" % move.effect, move.id))
	if not DataValidationUtils.is_in_range(move.effect_chance, 0, 100):
		errors.append(ValidationError.new(
				"MR-3", "Effect chance must be in range [0, 100], got %d" % move.effect_chance,
				move.id))
	if move.effect == TypeEnums.EffectType.NONE and move.effect_chance != 0:
		errors.append(ValidationError.new(
				"MR-3", "Effect chance must be 0 when effect is None",
				move.id))
	if move.effect != TypeEnums.EffectType.NONE and move.effect_chance == 0:
		errors.append(ValidationError.new(
				"MR-3", "Effect chance must be > 0 when effect is not None",
				move.id))

	# Move Stat Modification
	if move.has_stat_mod():
		if not DataValidationUtils.is_valid_stat(move.stat_mod_stat):
			errors.append(ValidationError.new(
					"MR-4", "Invalid stat for modification: %d" % move.stat_mod_stat,
					move.id))
		if not DataValidationUtils.is_in_range(move.stat_mod_stage, -3, 3):
			errors.append(ValidationError.new(
					"MR-4", "Stat mod stage must be in range [-3, 3], got %d" % move.stat_mod_stage,
					move.id))
		if not DataValidationUtils.is_in_range(move.stat_mod_target, 0, 1):
			errors.append(ValidationError.new(
					"MR-4", "Stat mod target must be 0 (SELF) or 1 (TARGET), got %d" % move.stat_mod_target,
					move.id))

	# Move Multi-Hit
	if not DataValidationUtils.is_in_range(move.hit_count, 1, 5):
		errors.append(ValidationError.new(
				"MR-5", "Hit count must be in range [1, 5], got %d" % move.hit_count,
				move.id))

	# Move Recoil
	if not DataValidationUtils.is_in_range(move.recoil, 0, 100):
		errors.append(ValidationError.new(
				"MR-6", "Recoil must be in range [0, 100], got %d" % move.recoil,
				move.id))
	if move.recoil > 0 and move.power <= 0:
		errors.append(ValidationError.new(
				"MR-6", "Recoil requires power > 0", move.id))

	# Move Healing
	if not DataValidationUtils.is_in_range(move.healing, 0, 100):
		errors.append(ValidationError.new(
				"MR-7", "Healing must be in range [0, 100], got %d" % move.healing,
				move.id))

	return errors


## Implements type chart validation.
func _validate_type_chart(result: ValidationResult) -> void:
	var chart = TypeChart.TYPE_CHART

	# Type Validity — chart must be 7x7
	if chart.size() != 7:
		result.add_error("TR-1",
				"Type chart must have 7 rows, got %d" % chart.size())
		return
	for i in range(7):
		if chart[i].size() != 7:
			result.add_error("TR-1",
					"Type chart row %d must have 7 columns, got %d" % [
							i, chart[i].size()])

	# Type Effectiveness Constraints
	# Diagonal must not be 2.0 or 0.0
	for i in range(7):
		if chart[i][i] == 2.0:
			result.add_error("TR-2",
					"Type %d must not be super effective against itself" % i)
		if chart[i][i] == 0.0:
			result.add_error("TR-2",
					"Type %d must not be immune to itself" % i)

	# Yang (5) and Yin (6) must be super effective against each other
	if chart[6][5] != 2.0: # Yang attacker vs Yin defender
		result.add_error("TR-2",
				"Yang must be super effective against Yin (2.0)")
	if chart[5][6] != 2.0: # Yin attacker vs Yang defender
		result.add_error("TR-2",
				"Yin must be super effective against Yang (2.0)")

	# Yang and Yin must have neutral effectiveness against 五行 types
	for i in range(5):
		if chart[i][5] != 1.0: # Yang attacker vs 五行 defender
			result.add_error("TR-2",
					"Yang must have neutral effectiveness against type %d" % i)
		if chart[i][6] != 1.0: # Yin attacker vs 五行 defender
			result.add_error("TR-2",
					"Yin must have neutral effectiveness against type %d" % i)
		if chart[5][i] != 1.0: # 五行 attacker vs Yang defender
			result.add_error("TR-2",
					"Type %d must have neutral effectiveness against Yang" % i)
		if chart[6][i] != 1.0: # 五行 attacker vs Yin defender
			result.add_error("TR-2",
					"Type %d must have neutral effectiveness against Yin" % i)

	# Five Elements Cycle Compliance
	# Each 五行 type must be super effective against exactly one other (2.0)
	for defender in range(5):
		var super_effective_count = 0
		for attacker in range(5):
			if chart[defender][attacker] == 2.0:
				super_effective_count += 1
		if super_effective_count != 1:
			result.add_error("TR-3",
					"Type %d must be super effective against exactly 1 type, got %d" % [
							defender, super_effective_count])

	# Each 五行 type must generate exactly one other (1.25 when defending)
	for defender in range(5):
		var generating_count = 0
		for attacker in range(5):
			if chart[defender][attacker] == 1.25:
				generating_count += 1
		if generating_count != 1:
			result.add_error("TR-3",
					"Type %d must generate exactly 1 type (1.25x), got %d" % [
							defender, generating_count])

	# Each 五行 type must be not very effective against exactly one (0.5)
	for defender in range(5):
		var weak_count = 0
		for attacker in range(5):
			if chart[defender][attacker] == 0.5:
				weak_count += 1
		if weak_count != 1:
			result.add_error("TR-3",
					"Type %d must be weak against exactly 1 type (0.5x), got %d" % [
							defender, weak_count])
