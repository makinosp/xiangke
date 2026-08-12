## Tests for TypeChart data loading and effectiveness computation.
extends "res://tests/test_base.gd"

var _type_chart = null


func before_all() -> void:
	_type_chart = TypeChart.new()


func test_type_chart_exists() -> int:
	return assert_ne(_type_chart, null, "TypeChart should be loadable")


func test_type_chart_has_get_effectiveness_method() -> int:
	return assert_eq(_type_chart.has_method("get_effectiveness"), true,
		"TypeChart should have get_effectiveness method")


func test_same_type_effectiveness_is_neutral() -> int:
	return assert_eq(_type_chart.get_effectiveness(TypeEnums.Type.WOOD, TypeEnums.Type.WOOD), 1.0,
		"WOOD vs WOOD should be 1.0 (neutral)")


func test_fire_vs_water() -> int:
	return assert_eq(_type_chart.get_effectiveness(TypeEnums.Type.FIRE, TypeEnums.Type.WATER), 2.0,
		"FIRE vs WATER should be 2.0 (strong)")


func test_water_vs_fire() -> int:
	return assert_eq(_type_chart.get_effectiveness(TypeEnums.Type.WATER, TypeEnums.Type.FIRE), 1.0,
		"WATER vs FIRE should be 1.0 (neutral in this chart)")


func test_yang_vs_yin() -> int:
	return assert_eq(_type_chart.get_effectiveness(TypeEnums.Type.YANG, TypeEnums.Type.YIN), 2.0,
		"YANG vs YIN should be 2.0")


func test_wood_vs_fire_generating() -> int:
	return assert_eq(_type_chart.get_effectiveness(TypeEnums.Type.WOOD, TypeEnums.Type.FIRE), 1.25,
		"WOOD vs FIRE should be 1.25 (generating)")


func test_invalid_type_returns_neutral() -> int:
	var err := OK
	err = assert_eq(_type_chart.get_effectiveness(-1, 0), 1.0, "Invalid attacker type should return 1.0"); if err: return err
	err = assert_eq(_type_chart.get_effectiveness(0, 99), 1.0, "Invalid defender type should return 1.0"); if err: return err
	return OK
