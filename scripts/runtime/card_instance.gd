extends RefCounted
class_name CardInstance

var definition: CardData
var time_cost_override: int = -1
var temporary_tags: Array[StringName] = []

static func from_definition(card_definition: CardData) -> CardInstance:
	var instance: CardInstance = CardInstance.new()
	instance.definition = card_definition
	return instance

func get_time_cost() -> int:
	if time_cost_override >= 0:
		return time_cost_override
	return definition.time_cost if definition != null else 0

func get_display_name() -> String:
	return definition.display_name if definition != null else "Card"

func get_card_type() -> BattleTypes.CardType:
	return definition.card_type if definition != null else BattleTypes.CardType.NONE

func get_art_label() -> String:
	if definition == null:
		return ""
	if not definition.art_label.is_empty():
		return definition.art_label
	if definition.display_name.is_empty():
		return ""
	return definition.display_name.substr(0, 1)
