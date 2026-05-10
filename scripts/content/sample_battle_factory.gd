extends RefCounted
class_name SampleBattleFactory

static func create_demo_battle_definition() -> BattleDefinition:
	var battle: BattleDefinition = BattleDefinition.new()
	battle.id = &"demo_mold_bread_battle"
	battle.display_name = "霉菌面包演示战斗"
	battle.player_max_hp = 20
	battle.player_max_hand_size = 5
	battle.player_starting_hand_size = 5
	battle.player_max_stomach_volume = 6
	battle.starting_items = [_starter_item()]
	battle.starting_deck = _build_starting_deck()
	battle.enemy = _build_enemy()
	return battle

static func _build_starting_deck() -> Array[CardPileEntryData]:
	var deck: Array[CardPileEntryData] = []
	deck.append(_entry(_card_eat_front(), 2))
	deck.append(_entry(_card_digest_front(), 2))
	deck.append(_entry(_card_wash(), 2))
	deck.append(_entry(_card_cut(), 2))
	deck.append(_entry(_card_bake(), 2))
	deck.append(_entry(_card_focus(), 2))
	return deck

static func _build_enemy() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = &"mold_bread"
	enemy.display_name = "霉菌面包"
	enemy.food_blocks = [
		_block_mold(),
		_block_bread(),
		_block_mold(),
		_block_bread(),
	]
	enemy.purification_steps = [
		_step(&"clean", "清洗", BattleTypes.PurificationActionType.CLEAN),
		_step(&"cut", "切除", BattleTypes.PurificationActionType.CUT),
		_step(&"bake", "烘烤", BattleTypes.PurificationActionType.BAKE),
	]
	enemy.actions = [
		_attack_action(&"attack", "攻击", 2, 10),
		_add_block_action(&"spawn", "生成碎屑", _block_crumb(), 6),
		_charge_action(&"charge", "蓄力", 1, 4),
	]
	return enemy

static func _card_eat_front() -> CardData:
	var card: CardData = CardData.new()
	card.id = &"eat_front"
	card.display_name = "啃食前端"
	card.time_cost = 1
	card.card_type = BattleTypes.CardType.EAT
	card.art_label = "吃"
	card.description = "吃掉敌人最前方的食物块。"
	card.effects = [_effect(BattleTypes.EffectKind.EAT_ENEMY_BLOCK)]
	return card

static func _card_digest_front() -> CardData:
	var card: CardData = CardData.new()
	card.id = &"digest_front"
	card.display_name = "消化前端"
	card.time_cost = 2
	card.card_type = BattleTypes.CardType.DIGEST
	card.art_label = "消"
	card.description = "消化胃里最前方的食物块。"
	card.effects = [_effect(BattleTypes.EffectKind.DIGEST_STOMACH_ITEM)]
	return card

static func _card_wash() -> CardData:
	var card: CardData = CardData.new()
	card.id = &"wash"
	card.display_name = "清洗"
	card.time_cost = 1
	card.card_type = BattleTypes.CardType.PURIFY
	card.art_label = "洗"
	card.description = "推进一次清洗净化步骤。"
	card.effects = [_purify_effect(BattleTypes.PurificationActionType.CLEAN)]
	return card

static func _card_cut() -> CardData:
	var card: CardData = CardData.new()
	card.id = &"cut"
	card.display_name = "切除"
	card.time_cost = 3
	card.card_type = BattleTypes.CardType.PURIFY
	card.art_label = "切"
	card.description = "推进一次切除净化步骤。"
	card.effects = [_purify_effect(BattleTypes.PurificationActionType.CUT)]
	return card

static func _card_bake() -> CardData:
	var card: CardData = CardData.new()
	card.id = &"bake"
	card.display_name = "烘烤"
	card.time_cost = 4
	card.card_type = BattleTypes.CardType.PURIFY
	card.art_label = "烤"
	card.description = "推进一次烘烤净化步骤。"
	card.effects = [_purify_effect(BattleTypes.PurificationActionType.BAKE)]
	return card

static func _card_focus() -> CardData:
	var card: CardData = CardData.new()
	card.id = &"focus"
	card.display_name = "专注"
	card.time_cost = 0
	card.card_type = BattleTypes.CardType.SUPPORT
	card.art_label = "气"
	card.description = "获得 1 点临时体力。"
	card.effects = [_effect(BattleTypes.EffectKind.GAIN_ENERGY, 1)]
	return card

static func _starter_item() -> PlayerItemData:
	var item: PlayerItemData = PlayerItemData.new()
	item.id = &"starter_spoon"
	item.display_name = "起始汤匙"
	item.description = "为后续被动效果预留的占位道具。"
	return item

static func _block_mold() -> FoodBlockData:
	var block: FoodBlockData = FoodBlockData.new()
	block.id = &"mold_block"
	block.display_name = "霉菌块"
	block.volume = 1
	block.description = "带着霉味的一口，消化后效果不太妙。"
	block.digest_effects = [_effect(BattleTypes.EffectKind.DEAL_PLAYER_DAMAGE, 1)]
	return block

static func _block_bread() -> FoodBlockData:
	var block: FoodBlockData = FoodBlockData.new()
	block.id = &"bread_block"
	block.display_name = "面包块"
	block.volume = 1
	block.description = "普通面包，消化后可以转化成体力。"
	block.digest_effects = [_effect(BattleTypes.EffectKind.GAIN_ENERGY, 1)]
	return block

static func _block_crumb() -> FoodBlockData:
	var block: FoodBlockData = FoodBlockData.new()
	block.id = &"crumb_block"
	block.display_name = "碎屑块"
	block.volume = 1
	block.description = "敌人可以额外生成的小块食物。"
	block.digest_effects = [_effect(BattleTypes.EffectKind.DRAW_CARDS, 1)]
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

static func _charge_action(id: StringName, name: String, amount: int, time_delay: int) -> EnemyActionData:
	var action: EnemyActionData = EnemyActionData.new()
	action.id = id
	action.display_name = name
	action.action_type = BattleTypes.EnemyActionType.CHARGE_ATTACK
	action.amount = amount
	action.time_delay = time_delay
	return action

static func _entry(card: CardData, quantity: int) -> CardPileEntryData:
	var entry: CardPileEntryData = CardPileEntryData.new()
	entry.card = card
	entry.quantity = quantity
	return entry

static func _effect(kind: BattleTypes.EffectKind, amount: int = 0) -> BattleEffectData:
	var effect: BattleEffectData = BattleEffectData.new()
	effect.kind = kind
	effect.amount = amount
	return effect

static func _purify_effect(action: BattleTypes.PurificationActionType) -> BattleEffectData:
	var effect: BattleEffectData = BattleEffectData.new()
	effect.kind = BattleTypes.EffectKind.ADVANCE_PURIFICATION
	effect.purification_action = action
	return effect
