## Reusable panel displaying a single battle character's state.
## Shows name, type, HP bar, status effects, and stat stages.
class_name BattleUnitPanel
extends PanelContainer

## Name label showing the character's display name.
var _name_label: Label
## Type label showing primary (+ secondary) type in type color.
var _type_label: Label
## HP progress bar (0-100, percentage hidden).
var _hp_bar: ProgressBar
## HP text label (e.g., "120/150").
var _hp_label: Label
## Container for status effect badges.
var _status_container: HBoxContainer
## Container for stat stage indicators.
var _stat_container: HBoxContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Panel styling for visual distinction.
	add_theme_stylebox_override("panel", _create_panel_style())

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	# Row 1: Name + Type
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	vbox.add_child(header)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", 14)
	header.add_child(_name_label)

	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 12)
	header.add_child(_type_label)

	# Row 2: HP Bar
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(120, 12)
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	_hp_bar.show_percentage = false
	vbox.add_child(_hp_bar)

	# Row 3: HP Text
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 11)
	_hp_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(_hp_label)

	# Row 4: Status Effects
	_status_container = HBoxContainer.new()
	_status_container.add_theme_constant_override("separation", 4)
	vbox.add_child(_status_container)

	# Row 5: Stat Stages
	_stat_container = HBoxContainer.new()
	_stat_container.add_theme_constant_override("separation", 4)
	vbox.add_child(_stat_container)


func _create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	return style


## Updates all display elements from a battle participant's data.
func update_from_participant(p: BattleParticipant) -> void:
	if p == null or p.character_data == null:
		return

	# Name
	_name_label.text = p.character_data.name
	if p.is_defeated:
		_name_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		_name_label.add_theme_color_override("font_color", Color.WHITE)

	# Type
	_update_type_display(p.character_data)

	# HP Bar
	if p.is_defeated:
		_hp_bar.value = 0
		_hp_bar.modulate = Color.GRAY
	else:
		var hp_ratio: float = float(p.current_hp) / float(p.max_hp)
		_hp_bar.value = hp_ratio * 100.0
		if hp_ratio >= 0.5:
			_hp_bar.modulate = Color("#4CAF50")
		elif hp_ratio >= 0.25:
			_hp_bar.modulate = Color("#FFC107")
		else:
			_hp_bar.modulate = Color("#F44336")

	# HP Text
	if p.is_defeated:
		_hp_label.text = "DEFEATED"
		_hp_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		_hp_label.text = "%d/%d" % [p.current_hp, p.max_hp]
		_hp_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	# Status Effects
	_update_status_display(p.active_status_effects)

	# Stat Stages
	_update_stat_display(p.stat_stages)


func _update_type_display(char_data: CharacterData) -> void:
	var type_text: String = TypeColors.get_type_name(char_data.type)
	var type_color: Color = TypeColors.get_type_color(char_data.type)

	if char_data.has_secondary_type():
		type_text += "+" + TypeColors.get_type_name(char_data.secondary_type)

	_type_label.text = type_text
	_type_label.add_theme_color_override("font_color", type_color)


func _update_status_display(effects: Array[int]) -> void:
	# Clear existing badges.
	for child: Node in _status_container.get_children():
		child.queue_free()

	for effect: int in effects:
		var label_text: String = TypeColors.get_status_effect_label(effect)
		if label_text.is_empty():
			continue
		var badge := Label.new()
		badge.text = label_text
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_color_override("font_color", TypeColors.get_status_effect_color(effect))
		_status_container.add_child(badge)


func _update_stat_display(stages: Array[int]) -> void:
	# Clear existing indicators.
	for child: Node in _stat_container.get_children():
		child.queue_free()

	for i in range(stages.size()):
		var stage: int = stages[i]
		if stage == 0:
			continue
		var stat_label := Label.new()
		var arrow: String = "↑" if stage > 0 else "↓"
		stat_label.text = "%s%s%d" % [TypeColors.get_stat_name(i), arrow, abs(stage)]
		stat_label.add_theme_font_size_override("font_size", 10)
		if stage > 0:
			stat_label.add_theme_color_override("font_color", Color("#4CAF50"))
		else:
			stat_label.add_theme_color_override("font_color", Color("#F44336"))
		_stat_container.add_child(stat_label)


## Highlights or un-highlights this panel to indicate front character status.
func set_front_highlight(is_front: bool) -> void:
	var style: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		style = _create_panel_style()
		add_theme_stylebox_override("panel", style)

	if is_front:
		style.border_color = Color("#FFD700")
		style.set_border_width_all(2)
	else:
		style.border_color = Color(0.3, 0.3, 0.4)
		style.set_border_width_all(1)
