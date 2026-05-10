extends PanelContainer
class_name CardView

signal play_requested(hand_index: int)
signal drag_started(card_view: CardView)
signal drag_ended(card_view: CardView, dropped_successfully: bool)

enum VisualState {
	IN_HAND,
	HOVERED,
	DRAGGING,
	PLAYABLE_OVER_DROP_ZONE,
	RETURNING,
	RESOLVING,
	DISABLED,
}

@onready var cost_label: Label = $Margin/Content/TopRow/CostLabel
@onready var name_label: Label = $Margin/Content/NameLabel
@onready var art_panel: PanelContainer = $Margin/Content/ArtPanel
@onready var art_label: Label = $Margin/Content/ArtPanel/ArtLabel
@onready var divider: ColorRect = $Margin/Content/Divider
@onready var description_label: Label = $Margin/Content/DescriptionLabel

var card_instance: CardInstance
var hand_index: int = -1
var visual_state: VisualState = VisualState.IN_HAND
var interactable: bool = true
var is_pointer_inside: bool = false
var is_dragging: bool = false
var _is_ui_ready: bool = false

func _ready() -> void:
	_is_ui_ready = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(136, 188)
	pivot_offset = custom_minimum_size * 0.5
	divider.color = Color(0.08, 0.08, 0.08, 1.0)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_configure_mouse_filters(self)
	_refresh_content()
	_apply_visual_state()

func setup(card: CardInstance, new_hand_index: int) -> void:
	card_instance = card
	hand_index = new_hand_index
	_refresh_content()
	_apply_visual_state()

func set_interactable(enabled: bool) -> void:
	interactable = enabled
	if enabled:
		set_visual_state(VisualState.IN_HAND)
	else:
		set_visual_state(VisualState.DISABLED)

func set_visual_state(state: VisualState) -> void:
	if visual_state == state:
		return
	visual_state = state
	_apply_visual_state()

func set_drag_hover_enabled(enabled: bool) -> void:
	if not interactable:
		return
	if enabled:
		set_visual_state(VisualState.PLAYABLE_OVER_DROP_ZONE)
	elif is_dragging:
		set_visual_state(VisualState.DRAGGING)
	elif is_pointer_inside:
		set_visual_state(VisualState.HOVERED)
	else:
		set_visual_state(VisualState.IN_HAND)

func mark_resolving() -> void:
	set_visual_state(VisualState.RESOLVING)

func _refresh_content() -> void:
	if not _is_ui_ready or card_instance == null:
		return
	cost_label.text = "%dt" % card_instance.get_time_cost()
	name_label.text = card_instance.get_display_name()
	art_label.text = card_instance.get_art_label()
	description_label.text = card_instance.definition.description if card_instance.definition != null else ""
	_update_art_style()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not interactable or hand_index < 0:
		return null
	is_dragging = true
	set_visual_state(VisualState.DRAGGING)
	drag_started.emit(self)
	var preview: CardView = duplicate()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.interactable = false
	preview.set_visual_state(VisualState.DRAGGING)
	preview.scale = Vector2(1.06, 1.06)
	set_drag_preview(preview)
	return {
		"source": self,
		"hand_index": hand_index,
	}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_dragging:
		is_dragging = false
		var dropped_successfully: bool = is_drag_successful()
		if not dropped_successfully:
			set_visual_state(VisualState.RETURNING)
			set_visual_state(VisualState.IN_HAND if interactable else VisualState.DISABLED)
		drag_ended.emit(self, dropped_successfully)

func _gui_input(event: InputEvent) -> void:
	if not interactable:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			accept_event()

func _on_mouse_entered() -> void:
	is_pointer_inside = true
	if interactable and not is_dragging:
		set_visual_state(VisualState.HOVERED)

func _on_mouse_exited() -> void:
	is_pointer_inside = false
	if interactable and not is_dragging:
		set_visual_state(VisualState.IN_HAND)

func _apply_visual_state() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = _background_color_for_type()
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = _border_color_for_state()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	add_theme_stylebox_override("panel", style)

	modulate = Color(1, 1, 1, 0.55) if visual_state == VisualState.DISABLED else Color.WHITE

	match visual_state:
		VisualState.HOVERED:
			scale = Vector2(1.03, 1.03)
			position.y = -8.0
		VisualState.DRAGGING:
			scale = Vector2(1.05, 1.05)
			position.y = 0.0
			modulate = Color(1, 1, 1, 0.92)
		VisualState.PLAYABLE_OVER_DROP_ZONE:
			scale = Vector2(1.07, 1.07)
			position.y = 0.0
		VisualState.RETURNING:
			scale = Vector2.ONE
			position.y = 0.0
		VisualState.RESOLVING:
			scale = Vector2(0.98, 0.98)
			position.y = 0.0
			modulate = Color(1, 1, 1, 0.72)
		VisualState.DISABLED:
			scale = Vector2.ONE
			position.y = 0.0
		_:
			scale = Vector2.ONE
			position.y = 0.0

	if _is_ui_ready and art_panel != null:
		art_panel.queue_redraw()

func _configure_mouse_filters(root: Node) -> void:
	for child in root.get_children():
		if child is Control:
			var control := child as Control
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_configure_mouse_filters(control)

func _background_color_for_type() -> Color:
	if card_instance == null:
		return Color(0.37, 0.37, 0.37, 1.0)
	match card_instance.get_card_type():
		BattleTypes.CardType.EAT:
			return Color(0.53, 0.35, 0.27, 1.0)
		BattleTypes.CardType.DIGEST:
			return Color(0.34, 0.47, 0.31, 1.0)
		BattleTypes.CardType.PURIFY:
			return Color(0.30, 0.43, 0.58, 1.0)
		BattleTypes.CardType.SUPPORT:
			return Color(0.56, 0.48, 0.24, 1.0)
		_:
			return Color(0.37, 0.37, 0.37, 1.0)

func _border_color_for_state() -> Color:
	match visual_state:
		VisualState.HOVERED:
			return Color(0.95, 0.95, 0.90, 1.0)
		VisualState.DRAGGING:
			return Color(0.93, 0.83, 0.35, 1.0)
		VisualState.PLAYABLE_OVER_DROP_ZONE:
			return Color(0.64, 0.93, 0.52, 1.0)
		VisualState.RESOLVING:
			return Color(0.70, 0.70, 0.70, 1.0)
		VisualState.DISABLED:
			return Color(0.20, 0.20, 0.20, 1.0)
		_:
			return Color(0.10, 0.10, 0.10, 1.0)

func _update_art_style() -> void:
	if not _is_ui_ready or art_panel == null:
		return
	var art_style := StyleBoxFlat.new()
	art_style.bg_color = Color(1, 1, 1, 0.14)
	art_style.border_width_left = 2
	art_style.border_width_top = 2
	art_style.border_width_right = 2
	art_style.border_width_bottom = 2
	art_style.border_color = Color(0.08, 0.08, 0.08, 0.85)
	art_style.corner_radius_top_left = 4
	art_style.corner_radius_top_right = 4
	art_style.corner_radius_bottom_left = 4
	art_style.corner_radius_bottom_right = 4
	art_panel.add_theme_stylebox_override("panel", art_style)
