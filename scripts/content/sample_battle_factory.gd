extends RefCounted
class_name SampleBattleFactory

static func create_demo_battle_definition() -> BattleDefinition:
	var battle: BattleDefinition = BattleDefinition.new()
	battle.id = &"demo_food_cleaner_battle"
	battle.display_name = "食物清道夫演示战斗"
	battle.player_max_hp = 20
	battle.player_starting_hp = 20
	battle.player_max_hand_size = 8
	battle.player_starting_hand_size = 4
	battle.player_max_stomach_volume = 6
	battle.starting_items = [_starter_item()]
	battle.starting_deck = CardCatalog.build_card_entries()
	battle.monster_id = &"marshmallow"
	battle.enemy = _build_enemy()
	return battle

static func _build_enemy() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = &"spoiled_lunchbox"
	enemy.display_name = "变质便当"
	enemy.food_blocks = [
		_block_rice(),
		_block_rotten_meat(),
		_block_vegetable(),
	]
	enemy.purification_steps = [
		_step(&"dirty", "脏污", BattleTypes.PurificationActionType.WASH),
		_step(&"rotten", "腐败", BattleTypes.PurificationActionType.TRIM),
		_step(&"filthy", "污秽", BattleTypes.PurificationActionType.PURGE),
	]
	enemy.actions = [
		_attack_action(&"peck", "啄咬", 2, 4),
		_attack_action(&"scratch", "抓挠", 3, 3),
		_add_block_action(&"crumb", "掉落碎屑", _block_crumb(), 5),
	]
	return enemy

static func _starter_item() -> PlayerItemData:
	var item: PlayerItemData = PlayerItemData.new()
	item.id = &"starter_spoon"
	item.display_name = "起始汤匙"
	item.description = "当前仍是占位道具。"
	return item

static func _block_rice() -> FoodBlockData:
	var block: FoodBlockData = FoodBlockData.new()
	block.id = &"rice"
	block.display_name = "米饭块"
	block.volume = 1
	block.digest_time = 2
	block.description = "正常的主食。"
	return block

static func _block_rotten_meat() -> FoodBlockData:
	var block: FoodBlockData = FoodBlockData.new()
	block.id = &"rotten_meat"
	block.display_name = "腐肉块"
	block.volume = 1
	block.digest_time = 3
	block.description = "消化完成后会反噬玩家。"
	block.digest_effects = [_effect(BattleTypes.EffectKind.DEAL_PLAYER_DAMAGE, 2)]
	return block

static func _block_vegetable() -> FoodBlockData:
	var block: FoodBlockData = FoodBlockData.new()
	block.id = &"vegetable"
	block.display_name = "菜叶块"
	block.volume = 1
	block.digest_time = 1
	block.description = "比较容易消化。"
	return block

static func _block_crumb() -> FoodBlockData:
	var block: FoodBlockData = FoodBlockData.new()
	block.id = &"crumb"
	block.display_name = "碎屑块"
	block.volume = 1
	block.digest_time = 1
	block.description = "敌人追加的小块食物。"
	return block

static func _step(id: StringName, name: String, action: BattleTypes.PurificationActionType) -> PurificationStepData:
	var step: PurificationStepData = PurificationStepData.new()
	step.id = id
	step.display_name = name
	step.required_action = action
	return step

static func _attack_action(id: StringName, name: String, amount: int, time_delay: int) -> EnemyActionData:
	var action: EnemyActionData = EnemyActionData.new()
	action.id = id
	action.display_name = name
	action.action_type = BattleTypes.EnemyActionType.ATTACK
	action.amount = amount
	action.time_delay = time_delay
	return action

static func _add_block_action(id: StringName, name: String, block_definition: FoodBlockData, time_delay: int) -> EnemyActionData:
	var action: EnemyActionData = EnemyActionData.new()
	action.id = id
	action.display_name = name
	action.action_type = BattleTypes.EnemyActionType.ADD_BLOCK
	action.payload = {"block_definition": block_definition}
	action.time_delay = time_delay
	return action

static func _effect(kind: BattleTypes.EffectKind, amount: int = 0) -> BattleEffectData:
	var effect: BattleEffectData = BattleEffectData.new()
	effect.kind = kind
	effect.amount = amount
	return effect
