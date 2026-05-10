extends RefCounted
class_name PlayerItemInstance

var definition: PlayerItemData
var charges: int = 0
var temporary_tags: Array[StringName] = []

static func from_definition(item_definition: PlayerItemData) -> PlayerItemInstance:
	var instance: PlayerItemInstance = PlayerItemInstance.new()
	instance.definition = item_definition
	return instance

func get_display_name() -> String:
	return definition.display_name if definition != null else "Item"
