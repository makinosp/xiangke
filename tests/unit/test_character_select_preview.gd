## Tests for the character select preview panel.
##
## Verifies the StatsPreview container layout on the character select screen:
## every element fits inside the panel without overlap, the description stays
## within bounds even for the longest catalog description, and opponent hover
## populates and hides the preview.
extends "res://tests/test_base.gd"

## Player corps IDs used to populate the character grid.
const PLAYER_IDS: Array[String] = ["preview_p1", "preview_p2", "preview_p3"]
## Opponent corps IDs shown as read-only labels.
const OPPONENT_IDS: Array[String] = ["preview_o1", "preview_o2"]
## A character with a single move, used for the "fewer than four moves" case.
const FEW_MOVES_ID: String = "preview_few"
## Move ID registered in before_all().
const MOVE_ID: String = "preview_move"


func before_all() -> void:
	# Register the shared test move.
	if not DataRegistry._moves.has(MOVE_ID):
		var move := MoveData.new()
		move.id = MOVE_ID
		move.name_key = "preview.move"
		move.type = TypeEnums.Type.FIRE
		DataRegistry._moves[MOVE_ID] = move

	# Register player and opponent test characters (4 moves each).
	var all_ids: Array[String] = PLAYER_IDS + OPPONENT_IDS
	for i in all_ids.size():
		var id: String = all_ids[i]
		if DataRegistry._characters.has(id):
			continue
		var cd := CharacterData.new()
		cd.id = id
		cd.name = id
		cd.name_key = "Preview Character %d" % (i + 1)
		cd.type = TypeEnums.Type.FIRE
		cd.secondary_type = -1
		cd.hp = 100 + i
		cd.attack = 50 + i
		cd.defense = 40 + i
		cd.speed = 30 + i
		cd.intelligence = 60 + i
		cd.spirit = 20 + i
		cd.moves = PackedStringArray([MOVE_ID, MOVE_ID, MOVE_ID, MOVE_ID])
		cd.desc_key = "preview.desc.%s" % id
		DataRegistry._characters[id] = cd

	# Register a one-move character.
	if not DataRegistry._characters.has(FEW_MOVES_ID):
		var cd := CharacterData.new()
		cd.id = FEW_MOVES_ID
		cd.name = FEW_MOVES_ID
		cd.name_key = "Preview One Move"
		cd.type = TypeEnums.Type.EARTH
		cd.secondary_type = -1
		cd.hp = 90
		cd.attack = 55
		cd.defense = 45
		cd.speed = 35
		cd.intelligence = 50
		cd.spirit = 25
		cd.moves = PackedStringArray([MOVE_ID])
		cd.desc_key = "preview.desc.%s" % FEW_MOVES_ID
		DataRegistry._characters[FEW_MOVES_ID] = cd

	# Point the roster at the test characters.
	GameManager.corps_roster.corps_characters = PLAYER_IDS
	GameManager.corps_roster.opponent_corps = OPPONENT_IDS


## Returns the current SceneTree (the test runner executes as a scene).
func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Instantiates the character select scene and adds it to the tree so
## container layout is computed.
func _make_scene() -> Node:
	var scene: Node = load("res://scenes/character_select.tscn").instantiate()
	_tree().root.add_child(scene)
	return scene


## Returns the global rects of every preview element in layout order.
func _element_rects(scene: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	rects.append(scene.preview_name.get_global_rect() as Rect2)
	rects.append(scene.preview_type.get_global_rect() as Rect2)
	rects.append(scene.preview_hp.get_global_rect() as Rect2)
	rects.append(scene.preview_attack.get_global_rect() as Rect2)
	rects.append(scene.preview_defense.get_global_rect() as Rect2)
	rects.append(scene.preview_speed.get_global_rect() as Rect2)
	rects.append(scene.preview_intelligence.get_global_rect() as Rect2)
	rects.append(scene.preview_spirit.get_global_rect() as Rect2)
	rects.append(scene.preview_move_1.get_global_rect() as Rect2)
	rects.append(scene.preview_move_2.get_global_rect() as Rect2)
	rects.append(scene.preview_move_3.get_global_rect() as Rect2)
	rects.append(scene.preview_move_4.get_global_rect() as Rect2)
	rects.append(scene.preview_desc.get_global_rect() as Rect2)
	return rects


## Returns the longest flavor description from the loaded catalog.
func _longest_catalog_desc() -> String:
	var longest := ""
	for id in DataRegistry.get_all_characters().keys():
		var cd: CharacterData = DataRegistry.get_character(id)
		if cd.desc_key.is_empty():
			continue
		var text := tr(cd.desc_key)
		if text.length() > longest.length():
			longest = text
	return longest


func test_preview_layout_fits_panel() -> int:
	var scene := _make_scene()
	var err: int = assert_true(scene.is_inside_tree(),
		"Character select scene must be inside the tree")
	if err:
		return err
	await _tree().process_frame
	scene._on_character_hovered(PLAYER_IDS[0])
	await _tree().process_frame

	var panel_rect: Rect2 = scene.stats_preview.get_global_rect()
	for r in _element_rects(scene):
		err = assert_true(panel_rect.encloses(r),
			"Element rect %s must be inside panel rect %s" % [r, panel_rect])
		if err:
			scene.free()
			return err

	var rects := _element_rects(scene)
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			err = assert_false(rects[i].intersects(rects[j]),
				"Elements %d and %d must not overlap" % [i, j])
			if err:
				scene.free()
				return err
	scene.free()
	return err


func test_description_fits_with_longest_catalog_desc() -> int:
	var scene := _make_scene()
	var err: int = assert_true(scene.is_inside_tree(),
		"Character select scene must be inside the tree")
	if err:
		return err
	await _tree().process_frame
	var longest := _longest_catalog_desc()
	err = assert_true(longest.length() > 0,
		"Catalog should contain a flavor description")
	if err:
		scene.free()
		return err

	scene._on_character_hovered(PLAYER_IDS[0])
	scene.preview_desc.text = longest
	await _tree().process_frame

	var panel_rect: Rect2 = scene.stats_preview.get_global_rect()
	var desc_rect: Rect2 = scene.preview_desc.get_global_rect()
	err = assert_true(panel_rect.encloses(desc_rect),
		"Description rect %s must fit in panel rect %s" % [desc_rect, panel_rect])
	scene.free()
	return err


func test_fewer_moves_lets_desc_absorb_space() -> int:
	var scene := _make_scene()
	var err: int = assert_true(scene.is_inside_tree(),
		"Character select scene must be inside the tree")
	if err:
		return err
	await _tree().process_frame
	scene._on_character_hovered(FEW_MOVES_ID)
	await _tree().process_frame

	err = assert_false(scene.preview_move_2.visible,
		"Move 2 should be hidden for a one-move character")
	if err:
		scene.free()
		return err
	var panel_rect: Rect2 = scene.stats_preview.get_global_rect()
	var desc_rect: Rect2 = scene.preview_desc.get_global_rect()
	err = assert_true(panel_rect.encloses(desc_rect),
		"Description rect %s must fit in panel rect %s" % [desc_rect, panel_rect])
	if err:
		scene.free()
		return err
	err = assert_false(desc_rect.intersects(scene.preview_move_1.get_global_rect() as Rect2),
		"Description must not overlap the move list")
	scene.free()
	return err


func test_opponent_hover_populates_preview() -> int:
	var scene := _make_scene()
	var err: int = assert_true(scene.is_inside_tree(),
		"Character select scene must be inside the tree")
	if err:
		return err
	await _tree().process_frame

	var labels: Array[Node] = scene.opponent_label_container.get_children()
	err = assert_eq(labels.size(), OPPONENT_IDS.size(),
		"Opponent list should contain one label per opponent")
	if err:
		scene.free()
		return err
	var first_label := labels[0] as Label
	err = assert_eq(first_label.mouse_filter, Control.MOUSE_FILTER_STOP,
		"Opponent labels should stop mouse events so hover works")
	if err:
		scene.free()
		return err

	# Hovering an opponent reuses the same handler as player characters.
	scene._on_character_hovered(OPPONENT_IDS[0])
	await _tree().process_frame

	err = assert_true(scene.stats_preview.visible,
		"Hovering an opponent should show the preview")
	if err:
		scene.free()
		return err
	var cd := DataRegistry.get_character(OPPONENT_IDS[0])
	err = assert_eq(scene.preview_name.text, tr(cd.name_key),
		"Preview should show the opponent's name")
	if err:
		scene.free()
		return err
	err = assert_eq(scene.preview_hp.text, tr("ui.hp") % cd.hp,
		"Preview should show the opponent's HP")
	if err:
		scene.free()
		return err
	err = assert_eq(scene.preview_desc.text, tr(cd.desc_key),
		"Preview should show the opponent's description")
	scene.free()
	return err


func test_hover_exit_hides_preview() -> int:
	var scene := _make_scene()
	var err: int = assert_true(scene.is_inside_tree(),
		"Character select scene must be inside the tree")
	if err:
		return err
	await _tree().process_frame
	scene._on_character_hovered(PLAYER_IDS[0])
	err = assert_true(scene.stats_preview.visible,
		"Preview should be visible after hover")
	if err:
		scene.free()
		return err
	scene._on_character_hover_exit()
	err = assert_false(scene.stats_preview.visible,
		"Preview should hide after hover exit")
	scene.free()
	return err
