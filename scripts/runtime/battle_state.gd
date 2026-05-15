extends RefCounted
class_name BattleState

var definition: BattleDefinition
var phase: BattleTypes.BattlePhase = BattleTypes.BattlePhase.SETUP
var outcome: BattleTypes.BattleOutcome = BattleTypes.BattleOutcome.ONGOING
var battle_time: int = 0
var player_hp: int = 20
var player_max_hp: int = 20
var player_block: int = 0
var player_gold: int = 0
var player_max_hand_size: int = 8
var player_starting_hand_size: int = 4
var player_max_stomach_volume: int = 6
var player_extra_stomach_capacity: int = 0
var player_current_intent: String = "等待中"
var player_items: Array[PlayerItemInstance] = []
var draw_pile: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var exhaust_pile: Array[CardInstance] = []
var stomach: Array[FoodBlockInstance] = []
var enemy: EnemyRuntime
var timeline_entries: Array[String] = []
var card_effect_records: Array[CardEffectRecord] = []
var last_played_card_name: String = ""
var last_played_card_time_cost: int = 0
var last_played_effect_summary: String = ""
var last_played_sequence: int = 0
var last_enemy_action_name: String = ""
var log_entries: Array[String] = []

func is_finished() -> bool:
	return outcome != BattleTypes.BattleOutcome.ONGOING

func get_stomach_used() -> int:
	var total := 0
	for item in stomach:
		total += item.volume
	return total

func get_stomach_capacity_left() -> int:
	return max(0, player_max_stomach_volume + player_extra_stomach_capacity - get_stomach_used())

func get_purification_total() -> int:
	if enemy == null or enemy.definition == null:
		return 0
	return enemy.definition.purification_steps.size()

func get_purification_completed() -> int:
	if enemy == null:
		return 0
	return enemy.purification_index

func add_log(message: String) -> void:
	log_entries.append("[%dt] %s" % [battle_time, message])

func set_timeline(entries: Array[String]) -> void:
	timeline_entries = entries.duplicate()

func add_card_effect_record(record: CardEffectRecord) -> void:
	if record == null:
		return
	card_effect_records.append(record)

func get_card_effect_records_at_time(time_point: int) -> Array[CardEffectRecord]:
	var records: Array[CardEffectRecord] = []
	for record in card_effect_records:
		if record != null and record.time_point == time_point:
			records.append(record)
	return records
