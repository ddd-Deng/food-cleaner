extends Control
class_name BattleScene

signal battle_resolved(result: Dictionary)

@export var start_demo_on_ready: bool = true

@onready var controller: BattleController = $BattleController
@onready var battle_player_sprite: BattlePlayerSprite = $BattlePlayerSprite
@onready var battle_enemy_sprite: BattleEnemySprite = $BattleEnemySprite
@onready var player_hp_bar: Control = $Root/Layout/HeaderRow/PlayerHud/StatusColumn/PlayerHpPanel/PlayerHpBar
@onready var player_hp_fill: NinePatchRect = $Root/Layout/HeaderRow/PlayerHud/StatusColumn/PlayerHpPanel/PlayerHpBar/PlayerHpFill
@onready var player_hp_overlay: Label = $Root/Layout/HeaderRow/PlayerHud/StatusColumn/PlayerHpPanel/PlayerHpLabel
@onready var gold_value_label: Label = $Root/Layout/HeaderRow/PlayerHud/StatusColumn/GoldPanel/GoldValue
@onready var task_strip_panel: Control = $Root/Layout/HeaderRow/TaskStripPanel
@onready var purification_task_row: HBoxContainer = $Root/Layout/HeaderRow/TaskStripPanel/PurificationTaskRow
@onready var timeline_value_label: Label = $Root/Layout/MainRow/CentreColumn/TimeLogCenter/TimeLogPanel/TimeLogInner/TimelineValue
@onready var effect_banner_label: Label = $Root/Layout/MainRow/CentreColumn/TimeLogCenter/TimeLogPanel/TimeLogInner/EffectBanner/EffectBannerInner/EffectBannerLabel
@onready var enemy_intent_label: Label = $Root/Layout/MainRow/CentreColumn/TimeLogCenter/TimeLogPanel/TimeLogInner/EnemyIntentLabel
@onready var log_scroll: ScrollContainer = $Root/Layout/MainRow/CentreColumn/TimeLogCenter/TimeLogPanel/TimeLogInner/LogScroll
@onready var log_text: RichTextLabel = $Root/Layout/MainRow/CentreColumn/TimeLogCenter/TimeLogPanel/TimeLogInner/LogScroll/LogText
@onready var draw_pile_label: Label = $Root/Layout/BottomRow/DeckColumn/DeckPanel/DeckPanelInner/DrawValue
@onready var discard_pile_label: Label = $Root/Layout/BottomRow/DiscardColumn/DiscardPanel/DiscardPanelInner/DiscardValue
@onready var player_actor_view: BattleActorView = $Root/Layout/BottomRow/DeckColumn/ActorAnchor/PlayerActorView
@onready var hand_view: HandView = $Root/Layout/BottomRow/BottomCenter/HandCenter/HandView
@onready var timeline_scroll: ScrollContainer = $Root/Layout/BottomRow/BottomCenter/TimelineCenter/TimelineScroll
@onready var timeline_strip: Control = $Root/Layout/BottomRow/BottomCenter/TimelineCenter/TimelineScroll/TimelineStrip
@onready var enemy_actor_view: BattleActorView = $Root/Layout/BottomRow/DiscardColumn/ActorAnchor/EnemyActorView
@onready var player_food_queue: FoodQueueView = $PlayerFoodQueue
@onready var enemy_food_queue: FoodQueueView = $EnemyFoodQueue
@onready var settings_button: BaseButton = $Root/Layout/HeaderRow/RightButtons/SettingsButton
@onready var deck_preview_button: BaseButton = $Root/Layout/HeaderRow/RightButtons/DeckPreviewButton
@onready var draw_pile_button: BaseButton = $Root/Layout/BottomRow/DeckColumn/DeckPanel
@onready var discard_pile_button: BaseButton = $Root/Layout/BottomRow/DiscardColumn/DiscardPanel
const DECK_VIEW_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/deck_view_overlay.tscn")

const TIMELINE_BASE_TEXTURE: Texture2D = preload("res://sprites/时间轴/时间轴.png")
const TIMELINE_MARKER_TEXTURE: Texture2D = preload("res://sprites/时间轴/时间轴上的标记点.png")
const TIMELINE_CURRENT_TEXTURE: Texture2D = preload("res://sprites/时间轴/当前回合标记.png")
const TIMELINE_CARD_EFFECT_TEXTURE: Texture2D = preload("res://sprites/时间轴/卡牌生效卡牌标记.png")
const PURIFICATION_PROGRESS_TEXTURE: Texture2D = preload("res://sprites/净化进度、.png")

const TIMELINE_BASE_REGION := Rect2(252, 666, 839, 52)
const TIMELINE_MARKER_REGIONS := [
	Rect2(831, 681, 25, 34),
	Rect2(965, 680, 26, 36),
]
const TIMELINE_CURRENT_REGION := Rect2(493, 646, 22, 50)
const PURIFICATION_EMPTY_REGION := Rect2(779, 19, 49, 57)
const PURIFICATION_DONE_REGION := Rect2(970, 19, 59, 57)
const PURIFICATION_ICON_SIZE := Vector2(30, 34)
const PURIFICATION_ITEM_LABEL_COLOR := Color(0.18, 0.11, 0.04, 1.0)
const PURIFICATION_DONE_LABEL_COLOR := Color(0.11, 0.18, 0.10, 1.0)
const PURIFICATION_LABEL_OUTLINE_COLOR := Color(1.0, 0.96, 0.87, 0.55)
const TIMELINE_CARD_EFFECT_MARKER_SIZE := Vector2(16, 25)
const TIMELINE_SLOT_WIDTH := 84.0
const TIMELINE_LEFT_PADDING := 22.0
const TIMELINE_TRACK_Y := 30.0
const TIMELINE_ACTION_MARKER_Y := 50.0
const TIMELINE_CARD_EFFECT_MARKER_Y := 4.0
const TIMELINE_CARD_EFFECT_MARKER_X_OFFSET := 18.0
const TIMELINE_CURRENT_Y := 14.0
const TIMELINE_LABEL_Y := 22.0
const TIMELINE_MIN_HEIGHT := 82.0
const TIMELINE_CURRENT_OFFSET_SLOTS := 2
const TIMELINE_END_CAP_PADDING := 64.0

var _last_effect_sequence_seen: int = -1
var _last_player_hp_seen: int = -1
var _last_enemy_block_count_seen: int = -1
var _last_purification_index_seen: int = -1
var _pending_definition: BattleDefinition
var _started_once: bool = false
var _card_effect_preview_popup: CardEffectPreviewPopup
var _deck_view_overlay: DeckViewOverlay

func _ready() -> void:
	player_actor_view.set_actor_mode(BattleActorView.MODE_PLAYER)
	enemy_actor_view.set_actor_mode(BattleActorView.MODE_ENEMY)
	ScrollBarSkin.apply_to_scroll_container(log_scroll)
	ScrollBarSkin.apply_to_rich_text_label(log_text)
	ScrollBarSkin.apply_compact_horizontal_to_scroll_container(timeline_scroll)
	_create_card_effect_preview_popup()
	_create_deck_view_overlay()

	controller.state_changed.connect(_on_state_changed)
	controller.state_changed.connect(func(state: BattleState) -> void:
		if _deck_view_overlay != null and _deck_view_overlay.is_open():
			_deck_view_overlay.refresh_with_state(state)
	)
	controller.log_added.connect(_on_log_added)
	controller.battle_finished.connect(_on_battle_finished)
	settings_button.pressed.connect(_on_settings_pressed)
	deck_preview_button.pressed.connect(func() -> void:
		_open_deck_view(DeckViewOverlay.TAB_ALL)
	)
	draw_pile_button.pressed.connect(func() -> void:
		_open_deck_view(DeckViewOverlay.TAB_DRAW)
	)
	discard_pile_button.pressed.connect(func() -> void:
		_open_deck_view(DeckViewOverlay.TAB_DISCARD)
	)
	_configure_texture_button_feedback(settings_button)
	_configure_texture_button_feedback(deck_preview_button)
	_configure_texture_button_feedback(draw_pile_button)
	_configure_texture_button_feedback(discard_pile_button)
	hand_view.card_released_outside_hand.connect(_on_card_released_outside_hand)
	hand_view.drag_cancelled.connect(_on_drag_cancelled)
	if _pending_definition != null:
		_start_controller_battle(_pending_definition)
	elif start_demo_on_ready:
		_start_controller_battle(SampleBattleFactory.create_demo_battle_definition())

func start_battle(definition: BattleDefinition) -> void:
	_pending_definition = definition
	if is_node_ready():
		_start_controller_battle(definition)

func _input(event: InputEvent) -> void:
	if _deck_view_overlay != null and _deck_view_overlay.is_open():
		return
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_RIGHT or not mouse_event.pressed:
		return
	if hand_view.cancel_active_drag():
		get_viewport().set_input_as_handled()

func _on_state_changed(state: BattleState) -> void:
	_flash_state_changes(state)
	_refresh_player_hp_bar(state.player_hp, state.player_max_hp)
	player_hp_overlay.text = "HP %d / %d" % [state.player_hp, state.player_max_hp]
	player_actor_view.set_player_snapshot(
		state.player_hp,
		state.player_max_hp,
		state.player_block,
		state.get_stomach_used(),
		state.player_max_stomach_volume + state.player_extra_stomach_capacity
	)
	enemy_actor_view.set_enemy_snapshot(
		_enemy_name(state),
		state.player_current_intent,
		state.get_purification_completed(),
		state.get_purification_total(),
		state.enemy.blocks.size() if state.enemy != null else 0
	)
	_refresh_purification_task_row(state)
	gold_value_label.text = str(state.player_gold)
	draw_pile_label.text = "抽牌堆：%d" % state.draw_pile.size()
	discard_pile_label.text = "弃牌堆：%d" % state.discard_pile.size()
	timeline_value_label.text = "战斗时间：%dt" % state.battle_time
	enemy_intent_label.text = "敌人行动：%s" % _enemy_intent_text(state)
	_refresh_food_queues(state)
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
	battle_resolved.emit({
		"outcome": outcome,
		"player_hp": controller.state.player_hp if controller.state != null else 0,
		"player_max_hp": controller.state.player_max_hp if controller.state != null else 0,
	})

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

func _on_draw_pile_pressed() -> void:
	log_text.append_text("\n抽牌堆按钮点击。")
	log_text.scroll_to_line(log_text.get_line_count())

func _on_discard_pile_pressed() -> void:
	log_text.append_text("\n弃牌堆按钮点击。")
	log_text.scroll_to_line(log_text.get_line_count())

func _rebuild_hand(state: BattleState) -> void:
	hand_view.rebuild_hand(state.hand, not state.is_finished())

func _refresh_food_queues(state: BattleState) -> void:
	var stomach_capacity := state.player_max_stomach_volume + state.player_extra_stomach_capacity
	player_food_queue.set_queue(
		"玩家胃袋",
		_build_food_queue_items(state.stomach, true),
		stomach_capacity
	)
	var enemy_count := state.enemy.blocks.size() if state.enemy != null else 0
	enemy_food_queue.set_queue(
		"敌人掉落",
		_build_food_queue_items(state.enemy.blocks if state.enemy != null else [], false),
		max(enemy_count, 3)
	)

func _build_food_queue_items(blocks: Array, include_digest_time: bool) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for block_variant in blocks:
		if block_variant is not FoodBlockInstance:
			continue
		var block := block_variant as FoodBlockInstance
		var meta_parts: PackedStringArray = []
		meta_parts.append("体积 %d" % max(1, block.volume))
		if include_digest_time:
			meta_parts.append("消化 %dt" % max(0, block.remaining_digest_time))
		items.append({
			"name": block.get_display_name(),
			"meta": " | ".join(meta_parts),
		})
	return items

func _refresh_player_hp_bar(current_hp: int, max_hp: int) -> void:
	var safe_max_hp: int = max(1, max_hp)
	var ratio: float = clamp(float(current_hp) / float(safe_max_hp), 0.0, 1.0)
	var bar_width: float = player_hp_bar.size.x
	if bar_width <= 0.0:
		bar_width = player_hp_bar.get_rect().size.x
	player_hp_fill.size.x = round(bar_width * ratio)

func _configure_texture_button_feedback(button: BaseButton) -> void:
	button.pivot_offset = button.custom_minimum_size * 0.5
	button.mouse_entered.connect(func() -> void:
		button.modulate = Color(1.08, 1.08, 1.08, 1.0)
		button.scale = Vector2(1.05, 1.05)
	)
	button.mouse_exited.connect(func() -> void:
		button.modulate = Color.WHITE
		button.scale = Vector2.ONE
	)
	button.button_down.connect(func() -> void:
		button.modulate = Color(0.88, 0.88, 0.88, 1.0)
		button.scale = Vector2(0.96, 0.96)
	)
	button.button_up.connect(func() -> void:
		var is_hovered := button.get_global_rect().has_point(get_global_mouse_position())
		button.modulate = Color(1.08, 1.08, 1.08, 1.0) if is_hovered else Color.WHITE
		button.scale = Vector2(1.05, 1.05) if is_hovered else Vector2.ONE
	)

func _rebuild_timeline(state: BattleState) -> void:
	_hide_card_effect_preview()
	for child in timeline_strip.get_children():
		child.queue_free()
	var entry_count: int = state.timeline_entries.size()
	var timeline_width: float = max(920.0, TIMELINE_LEFT_PADDING * 2.0 + TIMELINE_SLOT_WIDTH * max(1, entry_count - 1) + TIMELINE_END_CAP_PADDING)
	timeline_strip.custom_minimum_size = Vector2(timeline_width, TIMELINE_MIN_HEIGHT)
	timeline_strip.size = timeline_strip.custom_minimum_size

	var base := TextureRect.new()
	var base_texture := AtlasTexture.new()
	base_texture.atlas = TIMELINE_BASE_TEXTURE
	base_texture.region = TIMELINE_BASE_REGION
	base.texture = base_texture
	base.stretch_mode = TextureRect.STRETCH_SCALE
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.position = Vector2(TIMELINE_LEFT_PADDING, TIMELINE_TRACK_Y)
	base.size = Vector2(timeline_width - TIMELINE_LEFT_PADDING * 2.0, TIMELINE_BASE_REGION.size.y)
	timeline_strip.add_child(base)

	var current_marker := TextureRect.new()
	var current_texture := AtlasTexture.new()
	current_texture.atlas = TIMELINE_CURRENT_TEXTURE
	current_texture.region = TIMELINE_CURRENT_REGION
	current_marker.texture = current_texture
	current_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var current_slot_index: int = state.battle_time
	var current_marker_x: float = TIMELINE_LEFT_PADDING + TIMELINE_SLOT_WIDTH * current_slot_index
	current_marker.position = Vector2(current_marker_x - TIMELINE_CURRENT_REGION.size.x * 0.5, TIMELINE_CURRENT_Y)
	current_marker.size = TIMELINE_CURRENT_REGION.size
	timeline_strip.add_child(current_marker)

	for i in range(entry_count):
		var time_point: int = i
		var marker_x: float = TIMELINE_LEFT_PADDING + TIMELINE_SLOT_WIDTH * i
		var card_effect_records := state.get_card_effect_records_at_time(time_point)
		if not card_effect_records.is_empty():
			timeline_strip.add_child(_build_card_effect_marker(card_effect_records, marker_x))
		if _timeline_time_has_action(state, time_point):
			var action_marker := TextureRect.new()
			var action_region: Rect2 = TIMELINE_MARKER_REGIONS[0]
			var action_texture := AtlasTexture.new()
			action_texture.atlas = TIMELINE_MARKER_TEXTURE
			action_texture.region = action_region
			action_marker.texture = action_texture
			action_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			action_marker.position = Vector2(marker_x - action_region.size.x * 0.5, TIMELINE_ACTION_MARKER_Y)
			action_marker.size = action_region.size
			timeline_strip.add_child(action_marker)

		var label := Label.new()
		label.text = state.timeline_entries[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.add_theme_font_size_override("font_size", 12)
		label.custom_minimum_size = Vector2(TIMELINE_SLOT_WIDTH, 28)
		label.position = Vector2(marker_x - TIMELINE_SLOT_WIDTH * 0.5, TIMELINE_LABEL_Y)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		timeline_strip.add_child(label)

	_align_timeline_scroll_to_current_time(state, timeline_width)

func _align_timeline_scroll_to_current_time(state: BattleState, timeline_width: float) -> void:
	var visible_width: float = timeline_scroll.size.x
	if visible_width <= 0.0:
		visible_width = timeline_scroll.get_rect().size.x
	var max_scroll: float = max(0.0, timeline_width - visible_width)
	if max_scroll <= 0.0:
		timeline_scroll.scroll_horizontal = 0
		return
	var target_time: int = max(0, state.battle_time - TIMELINE_CURRENT_OFFSET_SLOTS)
	var target_scroll: float = TIMELINE_LEFT_PADDING + TIMELINE_SLOT_WIDTH * target_time - TIMELINE_SLOT_WIDTH * 0.5
	timeline_scroll.scroll_horizontal = int(clampf(target_scroll, 0.0, max_scroll))

func _timeline_time_has_action(state: BattleState, time_point: int) -> bool:
	return state.enemy != null and not state.enemy.get_action_labels_at_time(time_point).is_empty()

func _build_card_effect_marker(records: Array[CardEffectRecord], marker_x: float) -> CardEffectTimelineMarker:
	var marker := CardEffectTimelineMarker.new()
	var marker_position := Vector2(
		marker_x + TIMELINE_CARD_EFFECT_MARKER_X_OFFSET - TIMELINE_CARD_EFFECT_MARKER_SIZE.x * 0.5,
		TIMELINE_CARD_EFFECT_MARKER_Y
	)
	marker.setup(records, TIMELINE_CARD_EFFECT_TEXTURE, marker_position, TIMELINE_CARD_EFFECT_MARKER_SIZE)
	marker.preview_requested.connect(_show_card_effect_preview)
	marker.preview_dismissed.connect(_hide_card_effect_preview)
	return marker

func _create_card_effect_preview_popup() -> void:
	if _card_effect_preview_popup != null:
		return
	_card_effect_preview_popup = CardEffectPreviewPopup.new()
	add_child(_card_effect_preview_popup)
	_card_effect_preview_popup.z_index = 2000

func _create_deck_view_overlay() -> void:
	if _deck_view_overlay != null:
		return
	_deck_view_overlay = DECK_VIEW_OVERLAY_SCENE.instantiate() as DeckViewOverlay
	if _deck_view_overlay == null:
		return
	add_child(_deck_view_overlay)
	_deck_view_overlay.z_index = 3000

func _show_card_effect_preview(records: Array[CardEffectRecord], marker_global_rect: Rect2) -> void:
	if _card_effect_preview_popup == null:
		return
	_card_effect_preview_popup.show_records(records, marker_global_rect)

func _hide_card_effect_preview() -> void:
	if _card_effect_preview_popup != null:
		_card_effect_preview_popup.hide_preview()

func _open_deck_view(tab_id: StringName) -> void:
	if controller.state == null or _deck_view_overlay == null:
		return
	hand_view.cancel_active_drag()
	_deck_view_overlay.open_with_state(controller.state, tab_id)

func _on_card_released_outside_hand(index: int) -> void:
	_play_card_from_hand(index)

func _on_drag_cancelled() -> void:
	hand_view.set_drop_hover(false)

func _play_card_from_hand(index: int) -> void:
	if index < 0:
		return
	var played_card: CardInstance = null
	if controller.state != null and index < controller.state.hand.size():
		played_card = controller.state.hand[index]
	var played_card_type: BattleTypes.CardType = played_card.get_card_type() if played_card != null else BattleTypes.CardType.NONE
	if not controller.play_card(index):
		hand_view.rebuild_hand(controller.state.hand, not controller.state.is_finished())
		return
	if played_card_type == BattleTypes.CardType.ATTACK and battle_player_sprite != null:
		battle_player_sprite.play_attack_animation()

func _refresh_purification_task_row(state: BattleState) -> void:
	for child in purification_task_row.get_children():
		child.queue_free()

	if state.enemy == null or state.enemy.definition == null or state.enemy.definition.purification_steps.is_empty():
		var empty_panel := PanelContainer.new()
		empty_panel.add_theme_stylebox_override("panel", _build_purification_item_style(false))
		var empty_label := Label.new()
		empty_label.text = "暂无净化任务"
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", PURIFICATION_ITEM_LABEL_COLOR)
		empty_label.add_theme_color_override("font_outline_color", PURIFICATION_LABEL_OUTLINE_COLOR)
		empty_label.add_theme_constant_override("outline_size", 1)
		empty_panel.add_child(empty_label)
		purification_task_row.add_child(empty_panel)
		return

	for i in range(state.enemy.definition.purification_steps.size()):
		var step: PurificationStepData = state.enemy.definition.purification_steps[i]
		var done: bool = state.enemy.purification_completed[i]
		purification_task_row.add_child(_build_purification_task_item(step.display_name, done))

func _build_purification_task_item(step_name: String, done: bool) -> PanelContainer:
	var item_panel := PanelContainer.new()
	item_panel.add_theme_stylebox_override("panel", _build_purification_item_style(done))

	var item_row := HBoxContainer.new()
	item_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item_row.add_theme_constant_override("separation", 8)
	item_panel.add_child(item_row)

	var label := Label.new()
	label.text = step_name
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", PURIFICATION_DONE_LABEL_COLOR if done else PURIFICATION_ITEM_LABEL_COLOR)
	label.add_theme_color_override("font_outline_color", PURIFICATION_LABEL_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 1)
	item_row.add_child(label)

	var icon := TextureRect.new()
	icon.custom_minimum_size = PURIFICATION_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _build_purification_icon_texture(done)
	item_row.add_child(icon)

	return item_panel

func _build_purification_item_style(done: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if done:
		style.bg_color = Color(0.79, 0.88, 0.72, 0.92)
		style.border_color = Color(0.3, 0.45, 0.26, 0.8)
	else:
		style.bg_color = Color(0.95, 0.88, 0.70, 0.92)
		style.border_color = Color(0.56, 0.42, 0.23, 0.72)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 12.0
	style.content_margin_top = 6.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 6.0
	return style

func _build_purification_icon_texture(done: bool) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = PURIFICATION_PROGRESS_TEXTURE
	texture.region = PURIFICATION_DONE_REGION if done else PURIFICATION_EMPTY_REGION
	return texture

func _enemy_name(state: BattleState) -> String:
	if state.enemy == null or state.enemy.definition == null:
		return "敌人"
	return state.enemy.definition.display_name

func _enemy_intent_text(state: BattleState) -> String:
	if state == null or state.enemy == null:
		return "暂无"
	if state.player_current_intent.is_empty():
		return "等待"
	return state.player_current_intent

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
		_flash_control(enemy_actor_view, block_color)
	_last_enemy_block_count_seen = enemy_block_count

	var purification_index: int = state.enemy.purification_index if state.enemy != null else 0
	if _last_purification_index_seen >= 0 and _last_purification_index_seen != purification_index:
		_flash_control(task_strip_panel, Color(0.78, 0.92, 1.0, 1.0))
	_last_purification_index_seen = purification_index

func _flash_control(control: CanvasItem, flash_color: Color) -> void:
	control.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(control, "modulate", Color.WHITE, 0.24)

func _start_controller_battle(definition: BattleDefinition) -> void:
	if definition == null:
		return
	_pending_definition = definition
	if battle_enemy_sprite != null:
		battle_enemy_sprite.setup_from_monster(definition.monster_id)
	if _started_once:
		log_text.clear()
		_last_effect_sequence_seen = -1
		_last_player_hp_seen = -1
		_last_enemy_block_count_seen = -1
		_last_purification_index_seen = -1
	_started_once = true
	controller.start_battle(definition)
