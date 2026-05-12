extends RefCounted
class_name EnemyRuntime

var definition: EnemyData
var blocks: Array[FoodBlockInstance] = []
var purification_index: int = 0
var purification_completed: Array[bool] = []
var action_index: int = 0
var charged_attack_bonus: int = 0
var action_schedule: Array[int] = []
var next_action_time: int = -1

static func from_definition(enemy_definition: EnemyData) -> EnemyRuntime:
	var instance: EnemyRuntime = EnemyRuntime.new()
	instance.definition = enemy_definition
	if enemy_definition != null:
		for block_definition in enemy_definition.food_blocks:
			instance.blocks.append(FoodBlockInstance.from_definition(block_definition))
		instance.purification_completed.resize(enemy_definition.purification_steps.size())
		for i in range(instance.purification_completed.size()):
			instance.purification_completed[i] = false
		instance._build_action_schedule()
	return instance

func is_cleared() -> bool:
	return blocks.is_empty()

func is_purified() -> bool:
	return definition != null and purification_index >= definition.purification_steps.size()

func current_step() -> PurificationStepData:
	if definition == null:
		return null
	for i in range(definition.purification_steps.size()):
		if not purification_completed[i]:
			return definition.purification_steps[i]
	return null

func current_action() -> EnemyActionData:
	if definition == null or definition.actions.is_empty():
		return null
	return definition.actions[action_index % definition.actions.size()]

func has_current_action() -> bool:
	return current_action() != null

func get_current_action_time() -> int:
	if action_index < 0 or action_index >= action_schedule.size():
		return -1
	return action_schedule[action_index]

func get_current_intent_label() -> String:
	var action: EnemyActionData = current_action()
	if action == null:
		return "待机"
	return action.display_name if not action.display_name.is_empty() else "意图"

func get_action_labels_at_time(time_point: int) -> Array[String]:
	var labels: Array[String] = []
	if definition == null or definition.actions.is_empty():
		return labels
	for i in range(action_schedule.size()):
		if action_schedule[i] != time_point:
			continue
		var action: EnemyActionData = definition.actions[i % definition.actions.size()]
		if action == null:
			continue
		labels.append(action.display_name if not action.display_name.is_empty() else "Intent")
	return labels

func advance_action() -> void:
	action_index += 1
	if action_index >= action_schedule.size():
		_build_action_schedule(maxi(16, action_schedule.size()))
	next_action_time = get_current_action_time()

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

func has_pending_purification_action(action: BattleTypes.PurificationActionType) -> bool:
	if definition == null:
		return false
	for i in range(definition.purification_steps.size()):
		if purification_completed[i]:
			continue
		if definition.purification_steps[i].required_action == action:
			return true
	return false

func complete_purification_action(action: BattleTypes.PurificationActionType) -> PurificationStepData:
	if definition == null:
		return null
	for i in range(definition.purification_steps.size()):
		if purification_completed[i]:
			continue
		var step: PurificationStepData = definition.purification_steps[i]
		if step.required_action != action:
			continue
		purification_completed[i] = true
		purification_index += 1
		return step
	return null

func delay_next_action(amount: int) -> void:
	if action_index < 0 or action_index >= action_schedule.size():
		return
	var shift: int = maxi(0, amount)
	action_schedule[action_index] += shift
	for i in range(action_index + 1, action_schedule.size()):
		action_schedule[i] += shift
	next_action_time = action_schedule[action_index]

func delay_all_actions(amount: int) -> void:
	var shift: int = maxi(0, amount)
	if shift <= 0:
		return
	for i in range(action_index, action_schedule.size()):
		action_schedule[i] += shift
	next_action_time = get_current_action_time()

func _build_action_schedule(min_entries: int = 32) -> void:
	action_schedule.clear()
	if definition == null or definition.actions.is_empty():
		next_action_time = -1
		return
	var accumulated_time: int = 0
	var schedule_count: int = maxi(min_entries, definition.actions.size())
	for i in range(schedule_count):
		var action: EnemyActionData = definition.actions[i % definition.actions.size()]
		accumulated_time += maxi(0, action.time_delay)
		action_schedule.append(accumulated_time)
	next_action_time = action_schedule[0]
