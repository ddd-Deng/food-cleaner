extends Control
class_name DeckViewOverlay

const DECK_CARD_TILE_SCENE: PackedScene = preload("res://scenes/ui/deck_card_tile.tscn")
const LARGE_FRAME_TEXTURE: Texture2D = preload("res://sprites/大框.png")
const MEDIUM_FRAME_TEXTURE: Texture2D = preload("res://sprites/中框.png")
const SMALL_FRAME_TEXTURE: Texture2D = preload("res://sprites/小框.png")
const BACK_BUTTON_TEXTURE: Texture2D = preload("res://sprites/返回.png")
const TAB_IDLE_TEXTURE: Texture2D = preload("res://sprites/分类框/平常分类.png")
const TAB_ACTIVE_TEXTURE: Texture2D = preload("res://sprites/分类框/选中分类.png")

const LARGE_FRAME_REGION := Rect2(38, 33, 1199, 656)
const MEDIUM_FRAME_REGION := Rect2(62, 189, 1152, 480)
const SMALL_FRAME_REGION := Rect2(81, 208, 1088, 302)
const BACK_BUTTON_REGION := Rect2(1093, 56, 119, 72)
const TAB_IDLE_REGION := Rect2(225, 138, 156, 45)
const TAB_ACTIVE_REGION := Rect2(64, 137, 154, 45)

const LARGE_FRAME_SLICE := 28.0
const MEDIUM_FRAME_SLICE := 24.0
const SMALL_FRAME_SLICE := 20.0
const BACK_BUTTON_SLICE := 14.0
const TAB_SLICE := 14.0

const TAB_ALL: StringName = &"all"
const TAB_DRAW: StringName = &"draw"
const TAB_DISCARD: StringName = &"discard"
const TAB_ORDER: Array[StringName] = [TAB_ALL, TAB_DRAW, TAB_DISCARD]
const TYPE_ORDER: Array[BattleTypes.CardType] = [
	BattleTypes.CardType.ATTACK,
	BattleTypes.CardType.SKILL,
	BattleTypes.CardType.PURIFY,
	BattleTypes.CardType.NONE,
]
const TILE_WIDTH := 168.0
const GRID_SEPARATION := 14.0
const OPEN_LAYOUT_MAX_RETRIES := 8

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $SafeArea/Panel
@onready var title_label: Label = $SafeArea/Panel/PanelMargin/PanelColumn/HeaderRow/HeaderText/TitleLabel
@onready var summary_label: Label = $SafeArea/Panel/PanelMargin/PanelColumn/HeaderRow/HeaderText/SummaryLabel
@onready var close_button: Button = $SafeArea/Panel/PanelMargin/PanelColumn/HeaderRow/CloseButton
@onready var all_tab_button: Button = $SafeArea/Panel/PanelMargin/PanelColumn/TabRow/AllTabButton
@onready var draw_tab_button: Button = $SafeArea/Panel/PanelMargin/PanelColumn/TabRow/DrawTabButton
@onready var discard_tab_button: Button = $SafeArea/Panel/PanelMargin/PanelColumn/TabRow/DiscardTabButton
@onready var content_panel: PanelContainer = $SafeArea/Panel/PanelMargin/PanelColumn/ContentPanel
@onready var content_scroll: ScrollContainer = $SafeArea/Panel/PanelMargin/PanelColumn/ContentPanel/ContentMargin/ContentScroll
@onready var content_column: VBoxContainer = $SafeArea/Panel/PanelMargin/PanelColumn/ContentPanel/ContentMargin/ContentScroll/ContentColumn

var _state: BattleState
var _current_tab: StringName = TAB_ALL
var _tab_buttons: Dictionary = {}
var _pending_rebuild_after_open: bool = false
var _open_layout_retry_count: int = 0
var _open_layout_rebuild_queued: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tab_buttons = {
		TAB_ALL: all_tab_button,
		TAB_DRAW: draw_tab_button,
		TAB_DISCARD: discard_tab_button,
	}
	close_button.pressed.connect(close)
	all_tab_button.pressed.connect(func() -> void: _switch_tab(TAB_ALL))
	draw_tab_button.pressed.connect(func() -> void: _switch_tab(TAB_DRAW))
	discard_tab_button.pressed.connect(func() -> void: _switch_tab(TAB_DISCARD))
	ScrollBarSkin.apply_to_scroll_container(content_scroll)
	resized.connect(_on_overlay_resized)
	content_scroll.resized.connect(_on_content_area_resized)
	content_panel.resized.connect(_on_content_area_resized)
	_apply_shell_styles()
	_rebuild_tabs()
	_rebuild_content()

func open_with_state(state: BattleState, initial_tab: StringName) -> void:
	_state = state
	_current_tab = initial_tab if TAB_ORDER.has(initial_tab) else TAB_ALL
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild_tabs()
	_request_open_layout_rebuild(true)
	call_deferred("_focus_close_button")

func refresh_with_state(state: BattleState) -> void:
	_state = state
	if visible:
		_rebuild_content()

func close() -> void:
	visible = false
	_pending_rebuild_after_open = false
	_open_layout_retry_count = 0
	_open_layout_rebuild_queued = false

func is_open() -> bool:
	return visible

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

func _switch_tab(tab_id: StringName) -> void:
	if _current_tab == tab_id:
		return
	_current_tab = tab_id
	_rebuild_tabs()
	if _pending_rebuild_after_open:
		_request_open_layout_rebuild()
	else:
		_rebuild_content()

func _rebuild_tabs() -> void:
	for tab_id in TAB_ORDER:
		var button := _tab_buttons.get(tab_id, null) as Button
		if button == null:
			continue
		_apply_tab_style(button, tab_id == _current_tab)

func _rebuild_content() -> void:
	for child in content_column.get_children():
		child.queue_free()

	var cards := _cards_for_tab(_state, _current_tab)
	var grouped_entries := _build_grouped_entries(cards)
	title_label.text = _title_for_tab(_current_tab)
	summary_label.text = "共 %d 张，%d 种" % [_count_cards(grouped_entries), _count_distinct_cards(grouped_entries)]

	if grouped_entries.is_empty():
		content_column.add_child(_build_empty_state())
		return

	for group_data in grouped_entries:
		content_column.add_child(_build_group_section(group_data))

func _cards_for_tab(state: BattleState, tab_id: StringName) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	if state == null:
		return cards
	match tab_id:
		TAB_DRAW:
			cards.append_array(state.draw_pile)
		TAB_DISCARD:
			cards.append_array(state.discard_pile)
		_:
			cards.append_array(state.draw_pile)
			cards.append_array(state.hand)
			cards.append_array(state.discard_pile)
			cards.append_array(state.exhaust_pile)
	return cards

func _build_grouped_entries(cards: Array[CardInstance]) -> Array[Dictionary]:
	var grouped: Dictionary = {}
	for card_type in TYPE_ORDER:
		grouped[card_type] = {}

	for card in cards:
		if card == null or card.definition == null:
			continue
		var data := card.definition
		var card_type: BattleTypes.CardType = data.card_type
		if not grouped.has(card_type):
			grouped[card_type] = {}
		var group_bucket: Dictionary = grouped[card_type]
		var card_key: String = String(data.id) if not data.id.is_empty() else data.display_name
		var entry: Dictionary = group_bucket.get(card_key, {})
		if entry.is_empty():
			entry = {"card_data": data, "quantity": 0}
		entry["quantity"] = int(entry.get("quantity", 0)) + 1
		group_bucket[card_key] = entry
		grouped[card_type] = group_bucket

	var sections: Array[Dictionary] = []
	for card_type in TYPE_ORDER:
		var bucket: Dictionary = grouped.get(card_type, {})
		if bucket.is_empty():
			continue
		var entries: Array = bucket.values()
		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var a_data := a.get("card_data", null) as CardData
			var b_data := b.get("card_data", null) as CardData
			var a_name := a_data.display_name if a_data != null else ""
			var b_name := b_data.display_name if b_data != null else ""
			return a_name.naturalnocasecmp_to(b_name) < 0
		)
		var typed_entries: Array[Dictionary] = []
		var group_total := 0
		for entry in entries:
			typed_entries.append(entry)
			group_total += int(entry.get("quantity", 0))
		sections.append({
			"type": card_type,
			"title": _type_title(card_type),
			"entries": typed_entries,
			"total": group_total,
		})
	return sections

func _build_group_section(group_data: Dictionary) -> PanelContainer:
	var section := PanelContainer.new()
	section.add_theme_stylebox_override("panel", _build_section_style())
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	section.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header := Label.new()
	header.text = "%s · %d" % [String(group_data.get("title", "其他")), int(group_data.get("total", 0))]
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.22, 0.17, 0.11, 1.0))
	column.add_child(header)

	var grid := GridContainer.new()
	grid.columns = _grid_columns_for_current_width()
	grid.add_theme_constant_override("h_separation", int(GRID_SEPARATION))
	grid.add_theme_constant_override("v_separation", int(GRID_SEPARATION))
	column.add_child(grid)

	var entries := group_data.get("entries", []) as Array[Dictionary]
	for entry in entries:
		var card_data := entry.get("card_data", null) as CardData
		var quantity := int(entry.get("quantity", 1))
		var tile := DECK_CARD_TILE_SCENE.instantiate() as DeckCardTile
		if tile == null:
			continue
		tile.setup_from_definition(card_data, quantity)
		grid.add_child(tile)

	return section

func _build_empty_state() -> PanelContainer:
	var panel_container := PanelContainer.new()
	panel_container.add_theme_stylebox_override("panel", _build_section_style())
	panel_container.custom_minimum_size = Vector2(0, 180)

	var center := CenterContainer.new()
	panel_container.add_child(center)

	var label := Label.new()
	label.text = "当前没有可显示的卡牌。"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.31, 0.22, 0.14, 1.0))
	center.add_child(label)

	return panel_container

func _apply_shell_styles() -> void:
	backdrop.color = Color(0.16, 0.12, 0.07, 0.58)
	panel.add_theme_stylebox_override("panel", _build_outer_panel_style())
	content_panel.add_theme_stylebox_override("panel", _build_inner_panel_style())
	close_button.text = ""
	close_button.custom_minimum_size = BACK_BUTTON_REGION.size
	close_button.add_theme_stylebox_override("normal", _build_back_button_style(Color.WHITE))
	close_button.add_theme_stylebox_override("hover", _build_back_button_style(Color(1.05, 1.05, 1.05, 1.0)))
	close_button.add_theme_stylebox_override("pressed", _build_back_button_style(Color(0.90, 0.90, 0.90, 1.0)))
	close_button.add_theme_stylebox_override("focus", _build_back_button_style(Color.WHITE))
	for button in [all_tab_button, draw_tab_button, discard_tab_button]:
		button.custom_minimum_size = TAB_IDLE_REGION.size
		button.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.21, 0.16, 0.10, 1.0))
	summary_label.add_theme_color_override("font_color", Color(0.45, 0.34, 0.20, 1.0))

func _apply_tab_style(button: Button, active: bool) -> void:
	button.add_theme_stylebox_override("normal", _build_tab_style(active, false))
	button.add_theme_stylebox_override("hover", _build_tab_style(active, true))
	button.add_theme_stylebox_override("pressed", _build_tab_style(true, true))
	button.add_theme_stylebox_override("focus", _build_tab_style(active, false))
	var font_color := Color(0.95, 0.94, 0.89, 1.0) if active else Color(0.31, 0.23, 0.14, 1.0)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)

func _build_outer_panel_style() -> StyleBoxTexture:
	return _build_texture_style(LARGE_FRAME_TEXTURE, LARGE_FRAME_REGION, LARGE_FRAME_SLICE)

func _build_inner_panel_style() -> StyleBoxTexture:
	return _build_texture_style(MEDIUM_FRAME_TEXTURE, MEDIUM_FRAME_REGION, MEDIUM_FRAME_SLICE)

func _build_section_style() -> StyleBoxTexture:
	return _build_texture_style(SMALL_FRAME_TEXTURE, SMALL_FRAME_REGION, SMALL_FRAME_SLICE)

func _build_back_button_style(tint: Color) -> StyleBoxTexture:
	return _build_texture_style(BACK_BUTTON_TEXTURE, BACK_BUTTON_REGION, BACK_BUTTON_SLICE, tint)

func _build_tab_style(active: bool, hovered: bool) -> StyleBoxTexture:
	var texture := TAB_ACTIVE_TEXTURE if active else TAB_IDLE_TEXTURE
	var region := TAB_ACTIVE_REGION if active else TAB_IDLE_REGION
	var tint := Color(1.03, 1.03, 1.03, 1.0) if hovered else Color.WHITE
	return _build_texture_style(texture, region, TAB_SLICE, tint)

func _build_texture_style(texture: Texture2D, region: Rect2, slice: float, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _make_region_texture(texture, region)
	style.draw_center = true
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.set_texture_margin_all(slice)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	style.modulate_color = tint
	return style

func _make_region_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

func _title_for_tab(tab_id: StringName) -> String:
	match tab_id:
		TAB_DRAW:
			return "抽牌堆"
		TAB_DISCARD:
			return "弃牌堆"
		_:
			return "整个卡组"

func _type_title(card_type: BattleTypes.CardType) -> String:
	match card_type:
		BattleTypes.CardType.ATTACK:
			return "攻击"
		BattleTypes.CardType.SKILL:
			return "技能"
		BattleTypes.CardType.PURIFY:
			return "净化"
		_:
			return "其他"

func _grid_columns_for_current_width() -> int:
	var available_width := _current_content_width()
	if available_width <= 0.0:
		return 1
	return clampi(int(floor((available_width + GRID_SEPARATION) / (TILE_WIDTH + GRID_SEPARATION))), 1, 5)

func _count_cards(grouped_entries: Array[Dictionary]) -> int:
	var total := 0
	for group_data in grouped_entries:
		total += int(group_data.get("total", 0))
	return total

func _count_distinct_cards(grouped_entries: Array[Dictionary]) -> int:
	var total := 0
	for group_data in grouped_entries:
		var entries := group_data.get("entries", []) as Array[Dictionary]
		total += entries.size()
	return total

func _on_overlay_resized() -> void:
	if visible:
		if _pending_rebuild_after_open:
			_request_open_layout_rebuild()
		else:
			call_deferred("_rebuild_content")

func _on_content_area_resized() -> void:
	if visible and _pending_rebuild_after_open:
		_request_open_layout_rebuild()

func _focus_close_button() -> void:
	if close_button != null:
		close_button.grab_focus()

func _request_open_layout_rebuild(reset_retry_count: bool = false) -> void:
	if reset_retry_count:
		_open_layout_retry_count = 0
	_pending_rebuild_after_open = true
	if _open_layout_rebuild_queued:
		return
	_open_layout_rebuild_queued = true
	call_deferred("_finish_open_layout_rebuild")

func _finish_open_layout_rebuild() -> void:
	_open_layout_rebuild_queued = false
	if not visible:
		_pending_rebuild_after_open = false
		_open_layout_retry_count = 0
		return
	if not _content_width_is_ready() and _open_layout_retry_count < OPEN_LAYOUT_MAX_RETRIES:
		_open_layout_retry_count += 1
		_request_open_layout_rebuild()
		return
	_pending_rebuild_after_open = false
	_open_layout_retry_count = 0
	_rebuild_content()

func _current_content_width() -> float:
	return maxf(
		maxf(content_scroll.size.x, content_scroll.get_rect().size.x),
		maxf(content_panel.size.x, content_panel.get_rect().size.x)
	)

func _content_width_is_ready() -> bool:
	return _current_content_width() >= TILE_WIDTH * 2.0 + GRID_SEPARATION
