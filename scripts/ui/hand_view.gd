extends Control
class_name HandView

const CARD_VIEW_SCENE: PackedScene = preload("res://scenes/ui/card_view.tscn")
const FAN_MAX_ANGLE_DEGREES: float = 16.0
const CARD_SPACING_MIN: float = 104.0
const CARD_SPACING_MAX: float = 134.0
const CARD_CENTER_LIFT: float = 12.0
const CARD_EDGE_TOP_DROP: float = 22.0
const FAN_TOP_CURVE_POWER: float = 1.35
const FULL_SIZE_HAND_COUNT: int = 5
const MAX_HAND_COUNT: int = 8
const MIN_CARD_SCALE: float = 0.84
const HAND_BOTTOM_PADDING: float = 104.0
const HAND_VERTICAL_OFFSET: float = -22.0
const HAND_RELEASE_GRACE_HEIGHT: float = 24.0

signal card_released_outside_hand(hand_index: int)
signal drag_cancelled()
signal card_preview_requested(card: CardInstance, hand_index: int)
signal card_preview_cleared()

var _cards_interactable: bool = true
var _slot_order: Array[int] = []
var _active_drag_card_id: int = -1
var _hover_owner: CardView = null
var _card_size: Vector2 = Vector2(144, 192)
var _layout_card_scale: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	set_process(true)
	_refresh_card_size_from_scene()
	resized.connect(_layout_cards)

func rebuild_hand(cards: Array[CardInstance], interactable: bool) -> void:
	_cards_interactable = interactable
	var previous_views: Dictionary = {}
	for card_view in get_card_views():
		var previous_id: int = _card_id(card_view.card_instance)
		if previous_id >= 0:
			previous_views[previous_id] = card_view

	var current_card_ids: Array[int] = []
	var card_by_id: Dictionary = {}
	for card in cards:
		var card_id: int = _card_id(card)
		current_card_ids.append(card_id)
		card_by_id[card_id] = card

	var next_slot_order: Array[int] = current_card_ids.duplicate()

	var reused_views: Array[CardView] = []
	for order_index in range(next_slot_order.size()):
		var card_id: int = next_slot_order[order_index]
		var card_view: CardView = previous_views.get(card_id, null)
		if card_view == null:
			card_view = CARD_VIEW_SCENE.instantiate()
			add_child(card_view)
			card_view.hover_requested.connect(_on_card_hover_requested)
			card_view.hover_cleared.connect(_on_card_hover_cleared)
			card_view.drag_started.connect(_on_card_drag_started)
			card_view.drag_ended.connect(_on_card_drag_ended)
		var card: CardInstance = card_by_id.get(card_id, null)
		card_view.setup(card, order_index)
		card_view.set_interactable(interactable)
		if card_id == _active_drag_card_id and card_view.is_dragging:
			card_view.set_interactable(true)
		reused_views.append(card_view)

	for card_view in get_card_views():
		if not reused_views.has(card_view):
			if _hover_owner == card_view:
				_hover_owner = null
				card_preview_cleared.emit()
			remove_child(card_view)
			card_view.queue_free()

	for order_index in range(reused_views.size()):
		move_child(reused_views[order_index], order_index)

	_slot_order = next_slot_order
	call_deferred("_layout_cards")

func get_card_views() -> Array[CardView]:
	var card_views: Array[CardView] = []
	for child in get_children():
		if child is CardView and not child.is_queued_for_deletion():
			card_views.append(child as CardView)
	return card_views

func find_card_view(hand_index: int) -> CardView:
	for card_view in get_card_views():
		if card_view.hand_index == hand_index:
			return card_view
	return null

func set_drop_hover(is_hovering: bool) -> void:
	for card_view in get_card_views():
		if card_view.is_dragging:
			card_view.set_drag_hover_enabled(is_hovering)

func mark_card_resolving(hand_index: int) -> void:
	var card_view := find_card_view(hand_index)
	if card_view != null:
		card_view.mark_resolving()

func cancel_active_drag() -> bool:
	for card_view in get_card_views():
		if not card_view.is_dragging:
			continue
		card_view.mark_drag_cancelled()
		return true
	return false

func is_card_majority_in_non_hand_zone(card_view: CardView) -> bool:
	if card_view == null:
		return false
	var card_rect := card_view.get_global_rect()
	return card_rect.position.y + card_rect.size.y * 0.5 < _hand_zone_top_global_y()

func _process(_delta: float) -> void:
	if _active_drag_card_id >= 0:
		return
	var body_hover_card := _find_topmost_card_body_under_mouse()
	if body_hover_card != null and body_hover_card != _hover_owner:
		_grant_hover_to(body_hover_card)
		return
	if body_hover_card == null and _hover_owner != null:
		if is_instance_valid(_hover_owner) and _hover_owner.is_mouse_inside_hover_hold_area():
			return
		var previous_hover_owner := _hover_owner
		_hover_owner = null
		if is_instance_valid(previous_hover_owner):
			previous_hover_owner.force_hover_exit()
		card_preview_cleared.emit()

func _card_id(card: CardInstance) -> int:
	return card.get_instance_id() if card != null else -1

func _find_topmost_card_body_under_mouse() -> CardView:
	var card_views := get_card_views()
	for reverse_index in range(card_views.size() - 1, -1, -1):
		var card_view: CardView = card_views[reverse_index]
		if not card_view.interactable or card_view.is_dragging:
			continue
		if card_view.is_mouse_inside_card_body():
			return card_view
	return null

func _hand_zone_top_global_y() -> float:
	var layout_card_size: Vector2 = _card_size * _layout_card_scale
	var base_y: float = maxf(0.0, size.y - layout_card_size.y - HAND_BOTTOM_PADDING)
	var lifted_top_local_y: float = base_y + HAND_VERTICAL_OFFSET - CARD_CENTER_LIFT * _layout_card_scale
	return global_position.y + lifted_top_local_y - HAND_RELEASE_GRACE_HEIGHT

func _layout_cards() -> void:
	var card_views := get_card_views()
	var card_count: int = card_views.size()
	if card_count == 0:
		return

	_layout_card_scale = _card_scale_for_count(card_count)
	var layout_card_size: Vector2 = _card_size * _layout_card_scale
	var available_width: float = maxf(size.x, layout_card_size.x)
	var spacing: float = 0.0
	if card_count > 1:
		var width_limited_spacing: float = (available_width - layout_card_size.x) / float(card_count - 1)
		spacing = clampf(width_limited_spacing, CARD_SPACING_MIN * _layout_card_scale, CARD_SPACING_MAX * _layout_card_scale)

	var total_width: float = spacing * float(card_count - 1)
	var start_x: float = (available_width - layout_card_size.x - total_width) * 0.5
	var base_y: float = maxf(0.0, size.y - layout_card_size.y - HAND_BOTTOM_PADDING)
	var midpoint: float = float(card_count - 1) * 0.5

	for index in range(card_count):
		var card_view: CardView = card_views[index]
		if card_view.is_dragging:
			continue
		var normalized_offset: float = 0.0
		if midpoint > 0.0:
			normalized_offset = (float(index) - midpoint) / midpoint
		var x: float = start_x + spacing * float(index)
		var fan_rotation_degrees: float = FAN_MAX_ANGLE_DEGREES * normalized_offset
		var desired_top_y: float = base_y + HAND_VERTICAL_OFFSET - CARD_CENTER_LIFT * _layout_card_scale + CARD_EDGE_TOP_DROP * _layout_card_scale * pow(absf(normalized_offset), FAN_TOP_CURVE_POWER)
		var rotated_top_extent: float = _rotated_card_top_extent(layout_card_size, fan_rotation_degrees)
		var y: float = desired_top_y - layout_card_size.y * 0.5 + rotated_top_extent
		card_view.set_hand_layout_scale(_layout_card_scale)
		card_view.set_hand_transform(Vector2(x, y), fan_rotation_degrees, index)

func _card_scale_for_count(card_count: int) -> float:
	if card_count <= FULL_SIZE_HAND_COUNT:
		return 1.0
	var extra_card_ratio: float = float(card_count - FULL_SIZE_HAND_COUNT) / float(MAX_HAND_COUNT - FULL_SIZE_HAND_COUNT)
	return lerpf(1.0, MIN_CARD_SCALE, clampf(extra_card_ratio, 0.0, 1.0))

func _rotated_card_top_extent(card_size: Vector2, fan_rotation_degrees: float) -> float:
	var radians: float = deg_to_rad(fan_rotation_degrees)
	return absf(cos(radians)) * card_size.y * 0.5 + absf(sin(radians)) * card_size.x * 0.5

func _on_card_drag_started(active_card_view: CardView) -> void:
	_active_drag_card_id = _card_id(active_card_view.card_instance)
	_on_card_hover_requested(active_card_view)
	for card_view in get_card_views():
		if card_view == active_card_view:
			continue
		card_view.set_interactable(false)

func _on_card_hover_requested(active_card_view: CardView) -> void:
	if _hover_owner != null and _hover_owner != active_card_view:
		if is_instance_valid(_hover_owner) and _hover_owner.is_mouse_inside_hover_hold_area():
			if not active_card_view.is_mouse_inside_card_body():
				return
	_grant_hover_to(active_card_view)

func _grant_hover_to(active_card_view: CardView) -> void:
	for card_view in get_card_views():
		if card_view == active_card_view:
			continue
		card_view.force_hover_exit()
	_hover_owner = active_card_view
	active_card_view.grant_hover()
	card_preview_requested.emit(active_card_view.card_instance, active_card_view.hand_index)

func _on_card_hover_cleared(card_view: CardView) -> void:
	if _hover_owner != card_view:
		return
	_hover_owner = null
	if _active_drag_card_id >= 0:
		return
	card_preview_cleared.emit()

func _on_card_drag_ended(card_view: CardView, dropped_successfully: bool, _release_global_position: Vector2, cancelled_by_user: bool) -> void:
	_active_drag_card_id = -1
	if _hover_owner == card_view:
		_hover_owner = null
	card_preview_cleared.emit()
	if cancelled_by_user:
		for view in get_card_views():
			view.set_interactable(_cards_interactable)
		drag_cancelled.emit()
		return
	if not dropped_successfully and card_view.hand_index >= 0 and is_card_majority_in_non_hand_zone(card_view):
		card_released_outside_hand.emit(card_view.hand_index)
		return
	for view in get_card_views():
		view.set_interactable(_cards_interactable)

func _refresh_card_size_from_scene() -> void:
	var card_prototype := CARD_VIEW_SCENE.instantiate() as Control
	if card_prototype == null:
		return
	var scene_card_size := card_prototype.custom_minimum_size
	if scene_card_size == Vector2.ZERO:
		scene_card_size = card_prototype.size
	if scene_card_size != Vector2.ZERO:
		_card_size = scene_card_size
	card_prototype.free()
