## Main test runner for GDScript unit tests.
## Usage: godot --headless -s res://tests/test_runner.gd -- --test-pattern=<filter>
## Or: run the scene res://tests/test_runner.tscn in the editor
extends Node

## List of test script paths to discover and run.
const TEST_SCRIPTS: Array[String] = [
	"res://tests/unit/test_game_manager.gd",
	"res://tests/unit/test_save_manager.gd",
	"res://tests/unit/test_ui_focus_manager.gd",
	"res://tests/unit/test_type_enums.gd",
	"res://tests/unit/test_type_chart.gd",
	"res://tests/unit/test_battle_flow_service.gd",
	"res://tests/unit/test_opponent_visibility.gd",
	"res://tests/unit/test_move_selection_ui.gd",
]

## Total counters
var _total_passed: int = 0
var _total_failed: int = 0
var _total_skipped: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	print("\n=== GDScript Test Runner ===")
	print("Godot version: ", Engine.get_version_info().string)
	print()

	var test_filter: String = _get_argument("test-pattern", "")
	var run_list: Array[String] = TEST_SCRIPTS

	if not test_filter.is_empty():
		run_list = []
		for path in TEST_SCRIPTS:
			if path.contains(test_filter):
				run_list.append(path)
		if run_list.is_empty():
			print("No tests match filter: ", test_filter)
			quit_with_code(0)
			return

	print("Running ", run_list.size(), " test suite(s)...\n")

	for script_path in run_list:
		_run_test_suite(script_path)

	_print_summary()
	if _total_failed > 0:
		quit_with_code(1)
	else:
		quit_with_code(0)


func _run_test_suite(script_path: String) -> void:
	var script = load(script_path)
	if not script:
		push_error("Failed to load test script: ", script_path)
		_total_skipped += 1
		return

	var instance = script.new()
	if not instance:
		push_error("Failed to instantiate test script: ", script_path)
		_total_skipped += 1
		return

	var suite_name: String = script_path.get_file().trim_suffix(".gd")
	print("  [", suite_name, "]")

	# Discover test methods (methods starting with "test_")
	var method_dicts = instance.get_method_list()
	var methods: Array[String] = []
	for m in method_dicts:
		if m.name.begins_with("test_"):
			methods.append(m.name)

	if instance.has_method("before_all"):
		instance.before_all()

	var passed: int = 0
	var failed: int = 0

	for method_name in methods:
		if instance.has_method("before_each"):
			instance.before_each()

		var ok = _run_test_method(instance, method_name)
		if ok:
			passed += 1
		else:
			failed += 1

		if instance.has_method("after_each"):
			instance.after_each()

	if instance.has_method("after_all"):
		instance.after_all()

	var status := "[OK]" if failed == 0 else "[FAIL]"
	print("    %s %d passed, %d failed, %d total\n" % [status, passed, failed, methods.size()])

	_total_passed += passed
	_total_failed += failed
	# RefCounted is garbage-collected; Node subclasses need explicit queuing.
	if instance is Node:
		instance.queue_free()


func _run_test_method(instance: Object, method_name: String) -> bool:
	var failed_msg: String = ""
	var ok := true

	var start_time := Time.get_ticks_usec()
	var err := _safe_call(instance, method_name)
	var elapsed := (Time.get_ticks_usec() - start_time) / 1000.0

	if err == ERR_SKIP:
		print("    ~ %s (skipped)" % method_name)
		_total_skipped += 1
		return true
	elif err != OK:
		print("    [FAIL] %s (%0.1fms) — FAILED" % [method_name, elapsed])
		_failures.append("%s.%s: %s" % [instance.get_script().resource_path.get_file().trim_suffix(".gd"), method_name, failed_msg])
		return false
	else:
		print("    [PASS] %s (%0.1fms)" % [method_name, elapsed])
		return true


## Safely call a method and capture any errors.
## Returns OK on success, ERR_SKIP if the test should be skipped, or ERR_SCRIPT_FAILED on failure.
func _safe_call(instance: Object, method_name: String) -> int:
	var result = instance.call(method_name)
	if result is int:
		return result as int
	return OK


func _print_summary() -> void:
	var sep := "=".repeat(40)
	print(sep)
	print("  Total: %d passed, %d failed, %d skipped" % [_total_passed, _total_failed, _total_skipped])

	if _failures.size() > 0:
		print("\n  Failures:")
		for f in _failures:
			print("    - ", f)

	if _total_failed > 0:
		print("\n  [FAIL] SOME TESTS FAILED")
	else:
		print("\n  [PASS] ALL TESTS PASSED")
	print(sep)


func _get_argument(name: String, default: String = "") -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--%s=" % name):
			return arg.trim_prefix("--%s=" % name)
		if arg.begins_with("--%s:" % name):
			return arg.trim_prefix("--%s:" % name)
	return default


func quit_with_code(code: int) -> void:
	if Engine.has_singleton("GameManager"):
		get_tree().quit(code)
	else:
		# Running as a standalone script or minimal scene
		get_tree().quit(code)
