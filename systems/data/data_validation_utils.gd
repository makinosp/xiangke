## Static validation utility functions shared across all data validators.
## Provides common checks for ID format, range, uniqueness, and enum validity.
extends Node

class_name DataValidationUtils


## Validates that an ID string is in lowercase snake_case format.
## Must be 1-50 characters, containing only [a-z0-9_].
static func is_valid_id_format(id: String) -> bool:
	if id.is_empty() or id.length() > 50:
		return false
	var regex = RegEx.new()
	regex.compile("^[a-z][a-z0-9_]*$")
	return regex.search(id) != null


## Validates that an integer value is within the specified range (inclusive).
static func is_in_range(value: int, min_val: int, max_val: int) -> bool:
	return value >= min_val and value <= max_val


## Validates that a value is a valid Type enum value (0-6).
static func is_valid_type(value: int) -> bool:
	return value >= 0 and value <= 6


## Validates that a value is a valid EffectType enum value (0-5).
static func is_valid_effect_type(value: int) -> bool:
	return value >= 0 and value <= 5


## Validates that a value is a valid Stat enum value (0-4).
static func is_valid_stat(value: int) -> bool:
	return value >= 0 and value <= 4


## Validates that a string is non-empty and within the specified length range.
static func is_valid_string(value: String, min_len: int, max_len: int) -> bool:
	return value.length() >= min_len and value.length() <= max_len
