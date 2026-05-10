extends RefCounted
class_name FoodBlockInstance

var definition: FoodBlockData
var volume: int = 1
var tags: Array[StringName] = []

static func from_definition(block_definition: FoodBlockData) -> FoodBlockInstance:
	var instance: FoodBlockInstance = FoodBlockInstance.new()
	instance.definition = block_definition
	if block_definition != null:
		instance.volume = block_definition.volume
		instance.tags = block_definition.tags.duplicate()
	return instance

func get_display_name() -> String:
	return definition.display_name if definition != null else "Food Block"
