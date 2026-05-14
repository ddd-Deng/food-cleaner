extends RefCounted
class_name CardEffectRecord

var time_point: int = 0
var card_id: StringName = &""
var card_name: String = ""
var card_type: BattleTypes.CardType = BattleTypes.CardType.NONE
var time_cost: int = 0
var effect_summary: String = ""
var sequence: int = 0

static func from_card(
	card: CardInstance,
	new_time_point: int,
	new_effect_summary: String,
	new_sequence: int
) -> CardEffectRecord:
	var record := CardEffectRecord.new()
	record.time_point = max(0, new_time_point)
	record.time_cost = max(0, card.get_time_cost()) if card != null else 0
	record.effect_summary = new_effect_summary
	record.sequence = max(0, new_sequence)
	if card != null:
		record.card_name = card.get_display_name()
		record.card_type = card.get_card_type()
		if card.definition != null:
			record.card_id = card.definition.id
	return record

