extends PanelContainer
class_name CardView

const HOVER_SCALE: float = 1.08
const HOVER_LIFT: float = 34.0
const HOVER_HOLD_PADDING: float = 14.0
const DRAG_START_DISTANCE: float = 8.0

signal drag_started(card_view: CardView)
signal drag_ended(card_view: CardView, dropped_successfully: bool, release_global_position: Vector2, cancelled_by_user: bool)
signal hover_requested(card_view: CardView)

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
@onready var name_label: Label = $Margin/Content/TopRow/NameLabel
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
var _drag_cancelled_by_user: bool = false
var _is_left_button_held: bool = false
var _is_ui_ready: bool = false
var _base_size: Vector2 = Vector2.ZERO
var _hand_layout_scale: float = 1.0
var _hand_position: Vector2 = Vector2.ZERO
var _hand_rotation_degrees: float = 0.0
var _hand_z_index: int = 0
var _drag_pointer_offset: Vector2 = Vector2.ZERO
var _drag_position: Vector2 = Vector2.ZERO
var _press_global_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_is_ui_ready = true
	set_process(false)
	set_process_input(false)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_capture_base_layout()
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

func set_hand_transform(hand_position: Vector2, hand_rotation_degrees: float, hand_z_index: int) -> void:
	_hand_position = hand_position
	_hand_rotation_degrees = hand_rotation_degrees
	_hand_z_index = hand_z_index
	_apply_visual_state()

func set_hand_layout_scale(layout_scale: float) -> void:
	_hand_layout_scale = clampf(layout_scale, 0.75, 1.0)
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
	set_process(visual_state == VisualState.HOVERED)
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

func mark_drag_cancelled() -> void:
	if is_dragging:
		_drag_cancelled_by_user = true
		_is_left_button_held = false
		_finish_drag()
		set_process_input(false)

func force_hover_exit() -> void:
	if visual_state != VisualState.HOVERED:
		is_pointer_inside = false
		return
	is_pointer_inside = false
	set_visual_state(VisualState.IN_HAND if interactable else VisualState.DISABLED)

func grant_hover() -> void:
	if interactable and not is_dragging:
		is_pointer_inside = true
		set_visual_state(VisualState.HOVERED)

func is_mouse_inside_hover_hold_area() -> bool:
	return _is_mouse_inside_hover_hold_area()

func is_mouse_inside_card_body() -> bool:
	return _is_mouse_inside_current_card_body()

func _refresh_content() -> void:
	if not _is_ui_ready or card_instance == null:
		return
	cost_label.text = "%dt" % card_instance.get_time_cost()
	name_label.text = card_instance.get_display_name()
	art_label.text = card_instance.get_art_label()
	description_label.text = card_instance.definition.description if card_instance.definition != null else ""
	_update_art_style()

func _capture_base_layout() -> void:
	_base_size = custom_minimum_size
	if _base_size == Vector2.ZERO:
		_base_size = size
	if _base_size == Vector2.ZERO:
		_base_size = Vector2(144, 192)
	size = _base_size
	pivot_offset = _base_size * 0.5

func _get_card_size() -> Vector2:
	var base_size := _base_size if _base_size != Vector2.ZERO else custom_minimum_size
	return base_size * _hand_layout_scale

func _process(_delta: float) -> void:
	if visual_state != VisualState.HOVERED:
		set_process(false)
		return
	if not interactable or is_dragging:
		return
	if _is_mouse_inside_hover_hold_area():
		is_pointer_inside = true
		return
	is_pointer_inside = false
	set_visual_state(VisualState.IN_HAND)

func _input(event: InputEvent) -> void:
	if not (_is_left_button_held or is_dragging):
		return
	if event is InputEventMouseMotion:
		var mouse_event := event as InputEventMouseMotion
		if _is_left_button_held and not is_dragging and (mouse_event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if get_global_mouse_position().distance_to(_press_global_position) >= DRAG_START_DISTANCE:
				_begin_drag()
		if is_dragging:
			_update_drag_position()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_finish_drag()
			_is_left_button_held = false
			set_process_input(is_dragging)

func _gui_input(event: InputEvent) -> void:
	if not interactable:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_is_left_button_held = true
			_press_global_position = get_global_mouse_position()
			_drag_pointer_offset = _mouse_position_in_parent() - position
			_drag_cancelled_by_user = false
			set_process_input(true)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			accept_event()

func _on_mouse_entered() -> void:
	is_pointer_inside = true
	if interactable and not is_dragging:
		hover_requested.emit(self)

func _on_mouse_exited() -> void:
	if not interactable or is_dragging:
		is_pointer_inside = false
		return
	if visual_state == VisualState.HOVERED and _is_mouse_inside_hover_hold_area():
		is_pointer_inside = true
		set_process(true)
		return
	is_pointer_inside = false
	set_visual_state(VisualState.IN_HAND)

func _is_mouse_inside_hover_hold_area() -> bool:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return get_global_rect().grow(HOVER_HOLD_PADDING).has_point(get_global_mouse_position())

	var mouse_in_parent: Vector2 = parent_control.get_global_transform().affine_inverse() * get_global_mouse_position()
	var card_size := _get_card_size()
	var base_rect := Rect2(_hand_position, card_size).grow(HOVER_HOLD_PADDING)
	if base_rect.has_point(mouse_in_parent):
		return true

	var hovered_size: Vector2 = card_size * HOVER_SCALE
	var hovered_position: Vector2 = _hand_position + Vector2(0.0, -HOVER_LIFT * _hand_layout_scale) - (hovered_size - card_size) * 0.5
	var hovered_rect := Rect2(hovered_position, hovered_size).grow(HOVER_HOLD_PADDING)
	return hovered_rect.has_point(mouse_in_parent)

func _is_mouse_inside_current_card_body() -> bool:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return get_global_rect().has_point(get_global_mouse_position())

	var mouse_in_parent: Vector2 = parent_control.get_global_transform().affine_inverse() * get_global_mouse_position()
	var card_size := _get_card_size()
	var current_size := Vector2(card_size.x * scale.x, card_size.y * scale.y)
	var current_position: Vector2 = position - (current_size - card_size) * 0.5
	return Rect2(current_position, current_size).has_point(mouse_in_parent)

func _begin_drag() -> void:
	if is_dragging or not interactable or hand_index < 0:
		return
	is_dragging = true
	_drag_cancelled_by_user = false
	_drag_position = position
	set_visual_state(VisualState.DRAGGING)
	drag_started.emit(self)
	_update_drag_position()

func _finish_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	var release_global_position: Vector2 = get_global_mouse_position()
	var cancelled_by_user: bool = _drag_cancelled_by_user
	_drag_cancelled_by_user = false
	if cancelled_by_user:
		set_visual_state(VisualState.RETURNING)
		set_visual_state(VisualState.IN_HAND if interactable else VisualState.DISABLED)
	else:
		is_pointer_inside = false
		_drag_position = position
	drag_ended.emit(self, false, release_global_position, cancelled_by_user)

func _update_drag_position() -> void:
	_drag_position = _mouse_position_in_parent() - _drag_pointer_offset
	_apply_visual_state()

func _mouse_position_in_parent() -> Vector2:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return get_global_mouse_position()
	return parent_control.get_global_transform().affine_inverse() * get_global_mouse_position()

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
	custom_minimum_size = _get_card_size()
	size = _get_card_size()
	pivot_offset = _get_card_size() * 0.5
	position = _drag_position if is_dragging else _hand_position
	rotation_degrees = _hand_rotation_degrees
	scale = Vector2.ONE
	z_index = _hand_z_index

	match visual_state:
		VisualState.HOVERED:
			scale = Vector2(HOVER_SCALE, HOVER_SCALE)
			position += Vector2(0.0, -HOVER_LIFT * _hand_layout_scale)
			rotation_degrees = 0.0
			z_index = 1000 + _hand_z_index
		VisualState.DRAGGING:
			scale = Vector2(1.05, 1.05)
			rotation_degrees = 0.0
			z_index = 1100 + _hand_z_index
			modulate = Color(1, 1, 1, 0.92)
		VisualState.PLAYABLE_OVER_DROP_ZONE:
			scale = Vector2(1.07, 1.07)
			rotation_degrees = 0.0
			z_index = 1050 + _hand_z_index
		VisualState.RETURNING:
			pass
		VisualState.RESOLVING:
			scale = Vector2(0.98, 0.98)
			rotation_degrees = 0.0
			z_index = 1025 + _hand_z_index
			modulate = Color(1, 1, 1, 0.72)
		VisualState.DISABLED:
			pass
		_:
			pass

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
		BattleTypes.CardType.ATTACK:
			return Color(0.53, 0.35, 0.27, 1.0)
		BattleTypes.CardType.SKILL:
			return Color(0.34, 0.47, 0.31, 1.0)
		BattleTypes.CardType.PURIFY:
			return Color(0.30, 0.43, 0.58, 1.0)
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
