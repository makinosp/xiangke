## Tests for the i18n system.
##
## Verifies that every translatable resource (characters, moves, status
## effects) carries a name_key/desc_key pair and that every key resolves to
## an actual translation in every supported locale. Also verifies that the
## four CSV catalogs expose identical key sets.
extends "res://tests/test_base.gd"

## Supported locale codes, matching SettingsManager.SUPPORTED_LOCALES.
const LOCALES: Array[String] = ["en", "ja", "zh_CN", "zh_TW"]
## Resource directories and the key prefix for each translatable kind.
const RESOURCE_DIRS: Dictionary = {
	"char": "res://resources/characters",
	"move": "res://resources/moves",
	"effect": "res://resources/status_effects",
}

## Collected translation key pairs from all resources:
## [{kind, id, name_key, desc_key}, ...]
var _entries: Array[Dictionary] = []


## Scans all translatable resources once before the test methods run.
func before_all() -> void:
	_collect_resource_keys()


## Loads every .tres under RESOURCE_DIRS and records its name_key/desc_key.
func _collect_resource_keys() -> void:
	for kind: String in RESOURCE_DIRS:
		var dir := DirAccess.open(RESOURCE_DIRS[kind])
		if dir == null:
			push_error("Cannot open resource dir: %s" % RESOURCE_DIRS[kind])
			continue
		for file_name: String in dir.get_files():
			if not file_name.ends_with(".tres"):
				continue
			var res := load(RESOURCE_DIRS[kind] + "/" + file_name)
			if res == null:
				continue
			_entries.append({
				"kind": kind,
				"id": file_name.get_basename(),
				"name_key": String(res.get("name_key")),
				"desc_key": String(res.get("desc_key")),
			})


## Every resource must carry well-formed name_key/desc_key values.
func test_all_resources_have_translation_keys() -> int:
	var err := OK
	if _entries.is_empty():
		return assert_true(false, "No translatable resources found")
	for entry: Dictionary in _entries:
		var kind: String = entry["kind"]
		var id: String = entry["id"]
		var name_key: String = entry["name_key"]
		var desc_key: String = entry["desc_key"]
		err = assert_true(
			name_key.begins_with(kind + ".") and name_key.ends_with(".name"),
			"Bad name_key %s for %s.%s" % [name_key, kind, id])
		if err:
			return err
		err = assert_true(
			desc_key.begins_with(kind + ".") and desc_key.ends_with(".desc"),
			"Bad desc_key %s for %s.%s" % [desc_key, kind, id])
		if err:
			return err
	return OK


## Every name_key/desc_key must translate to something other than the key
## itself in every supported locale.
func test_keys_resolve_in_all_locales() -> int:
	var original_locale := TranslationServer.get_locale()
	var err := OK
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		for entry: Dictionary in _entries:
			for key: String in [entry["name_key"], entry["desc_key"]]:
				var translated: String = TranslationServer.translate(key)
				err = assert_ne(
					translated, key,
					"Key %s unresolved in locale %s" % [key, locale])
				if err:
					TranslationServer.set_locale(original_locale)
					return err
	TranslationServer.set_locale(original_locale)
	return OK


## The four CSV catalogs must expose identical key sets.
func test_csv_key_sets_match_across_locales() -> int:
	var key_sets: Dictionary = {}
	for locale: String in LOCALES:
		key_sets[locale] = _read_csv_keys("res://translations/%s.csv" % locale)

	var base: Array[String] = key_sets["en"]
	if base.is_empty():
		return assert_true(false, "en.csv contains no keys")
	var err := OK
	for locale: String in LOCALES:
		var keys: Array[String] = key_sets[locale]
		err = assert_eq(keys.size(), base.size(),
			"%s.csv key count (%d) differs from en.csv (%d)"
			% [locale, keys.size(), base.size()])
		if err:
			return err
		for i in base.size():
			err = assert_eq(keys[i], base[i],
				"%s.csv key mismatch at row %d" % [locale, i + 1])
			if err:
				return err
	return OK


## Reads the first column of every data row in a Godot CSV catalog.
func _read_csv_keys(path: String) -> Array[String]:
	var keys: Array[String] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open CSV: %s" % path)
		return keys
	var first_line := true
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		if first_line:
			# Header row ("keys,<locale>"); strip UTF-8 BOM if present.
			first_line = false
			continue
		keys.append(line.split(",", false)[0].trim_prefix("\uFEFF"))
	file.close()
	return keys
