extends RefCounted
class_name CardCatalog

static func build_card_entries() -> Array[CardPileEntryData]:
	var entries: Array[CardPileEntryData] = []
	for card in _load_cards_from_csv():
		_apply_effects(card)
		entries.append(_entry(card, 1))
	return entries

static func build_card_map() -> Dictionary:
	var map: Dictionary = {}
	for card in _load_cards_from_csv():
		_apply_effects(card)
		map[card.id] = card
		map[card.display_name] = card
	return map

static func get_card_definition(card_id: StringName) -> CardData:
	return build_card_map().get(card_id, null)

static func _load_cards_from_csv(csv_path: String = "res://data/cards.csv") -> Array[CardData]:
	var cards: Array[CardData] = []
	var csv_text: String = FileAccess.get_file_as_string(csv_path)
	if csv_text.is_empty():
		return cards
	for line in csv_text.split("\n", false):
		var trimmed: String = line.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("类型,"):
			continue
		var columns: PackedStringArray = trimmed.split(",", false)
		if columns.size() < 4:
			continue
		var card: CardData = CardData.new()
		card.id = StringName(_slugify(columns[1].strip_edges()))
		card.display_name = columns[1].strip_edges()
		card.time_cost = max(0, columns[2].strip_edges().to_int())
		card.card_type = _parse_type(columns[0].strip_edges())
		card.description = columns[3].strip_edges()
		card.art_label = card.display_name.substr(0, 1) if not card.display_name.is_empty() else ""
		cards.append(card)
	return cards

static func _apply_effects(card: CardData) -> void:
	var effects: Array[BattleEffectData] = []
	match card.display_name:
		"咬一口":
			effects = [_effect(BattleTypes.EffectKind.EAT_ENEMY_BLOCK, 1)]
		"咬一大口":
			effects = [_effect(BattleTypes.EffectKind.EAT_ENEMY_BLOCK, 2)]
		"囫囵吞枣":
			effects = [_effect(BattleTypes.EffectKind.EAT_ENEMY_BLOCK, 2), _effect(BattleTypes.EffectKind.DISCARD_RANDOM_CARDS, 1)]
		"血盆大口":
			effects = [_effect(BattleTypes.EffectKind.EAT_ENEMY_BLOCK, 4)]
		"护食":
			effects = [_effect(BattleTypes.EffectKind.EAT_ENEMY_BLOCK, 1), _effect(BattleTypes.EffectKind.GAIN_BLOCK, 2)]
		"防御":
			effects = [_effect(BattleTypes.EffectKind.GAIN_BLOCK, 1)]
		"不坏":
			effects = [_effect(BattleTypes.EffectKind.GAIN_BLOCK, 3)]
		"舍身防御":
			effects = [_effect(BattleTypes.EffectKind.GAIN_BLOCK, 3), _effect(BattleTypes.EffectKind.DISCARD_RANDOM_CARDS, 1)]
		"清洗":
			effects = [_effect(BattleTypes.EffectKind.ADVANCE_PURIFICATION, 0, BattleTypes.PurificationActionType.WASH)]
		"剔除":
			effects = [_effect(BattleTypes.EffectKind.ADVANCE_PURIFICATION, 0, BattleTypes.PurificationActionType.TRIM)]
		"矫正":
			effects = [_effect(BattleTypes.EffectKind.ADVANCE_PURIFICATION, 0, BattleTypes.PurificationActionType.CORRECT)]
		"除虫":
			effects = [_effect(BattleTypes.EffectKind.ADVANCE_PURIFICATION, 0, BattleTypes.PurificationActionType.DEWORM)]
		"涤荡":
			effects = [_effect(BattleTypes.EffectKind.ADVANCE_PURIFICATION, 0, BattleTypes.PurificationActionType.PURGE)]
		"智慧":
			effects = [_effect(BattleTypes.EffectKind.DRAW_CARDS, 3), _effect(BattleTypes.EffectKind.DISCARD_RANDOM_CARDS, 3)]
		"加速":
			effects = [_effect(BattleTypes.EffectKind.DRAW_CARDS, 1)]
		"快速消化":
			effects = [_effect(BattleTypes.EffectKind.DIGEST_LAST_STOMACH_ITEM, 1)]
		"健胃消食":
			effects = [_effect(BattleTypes.EffectKind.DIGEST_ALL_STOMACH_ITEMS, 1)]
		"拖延":
			effects = [_effect(BattleTypes.EffectKind.DELAY_ENEMY_NEXT_ACTION, 3)]
		"敏捷":
			effects = [_effect(BattleTypes.EffectKind.DELAY_ENEMY_ALL_ACTIONS, 1)]
		"扩容":
			effects = [_effect(BattleTypes.EffectKind.GAIN_STOMACH_CAPACITY, 1)]
		"肠胃翻腾":
			effects = [_effect(BattleTypes.EffectKind.MOVE_STOMACH_FRONT_TO_BACK, 1)]
		"插队消化":
			effects = [_effect(BattleTypes.EffectKind.MOVE_STOMACH_BACK_TO_FRONT, 1)]
		_:
			effects = []
	card.effects = effects

static func _effect(kind: BattleTypes.EffectKind, amount: int = 0, purification_action: BattleTypes.PurificationActionType = BattleTypes.PurificationActionType.NONE) -> BattleEffectData:
	var effect: BattleEffectData = BattleEffectData.new()
	effect.kind = kind
	effect.amount = amount
	effect.purification_action = purification_action
	return effect

static func _entry(card: CardData, quantity: int) -> CardPileEntryData:
	var entry: CardPileEntryData = CardPileEntryData.new()
	entry.card = card
	entry.quantity = quantity
	return entry

static func _parse_type(type_text: String) -> BattleTypes.CardType:
	match type_text:
		"攻击":
			return BattleTypes.CardType.ATTACK
		"技能":
			return BattleTypes.CardType.SKILL
		"净化":
			return BattleTypes.CardType.PURIFY
		_:
			return BattleTypes.CardType.NONE

static func _slugify(text: String) -> String:
	var result: String = text.strip_edges().to_lower()
	result = result.replace(" ", "_")
	result = result.replace("，", "_")
	result = result.replace("。", "_")
	return result
