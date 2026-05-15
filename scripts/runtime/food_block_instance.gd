extends RefCounted
class_name FoodBlockInstance

const CORRUPTED_TAG: StringName = &"corrupted"
const BAD_STATE_TAGS := [
	&"corrupted",
	&"spoiled",
	&"rotten",
	&"sour",
	&"dirty",
]

var definition: FoodBlockData
var volume: int = 1
var remaining_digest_time: int = 1
var tags: Array[StringName] = []
var is_corrupted: bool = false
var extra_digest_damage: int = 0

static func from_definition(block_definition: FoodBlockData) -> FoodBlockInstance:
	var instance: FoodBlockInstance = FoodBlockInstance.new()
	instance.definition = block_definition
	if block_definition != null:
		instance.volume = block_definition.volume
		instance.remaining_digest_time = max(1, block_definition.digest_time)
		instance.tags = block_definition.tags.duplicate()
	return instance

func get_display_name() -> String:
	var base_name := definition.display_name if definition != null else "Food Block"
	if is_corrupted and not base_name.begins_with("变质"):
		return "变质" + base_name
	return base_name

func can_be_corrupted() -> bool:
	return not is_bad_block()

func is_bad_block() -> bool:
	if is_corrupted:
		return true
	for tag in tags:
		if BAD_STATE_TAGS.has(tag):
			return true
	return _has_harmful_digest_effects()

func corrupt() -> bool:
	if not can_be_corrupted():
		return false
	is_corrupted = true
	if not tags.has(CORRUPTED_TAG):
		tags.append(CORRUPTED_TAG)
	remaining_digest_time = max(remaining_digest_time + 1, 2)
	extra_digest_damage += 1
	return true

func get_digest_effects() -> Array[BattleEffectData]:
	var effects: Array[BattleEffectData] = []
	if definition != null:
		for effect in definition.digest_effects:
			if effect != null:
				effects.append(effect)
	if extra_digest_damage > 0:
		var damage_effect := BattleEffectData.new()
		damage_effect.kind = BattleTypes.EffectKind.DEAL_PLAYER_DAMAGE
		damage_effect.amount = extra_digest_damage
		damage_effect.description = "变质反噬 %d 点伤害" % extra_digest_damage
		effects.append(damage_effect)
	return effects

func _has_harmful_digest_effects() -> bool:
	if definition == null:
		return false
	for effect in definition.digest_effects:
		if effect == null:
			continue
		if effect.kind == BattleTypes.EffectKind.DEAL_PLAYER_DAMAGE and effect.amount > 0:
			return true
	return false
