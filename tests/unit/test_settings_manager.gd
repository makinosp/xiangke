## Tests for SettingsManager locale resolution and application.
##
## Verifies _resolve_locale fallback/normalization logic and that
## set_language applies the locale to TranslationServer (persistence via
## SaveManager is tested separately in test_save_manager.gd).
extends "res://tests/test_base.gd"

var _settings_manager = null
var _original_locale: String = ""


func before_each() -> void:
	_settings_manager = load("res://autoloads/settings_manager.gd").new()
	_original_locale = TranslationServer.get_locale()


func after_each() -> void:
	TranslationServer.set_locale(_original_locale)


## A saved supported locale is used as-is.
func test_resolve_locale_uses_saved_value() -> int:
	return assert_eq(_settings_manager._resolve_locale("ja"), "ja",
		"Saved ja should resolve to ja")


## zh (language-only) is normalized to zh_CN.
func test_resolve_locale_normalizes_zh() -> int:
	TranslationServer.set_locale("zh")
	return assert_eq(_settings_manager._resolve_locale(""), "zh_CN",
		"System zh should normalize to zh_CN")


## A supported system locale is used when nothing is saved.
func test_resolve_locale_uses_system_when_empty() -> int:
	TranslationServer.set_locale("ja")
	return assert_eq(_settings_manager._resolve_locale(""), "ja",
		"Empty saved value should fall back to system ja")


## An unsupported saved value falls back to the system locale or default.
func test_resolve_locale_unsupported_falls_back() -> int:
	TranslationServer.set_locale("ja")
	var resolved: String = _settings_manager._resolve_locale("fr")
	return assert_eq(resolved, "ja", "Unsupported fr should fall back to system ja")


## An unsupported saved value with an unsupported system locale uses default.
func test_resolve_locale_default_when_all_unsupported() -> int:
	TranslationServer.set_locale("fr")
	return assert_eq(_settings_manager._resolve_locale("de"), "en",
		"Unsupported saved and system locales should fall back to en")


## set_language applies the locale to TranslationServer without persisting
## when persist is false (avoids SaveManager dependency in unit tests).
func test_set_language_applies_locale() -> int:
	var ok: bool = _settings_manager.set_language("zh_TW", false)
	var err := OK
	err = assert_eq(ok, true, "set_language should accept zh_TW"); if err: return err
	return assert_eq(TranslationServer.get_locale(), "zh_TW",
		"TranslationServer locale should be zh_TW after set_language")


## set_language rejects unsupported locales.
func test_set_language_rejects_unsupported() -> int:
	var ok: bool = _settings_manager.set_language("xx", false)
	return assert_eq(ok, false, "set_language should reject unsupported locale")


## SUPPORTED_LOCALES contains exactly the four catalog languages.
func test_supported_locales_are_complete() -> int:
	var err := OK
	err = assert_eq(_settings_manager.SUPPORTED_LOCALES.size(), 4,
		"Should support exactly 4 locales"); if err: return err
	for locale: String in ["en", "ja", "zh_CN", "zh_TW"]:
		err = assert_true(_settings_manager.SUPPORTED_LOCALES.has(locale),
			"Missing locale %s" % locale)
		if err:
			return err
	return OK
