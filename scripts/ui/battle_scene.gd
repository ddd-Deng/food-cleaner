extends Control
class_name BattleScene

@onready var controller: BattleController = $BattleController
@onready var player_hp_bar: ProgressBar = $Root/Layout/HeaderRow/PlayerHpPanel/PlayerHpBar
@onready var player_hp_overlay: Label = $Root/Layout/HeaderRow/PlayerHpPanel/PlayerHpLabel
@onready var player_block_label: Label = $Root/Layout/MainRow/LeftColumn/PlayerPanel/PlayerPanelInner/BlockValue
@onready var player_item_row: HBoxContainer = $Root/Layout/MainRow/LeftColumn/PlayerPanel/PlayerPanelInner/ItemRow
@onready var stomach_row: HBoxContainer = $Root/Layout/MainRow/LeftColumn/PlayerPanel/PlayerPanelInner/StomachRow
@onready var draw_pile_label: Label = $Root/Layout/BottomRow/DeckColumn/DeckPanel/DeckPanelInner/DrawValue
@onready var stomach_capacity_label: Label = $Root/Layout/BottomRow/DeckColumn/DeckPanel/DeckPanelInner/CapacityValue
@onready var discard_pile_label: Label = $Root/Layout/BottomRow/DiscardColumn/DiscardPanel/DiscardPanelInner/DiscardValue
@onready var task_value_label: Label = $Root/Layout/MainRow/CentreColumn/TaskPanel/TaskPanelInner/TaskValue
@onready var progress_value_label: Label = $Root/Layout/MainRow/CentreColumn/TaskPanel/TaskPanelInner/ProgressValue
@onready var task_list_label: RichTextLabel = $Root/Layout/MainRow/CentreColumn/TaskPanel/TaskPanelInner/TaskListValue
@onready var intent_value_label: Label = $Root/Layout/MainRow/CentreColumn/TaskPanel/TaskPanelInner/IntentValue
@onready var timeline_value_label: Label = $Root/Layout/MainRow/CentreColumn/TimeLogPanel/TimeLogInner/TimelineValue
@onready var enemy_name_label: Label = $Root/Layout/MainRow/RightColumn/EnemyPanel/EnemyPanelInner/EnemyName
@onready var enemy_status_label: Label = $Root/Layout/MainRow/RightColumn/EnemyPanel/EnemyPanelInner/EnemyStatusValue
@onready var enemy_block_row: VBoxContainer = $Root/Layout/MainRow/RightColumn/EnemyPanel/EnemyPanelInner/BlockRow
@onready var hand_view: HandView = $Root/Layout/BottomRow/BottomCenter/HandCenter/HandView
@onready var timeline_strip: HBoxContainer = $Root/Layout/BottomRow/BottomCenter/TimelineCenter/TimelineScroll/TimelineStrip
@onready var effect_banner_label: Label = $Root/Layout/MainRow/CentreColumn/TimeLogPanel/TimeLogInner/EffectBanner/EffectBannerInner/EffectBannerLabel
@onready var log_text: RichTextLabel = $Root/Layout/MainRow/CentreColumn/TimeLogPanel/TimeLogInner/LogScroll/LogText
@onready var settings_button: Button = $Root/Layout/HeaderRow/RightButtons/SettingsButton
@onready var deck_preview_button: Button = $Root/Layout/HeaderRow/RightButtons/DeckPreviewButton

var _last_effect_sequence_seen: int = -1
var _last_player_hp_seen: int = -1
var _last_enemy_block_count_seen: int = -1
var _last_purification_index_seen: int = -1

func _ready() -> void:
	controller.state_changed.connect(_on_state_changed)
	controller.log_added.connect(_on_log_added)
	controller.battle_finished.connect(_on_battle_finished)
	settings_button.pressed.connect(_on_settings_pressed)
	deck_preview_button.pressed.connect(_on_deck_preview_pressed)
	hand_view.card_released_outside_hand.connect(_on_card_released_outside_hand)
	hand_view.drag_cancelled.connect(_on_drag_cancelled)
	controller.start_battle(SampleBattleFactory.create_demo_battle_definition())

func _input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_RIGHT or not mouse_event.pressed:
		return
	if hand_view.cancel_active_drag():
		get_viewport().set_input_as_handled()

func _on_state_changed(state: BattleState) -> void:
	_flash_state_changes(state)
	player_hp_bar.max_value = maxf(1.0, float(state.player_max_hp))
	player_hp_bar.value = float(state.player_hp)
	player_hp_overlay.text = "HP %d / %d" % [state.player_hp, state.player_max_hp]
	player_block_label.text = "防御：%d" % state.player_block
	_refresh_player_items(state)
	_rebuild_stomach(state)
	draw_pile_label.text = "抽牌堆：%d" % state.draw_pile.size()
	stomach_capacity_label.text = "胃容量：%d / %d" % [state.get_stomach_used(), state.player_max_stomach_volume + state.player_extra_stomach_capacity]
	discard_pile_label.text = "弃牌堆：%d" % state.discard_pile.size()
	task_value_label.text = _task_text(state)
	progress_value_label.text = _progress_text(state)
	task_list_label.text = _task_list_text(state)
	intent_value_label.text = "意图：%s" % state.player_current_intent
	timeline_value_label.text = "战斗时间：%dt" % state.battle_time
	enemy_name_label.text = _enemy_name(state)
	enemy_status_label.text = "净化：%d / %d" % [state.get_purification_completed(), state.get_purification_total()]
	_rebuild_enemy_blocks(state)
	_rebuild_hand(state)
	_rebuild_timeline(state)
	_refresh_effect_banner(state)
func _on_log_added(message: String) -> void:
	if not log_text.text.is_empty():
		log_text.append_text("\n")
	log_text.append_text(message)
	log_text.scroll_to_line(log_text.get_line_count())

func _on_battle_finished(outcome: BattleTypes.BattleOutcome) -> void:
	log_text.append_text("\n战斗结束：%s" % _outcome_text(outcome))
	log_text.scroll_to_line(log_text.get_line_count())

func _on_settings_pressed() -> void:
	log_text.append_text("\n设置界面占位。")
	log_text.scroll_to_line(log_text.get_line_count())

func _on_deck_preview_pressed() -> void:
	log_text.append_text("\n牌库预览：")
	var seen_ids: Dictionary = {}
	for card in CardCatalog.build_card_map().values():
		if card is CardData:
			var data: CardData = card
			if seen_ids.has(data.id):
				continue
			seen_ids[data.id] = true
			log_text.append_text("\n- %s | %dt | %s" % [data.display_name, data.time_cost, data.description])
	log_text.scroll_to_line(log_text.get_line_count())

func _refresh_player_items(state: BattleState) -> void:
	for child in player_item_row.get_children():
		child.queue_free()
	if state.player_items.is_empty():
		var placeholder: Label = Label.new()
		placeholder.text = "暂无道具"
		player_item_row.add_child(placeholder)
		return
	for item in state.player_items:
		var label: Label = Label.new()
		label.text = item.get_display_name()
		label.custom_minimum_size = Vector2(140, 36)
		player_item_row.add_child(label)

func _rebuild_enemy_blocks(state: BattleState) -> void:
	for child in enemy_block_row.get_children():
		if child.name != "BlockTitle":
			child.queue_free()
	if state.enemy == null or state.enemy.blocks.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "暂无食物块"
		enemy_block_row.add_child(empty_label)
		return
	for index in range(state.enemy.blocks.size()):
		var block: FoodBlockInstance = state.enemy.blocks[index]
		var label: Label = Label.new()
		label.text = "%d. %s" % [index + 1, block.get_display_name()]
		enemy_block_row.add_child(label)

func _rebuild_stomach(state: BattleState) -> void:
	for child in stomach_row.get_children():
		child.queue_free()
	if state.stomach.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "胃：空"
		stomach_row.add_child(empty_label)
		return
	for index in range(state.stomach.size()):
		var item: FoodBlockInstance = state.stomach[index]
		var label: Label = Label.new()
		label.text = "%d. %s(%d)" % [index + 1, item.get_display_name(), item.remaining_digest_time]
		stomach_row.add_child(label)

func _rebuild_hand(state: BattleState) -> void:
	hand_view.rebuild_hand(state.hand, not state.is_finished())

func _rebuild_timeline(state: BattleState) -> void:
	for child in timeline_strip.get_children():
		child.queue_free()
	for entry in state.timeline_entries:
		var label: Label = Label.new()
		label.text = entry
		label.custom_minimum_size = Vector2(48, 24)
		timeline_strip.add_child(label)

func _on_card_released_outside_hand(index: int) -> void:
	_play_card_from_hand(index)

func _on_drag_cancelled() -> void:
	hand_view.set_drop_hover(false)

func _play_card_from_hand(index: int) -> void:
	if index < 0:
		return
	if not controller.play_card(index):
		hand_view.rebuild_hand(controller.state.hand, not controller.state.is_finished())

func _task_text(state: BattleState) -> String:
	if state.enemy == null or state.enemy.definition == null:
		return "当前步骤：-"
	var step: PurificationStepData = state.enemy.current_step()
	if step == null:
		return "当前步骤：已完成"
	return "当前步骤：%s" % step.display_name

func _task_list_text(state: BattleState) -> String:
	if state.enemy == null or state.enemy.definition == null or state.enemy.definition.purification_steps.is_empty():
		return "任务：-"
	var lines: Array[String] = ["任务："]
	for i in range(state.enemy.definition.purification_steps.size()):
		var step: PurificationStepData = state.enemy.definition.purification_steps[i]
		var done: bool = state.enemy.purification_completed[i]
		lines.append("[%s] %s" % ["x" if done else " ", step.display_name])
	return "\n".join(lines)

func _progress_text(state: BattleState) -> String:
	if state.enemy == null or state.enemy.definition == null:
		return "进度：-"
	return "进度：%d / %d" % [state.enemy.purification_index, state.enemy.definition.purification_steps.size()]

func _enemy_name(state: BattleState) -> String:
	if state.enemy == null or state.enemy.definition == null:
		return "敌人"
	return state.enemy.definition.display_name

func _outcome_text(outcome: BattleTypes.BattleOutcome) -> String:
	match outcome:
		BattleTypes.BattleOutcome.VICTORY_CLEARED:
			return "已清除"
		BattleTypes.BattleOutcome.VICTORY_PURIFIED:
			return "已净化"
		BattleTypes.BattleOutcome.DEFEAT:
			return "失败"
		_:
			return "进行中"

func _refresh_effect_banner(state: BattleState) -> void:
	if state.last_played_sequence == _last_effect_sequence_seen:
		return
	_last_effect_sequence_seen = state.last_played_sequence
	if state.last_played_sequence <= 0:
		effect_banner_label.text = "拖出手牌区后松手即可打出，右键可立即取消。"
		return
	effect_banner_label.text = "打出 %s | 消耗 %dt | %s" % [
		state.last_played_card_name,
		state.last_played_card_time_cost,
		state.last_played_effect_summary,
	]
	_flash_control(effect_banner_label, Color(1.0, 0.94, 0.70, 1.0))

func _flash_state_changes(state: BattleState) -> void:
	if _last_player_hp_seen >= 0 and _last_player_hp_seen != state.player_hp:
		var hp_color := Color(1.0, 0.68, 0.68, 1.0) if state.player_hp < _last_player_hp_seen else Color(0.72, 1.0, 0.72, 1.0)
		_flash_control(player_hp_bar, hp_color)
	_last_player_hp_seen = state.player_hp

	var enemy_block_count: int = state.enemy.blocks.size() if state.enemy != null else 0
	if _last_enemy_block_count_seen >= 0 and _last_enemy_block_count_seen != enemy_block_count:
		var block_color := Color(0.72, 1.0, 0.72, 1.0) if enemy_block_count < _last_enemy_block_count_seen else Color(1.0, 0.92, 0.66, 1.0)
		_flash_control(enemy_block_row, block_color)
	_last_enemy_block_count_seen = enemy_block_count

	var purification_index: int = state.enemy.purification_index if state.enemy != null else 0
	if _last_purification_index_seen >= 0 and _last_purification_index_seen != purification_index:
		_flash_control(progress_value_label, Color(0.78, 0.92, 1.0, 1.0))
	_last_purification_index_seen = purification_index

func _flash_control(control: CanvasItem, flash_color: Color) -> void:
	control.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(control, "modulate", Color.WHITE, 0.24)
