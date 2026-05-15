extends Control
class_name DeckViewOverlay

const DECK_CARD_TILE_SCENE: PackedScene = preload("res://scenes/ui/deck_card_tile.tscn")
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
	_apply_shell_styles()
	_rebuild_tabs()
	_rebuild_content()

func open_with_state(state: BattleState, initial_tab: StringName) -> void:
	_state = state
	_current_tab = initial_tab if TAB_ORDER.has(initial_tab) else TAB_ALL
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild_tabs()
	_rebuild_content()
	call_deferred("_focus_close_button")

func refresh_with_state(state: BattleState) -> void:
	_state = state
	if visible:
		_rebuild_content()

func close() -> void:
	visible = false

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
	panel.add_theme_stylebox_override("panel", _build_outer_panel_style())
	content_panel.add_theme_stylebox_override("panel", _build_inner_panel_style())
	close_button.add_theme_stylebox_override("normal", _build_action_button_style(false))
	close_button.add_theme_stylebox_override("hover", _build_action_button_style(true))
	close_button.add_theme_stylebox_override("pressed", _build_action_button_style(true, true))
	close_button.add_theme_color_override("font_color", Color(0.97, 0.95, 0.87, 1.0))
	title_label.add_theme_color_override("font_color", Color(0.21, 0.16, 0.10, 1.0))
	summary_label.add_theme_color_override("font_color", Color(0.45, 0.34, 0.20, 1.0))

func _apply_tab_style(button: Button, active: bool) -> void:
	button.add_theme_stylebox_override("normal", _build_tab_style(active, false))
	button.add_theme_stylebox_override("hover", _build_tab_style(active, true))
	button.add_theme_stylebox_override("pressed", _build_tab_style(true, true))
	button.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86, 1.0) if active else Color(0.38, 0.28, 0.17, 1.0))

func _build_outer_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.91, 0.77, 0.98)
	style.border_color = Color(0.24, 0.17, 0.09, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 10
	return style

func _build_inner_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.89, 0.92)
	style.border_color = Color(0.67, 0.54, 0.33, 0.65)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style

func _build_section_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.95, 0.86, 0.95)
	style.border_color = Color(0.72, 0.61, 0.40, 0.58)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	return style

func _build_action_button_style(is_hovered: bool, is_pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.23, 0.17, 0.10, 1.0)
	if is_hovered:
		style.bg_color = Color(0.31, 0.22, 0.12, 1.0)
	if is_pressed:
		style.bg_color = Color(0.17, 0.12, 0.07, 1.0)
	style.border_color = Color(0.87, 0.72, 0.34, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

func _build_tab_style(active: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if active:
		style.bg_color = Color(0.29, 0.45, 0.34, 1.0) if hovered else Color(0.25, 0.40, 0.30, 1.0)
		style.border_color = Color(0.82, 0.90, 0.72, 1.0)
	else:
		style.bg_color = Color(0.90, 0.83, 0.67, 1.0) if hovered else Color(0.94, 0.88, 0.74, 1.0)
		style.border_color = Color(0.66, 0.53, 0.31, 0.82)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

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
	var available_width := content_scroll.size.x
	if available_width <= 0.0:
		available_width = content_panel.size.x
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
		call_deferred("_rebuild_content")

func _focus_close_button() -> void:
	if close_button != null:
		close_button.grab_focus()
