extends PanelContainer
class_name PlayDropZone

signal drop_hover_changed(is_hovering: bool)
signal card_dropped(hand_index: int)

var _hovering: bool = false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var valid: bool = typeof(data) == TYPE_DICTIONARY and data.has("hand_index") and int(data.get("hand_index", -1)) >= 0
	_set_hovering(valid)
	return valid

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_hovering(false)
	if typeof(data) != TYPE_DICTIONARY:
		return
	card_dropped.emit(int(data.get("hand_index", -1)))

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_hovering(false)

func set_active(active: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS if active else Control.MOUSE_FILTER_IGNORE
	_update_style(active)

func _set_hovering(value: bool) -> void:
	if _hovering == value:
		return
	_hovering = value
	_update_style(true)
	drop_hover_changed.emit(_hovering)

func _update_style(active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.14, 0.9)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	if not active:
		style.bg_color = Color(0.12, 0.12, 0.12, 0.45)
		style.border_color = Color(0.25, 0.25, 0.25, 0.6)
	elif _hovering:
		style.bg_color = Color(0.20, 0.28, 0.17, 0.95)
		style.border_color = Color(0.56, 0.89, 0.42, 1.0)
	else:
		style.border_color = Color(0.56, 0.56, 0.56, 0.85)
	add_theme_stylebox_override("panel", style)
