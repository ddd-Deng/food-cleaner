extends RefCounted
class_name MonsterCatalog

const MONSTER_ANIMATION_ROOT := "res://sprites/怪物_256x144"

static func get_monster_definition(monster_id: StringName) -> MonsterDefinition:
	var definitions := _build_definitions()
	return definitions.get(monster_id, null)

static func get_all_monster_definitions() -> Array[MonsterDefinition]:
	return _build_definitions().values()

static func _build_definitions() -> Dictionary:
	var definitions: Dictionary = {}

	definitions[&"marshmallow"] = _build_monster(
		&"marshmallow",
		"污染怪物",
		"怪物房",
		"res://scenes/rooms/marshmallow_room.tscn",
		MONSTER_ANIMATION_ROOT + "/棉花糖",
		_build_marshmallow_enemy()
	)
	definitions[&"candy_bean"] = _build_monster(
		&"candy_bean",
		"污染怪物",
		"怪物房",
		"res://scenes/rooms/candy_bean_room.tscn",
		MONSTER_ANIMATION_ROOT + "/糖豆人",
		_build_candy_bean_enemy()
	)
	definitions[&"strawberry"] = _build_monster(
		&"strawberry",
		"污染怪物",
		"怪物房",
		"res://scenes/rooms/strawberry_room.tscn",
		MONSTER_ANIMATION_ROOT + "/草莓",
		_build_strawberry_enemy()
	)
	definitions[&"fish_boss"] = _build_monster(
		&"fish_boss",
		"Boss",
		"Boss房",
		"res://scenes/rooms/fish_boss_room.tscn",
		MONSTER_ANIMATION_ROOT + "/鱼",
		_build_fish_enemy()
	)

	return definitions

static func _build_monster(
	monster_id: StringName,
	display_name: String,
	room_display_name: String,
	room_scene_path: String,
	animation_dir: String,
	enemy_definition: EnemyData
) -> MonsterDefinition:
	var definition := MonsterDefinition.new()
	definition.id = monster_id
	definition.display_name = display_name
	definition.room_display_name = room_display_name
	definition.room_scene_path = room_scene_path
	definition.explore_animation_dir = animation_dir
	definition.battle_animation_dir = animation_dir
	definition.animation_fps = 10.0
	definition.outline_color = Color(1.0, 0.95, 0.72, 1.0)
	definition.outline_thickness = 4.0
	definition.enemy_definition = enemy_definition
	return definition

static func _build_marshmallow_enemy() -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"marshmallow"
	enemy.display_name = "污染怪物"
	enemy.food_blocks = [
		_block(&"sugar_cube", "糖块", 1, 1, "轻飘飘的甜块。"),
		_block(&"sticky_cream", "黏奶油", 1, 2, "会稍微拖慢节奏。"),
		_block(&"burnt_shell", "焦糖壳", 1, 2, "外层有点硬。"),
	]
	enemy.purification_steps = [
		_step(&"wash", "洗去糖霜", BattleTypes.PurificationActionType.WASH),
		_step(&"trim", "剔掉焦层", BattleTypes.PurificationActionType.TRIM),
	]
	enemy.actions = [
		_attack_action(&"sticky_hit", "黏弹拍击", 2, 2),
		_add_block_action(&"sprinkle", "洒落糖粒", _block(&"sprinkle", "糖粒", 1, 1, "小块糖粒。"), 2),
		_attack_action(&"bounce", "弹跳撞击", 3, 2),
	]
	return enemy

static func _build_candy_bean_enemy() -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"candy_bean"
	enemy.display_name = "污染怪物"
	enemy.food_blocks = [
		_block(&"bean_shell", "豆壳片", 1, 2, "甜味很重。"),
		_block(&"syrup_core", "糖浆芯", 1, 3, "太甜会反噬。", [_effect(BattleTypes.EffectKind.DEAL_PLAYER_DAMAGE, 1)]),
		_block(&"crumb", "碎糖", 1, 1, "容易消化。"),
	]
	enemy.purification_steps = [
		_step(&"trim", "去硬壳", BattleTypes.PurificationActionType.TRIM),
		_step(&"correct", "矫正糖化", BattleTypes.PurificationActionType.CORRECT),
	]
	enemy.actions = [
		_charge_action(&"charge", "蓄力滚撞", 2, 2),
		_attack_action(&"slam", "滚撞冲击", 4, 1),
		_attack_action(&"kick", "糖豆踢击", 2, 2),
	]
	return enemy

static func _build_strawberry_enemy() -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"strawberry"
	enemy.display_name = "污染怪物"
	enemy.food_blocks = [
		_block(&"berry_meat", "莓肉块", 1, 1, "多汁柔软。"),
		_block(&"seed_cluster", "籽团", 1, 2, "细小但烦人。"),
		_block(&"sour_core", "酸芯", 1, 2, "会刺激胃。", [_effect(BattleTypes.EffectKind.DEAL_PLAYER_DAMAGE, 1)]),
	]
	enemy.purification_steps = [
		_step(&"wash", "清洗果皮", BattleTypes.PurificationActionType.WASH),
		_step(&"deworm", "除虫", BattleTypes.PurificationActionType.DEWORM),
		_step(&"purge", "净除腐味", BattleTypes.PurificationActionType.PURGE),
	]
	enemy.actions = [
		_add_block_action(&"grow_seed", "籽团增殖", _block(&"seed_cluster_extra", "增殖籽团", 1, 2, "不断长出。"), 3),
		_corrupt_action(&"rot_spread", "腐坏扩散", 2, 2),
		_attack_action(&"acid_splash", "酸汁喷溅", 2, 2),
		_attack_action(&"vine_whip", "果蒂抽打", 3, 2),
	]
	return enemy

static func _build_fish_enemy() -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"fish_boss"
	enemy.display_name = "Boss"
	enemy.food_blocks = [
		_block(&"scale", "污鳞", 1, 2, "腥味很重。"),
		_block(&"fish_meat", "鱼肉块", 1, 2, "纤维明显。"),
		_block(&"bone", "细鱼骨", 1, 3, "消化时会扎伤。", [_effect(BattleTypes.EffectKind.DEAL_PLAYER_DAMAGE, 2)]),
		_block(&"roe", "腐败鱼卵", 1, 1, "会继续扩散。"),
	]
	enemy.purification_steps = [
		_step(&"wash", "冲净黏液", BattleTypes.PurificationActionType.WASH),
		_step(&"trim", "剔除骨刺", BattleTypes.PurificationActionType.TRIM),
		_step(&"purge", "净除腥腐", BattleTypes.PurificationActionType.PURGE),
	]
	enemy.actions = [
		_attack_action(&"tail_slap", "甩尾拍击", 3, 2),
		_add_block_action(&"spawn_roe", "抖落鱼卵", _block(&"roe_spawned", "掉落鱼卵", 1, 1, "新掉落的鱼卵。"), 2),
		_charge_action(&"inhale", "鼓腮蓄力", 3, 2),
		_attack_action(&"surge", "腥潮冲撞", 6, 1),
	]
	return enemy

static func _block(
	block_id: StringName,
	display_name: String,
	volume: int,
	digest_time: int,
	description: String,
	digest_effects: Array[BattleEffectData] = []
) -> FoodBlockData:
	var block := FoodBlockData.new()
	block.id = block_id
	block.display_name = display_name
	block.volume = volume
	block.digest_time = digest_time
	block.description = description
	block.digest_effects = digest_effects
	return block

static func _step(id: StringName, display_name: String, action: BattleTypes.PurificationActionType) -> PurificationStepData:
	var step := PurificationStepData.new()
	step.id = id
	step.display_name = display_name
	step.required_action = action
	return step

static func _attack_action(id: StringName, display_name: String, amount: int, time_delay: int) -> EnemyActionData:
	var action := EnemyActionData.new()
	action.id = id
	action.display_name = display_name
	action.action_type = BattleTypes.EnemyActionType.ATTACK
	action.amount = amount
	action.time_delay = time_delay
	return action

static func _add_block_action(id: StringName, display_name: String, block_definition: FoodBlockData, time_delay: int) -> EnemyActionData:
	var action := EnemyActionData.new()
	action.id = id
	action.display_name = display_name
	action.action_type = BattleTypes.EnemyActionType.ADD_BLOCK
	action.time_delay = time_delay
	action.payload = {"block_definition": block_definition}
	return action

static func _charge_action(id: StringName, display_name: String, amount: int, time_delay: int) -> EnemyActionData:
	var action := EnemyActionData.new()
	action.id = id
	action.display_name = display_name
	action.action_type = BattleTypes.EnemyActionType.CHARGE_ATTACK
	action.amount = amount
	action.time_delay = time_delay
	return action

static func _corrupt_action(id: StringName, display_name: String, amount: int, time_delay: int) -> EnemyActionData:
	var action := EnemyActionData.new()
	action.id = id
	action.display_name = display_name
	action.action_type = BattleTypes.EnemyActionType.CORRUPT_BLOCK
	action.amount = amount
	action.time_delay = time_delay
	return action

static func _effect(kind: BattleTypes.EffectKind, amount: int = 0) -> BattleEffectData:
	var effect := BattleEffectData.new()
	effect.kind = kind
	effect.amount = amount
	return effect
