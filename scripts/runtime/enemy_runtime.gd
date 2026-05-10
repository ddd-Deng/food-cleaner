extends RefCounted
class_name EnemyRuntime

var definition: EnemyData
var blocks: Array[FoodBlockInstance] = []
var purification_index: int = 0
var action_index: int = 0
var charged_attack_bonus: int = 0
var next_action_time: int = -1

static func from_definition(enemy_definition: EnemyData) -> EnemyRuntime:
	var instance: EnemyRuntime = EnemyRuntime.new()
	instance.definition = enemy_definition
	if enemy_definition != null:
		for block_definition in enemy_definition.food_blocks:
			instance.blocks.append(FoodBlockInstance.from_definition(block_definition))
		instance._refresh_next_action_time()
	return instance

func is_cleared() -> bool:
	return blocks.is_empty()

func is_purified() -> bool:
	return definition != null and purification_index >= definition.purification_steps.size()

func current_step() -> PurificationStepData:
	if definition == null:
		return null
	if purification_index < 0 or purification_index >= definition.purification_steps.size():
		return null
	return definition.purification_steps[purification_index]

func current_action() -> EnemyActionData:
	if definition == null or definition.actions.is_empty():
		return null
	return definition.actions[action_index % definition.actions.size()]

func has_current_action() -> bool:
	return current_action() != null

func get_current_action_time() -> int:
	return next_action_time

func get_current_intent_label() -> String:
	var action: EnemyActionData = current_action()
	if action == null:
		return "待机"
	return action.display_name if not action.display_name.is_empty() else "意图"

func advance_action() -> void:
	action_index += 1
	_refresh_next_action_time()

func add_block(block_definition: FoodBlockData) -> void:
	if block_definition == null:
		return
	blocks.append(FoodBlockInstance.from_definition(block_definition))

func remove_front_block() -> FoodBlockInstance:
	if blocks.is_empty():
		return null
	var block: FoodBlockInstance = blocks[0]
	blocks.remove_at(0)
	return block

func _refresh_next_action_time() -> void:
	if definition == null or definition.actions.is_empty() or action_index >= definition.actions.size():
		next_action_time = -1
		return
	if action_index == 0:
		next_action_time = maxi(0, definition.actions[0].time_delay)
		return
	next_action_time += maxi(0, definition.actions[action_index].time_delay)
