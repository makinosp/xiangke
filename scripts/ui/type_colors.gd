## Shared color and label mappings for the type system.
## Provides consistent type-to-color mapping, type display names,
## and status effect label/color lookups across the battle UI.
@tool
class_name TypeColors
extends Node


## Returns the color associated with a battle type.
static func get_type_color(type: int) -> Color:
	match type:
		TypeEnums.Type.WOOD:
			return Color("#4CAF50")
		TypeEnums.Type.FIRE:
			return Color("#F44336")
		TypeEnums.Type.EARTH:
			return Color("#FF9800")
		TypeEnums.Type.METAL:
			return Color("#9E9E9E")
		TypeEnums.Type.WATER:
			return Color("#2196F3")
		TypeEnums.Type.YANG:
			return Color("#FFD700")
		TypeEnums.Type.YIN:
			return Color("#9C27B0")
		_:
			return Color.WHITE


## Returns the display name for a battle type.
static func get_type_name(type: int) -> String:
	match type:
		TypeEnums.Type.WOOD:
			return TranslationServer.translate("ui.type_wood")
		TypeEnums.Type.FIRE:
			return TranslationServer.translate("ui.type_fire")
		TypeEnums.Type.EARTH:
			return TranslationServer.translate("ui.type_earth")
		TypeEnums.Type.METAL:
			return TranslationServer.translate("ui.type_metal")
		TypeEnums.Type.WATER:
			return TranslationServer.translate("ui.type_water")
		TypeEnums.Type.YANG:
			return TranslationServer.translate("ui.type_yang")
		TypeEnums.Type.YIN:
			return TranslationServer.translate("ui.type_yin")
		_:
			return "?"


## Returns the emoji + name label for a status effect.
static func get_status_effect_label(effect: int) -> String:
	match effect:
		TypeEnums.EffectType.BURN:
			return "🔥" + TranslationServer.translate("ui.effect_burn")
		TypeEnums.EffectType.POISON:
			return "☠" + TranslationServer.translate("ui.effect_poison")
		TypeEnums.EffectType.CONFUSION:
			return "❓" + TranslationServer.translate("ui.effect_confusion")
		TypeEnums.EffectType.CHAIN:
			return "⚡" + TranslationServer.translate("ui.effect_chain")
		TypeEnums.EffectType.CHARM:
			return "✨" + TranslationServer.translate("ui.effect_charm")
		_:
			return ""


## Returns the color for a status effect badge.
static func get_status_effect_color(effect: int) -> Color:
	match effect:
		TypeEnums.EffectType.BURN:
			return Color("#FF5722")
		TypeEnums.EffectType.POISON:
			return Color("#8BC34A")
		TypeEnums.EffectType.CONFUSION:
			return Color("#FF9800")
		TypeEnums.EffectType.CHAIN:
			return Color("#03A9F4")
		TypeEnums.EffectType.CHARM:
			return Color("#E91E63")
		_:
			return Color.WHITE


## Returns the display name for a stat.
static func get_stat_name(stat: int) -> String:
	match stat:
		TypeEnums.Stat.ATTACK:
			return TranslationServer.translate("ui.stat_attack")
		TypeEnums.Stat.DEFENSE:
			return TranslationServer.translate("ui.stat_defense")
		TypeEnums.Stat.SPEED:
			return TranslationServer.translate("ui.stat_speed")
		TypeEnums.Stat.INTELLIGENCE:
			return TranslationServer.translate("ui.stat_intelligence")
		TypeEnums.Stat.SPIRIT:
			return TranslationServer.translate("ui.stat_spirit")
		_:
			return "?"


## Returns the display name for a damage category.
static func get_category_name(category: int) -> String:
	match category:
		TypeEnums.DamageCategory.PHYSICAL:
			return TranslationServer.translate("ui.category_physical")
		TypeEnums.DamageCategory.ARTS:
			return TranslationServer.translate("ui.category_arts")
		_:
			return ""
