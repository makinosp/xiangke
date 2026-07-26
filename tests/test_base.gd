## Base class for GDScript unit tests.
## Provides assert_eq/assert_ne/assert_true/assert_false helpers.
extends RefCounted


## Assert that `got` equals `expected`. Emits a push_error and returns ERR_SCRIPT_FAILED on mismatch.
func assert_eq(got, expected, msg: String = "") -> int:
	if got != expected:
		var detail := "%s != %s" % [got, expected]
		if not msg.is_empty():
			detail = msg + " (" + detail + ")"
		push_error("FAIL: " + detail)
		return ERR_SCRIPT_FAILED
	return OK


## Assert that `got` does NOT equal `unexpected`.
func assert_ne(got, unexpected, msg: String = "") -> int:
	if got == unexpected:
		var detail := "%s == %s" % [got, unexpected]
		if not msg.is_empty():
			detail = msg + " (" + detail + ")"
		push_error("FAIL: " + detail)
		return ERR_SCRIPT_FAILED
	return OK


## Assert that `value` is true.
func assert_true(value: bool, msg: String = "") -> int:
	return assert_eq(value, true, msg)


## Assert that `value` is false.
func assert_false(value: bool, msg: String = "") -> int:
	return assert_eq(value, false, msg)
