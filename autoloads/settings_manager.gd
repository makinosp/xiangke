## SettingsManager autoload singleton.
## Owns runtime settings (language) and applies them on startup.
## Volume settings are owned by AudioManager; this autoload only resolves
## and persists the active locale.
extends Node

## Supported locale codes, in display order.
const SUPPORTED_LOCALES: Array[String] = ["en", "ja", "zh_CN", "zh_TW"]
## Fallback locale used when nothing else applies.
const DEFAULT_LOCALE: String = "en"

## Currently active locale code.
var current_locale: String = DEFAULT_LOCALE


func _ready() -> void:
	apply_settings()


## Applies persisted settings at startup (language + volumes).
func apply_settings() -> void:
	var saved: String = SaveManager.current_data.get("language", "")
	set_language(_resolve_locale(saved), false)


## Resolves the effective locale: saved value → system locale → default.
##
## Parameters:
##   saved: The persisted locale code, or empty when unset.
func _resolve_locale(saved: String) -> String:
	if saved in SUPPORTED_LOCALES:
		return saved
	var system := TranslationServer.get_locale()
	if system in SUPPORTED_LOCALES:
		return system
	# Normalize language-only codes (e.g. "zh" → zh_CN).
	var lang := system.split("_")[0]
	if lang == "zh":
		return "zh_CN"
	return DEFAULT_LOCALE


## Sets the active language, applies it to TranslationServer, and persists it.
##
## Parameters:
##   locale: One of SUPPORTED_LOCALES.
##   persist: Whether to write the value to save data (default true).
##
## Returns:
##   true if the locale was applied, false if it is unsupported.
func set_language(locale: String, persist: bool = true) -> bool:
	if locale not in SUPPORTED_LOCALES:
		push_warning("SettingsManager: Unsupported locale: %s" % locale)
		return false
	current_locale = locale
	TranslationServer.set_locale(locale)
	if persist:
		SaveManager.current_data["language"] = locale
		SaveManager.save_game()
	return true


## Returns the list of supported locales.
func get_supported_locales() -> Array[String]:
	return SUPPORTED_LOCALES
