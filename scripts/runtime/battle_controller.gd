extends Node
class_name BattleController

signal state_changed(state: BattleState)
signal log_added(message: String)
signal battle_finished(outcome: BattleTypes.BattleOutcome)

var state: BattleState
var _known_log_count: int = 0

func start_battle(definition: BattleDefinition) -> void:
	state = BattleRules.create_state(definition)
	_known_log_count = 0
	_flush_logs()
	state_changed.emit(state)
	_check_finished()

func play_card(hand_index: int) -> bool:
	if state == null:
		return false
	var played: bool = BattleRules.play_card(state, hand_index)
	_refresh()
	return played

func _refresh() -> void:
	_flush_logs()
	state_changed.emit(state)
	_check_finished()

func _flush_logs() -> void:
	if state == null:
		return
	while _known_log_count < state.log_entries.size():
		log_added.emit(state.log_entries[_known_log_count])
		_known_log_count += 1

func _check_finished() -> void:
	if state == null:
		return
	if state.is_finished():
		battle_finished.emit(state.outcome)
