extends Control
class_name PlayerActor

@export var move_speed: float = 260.0

var room_bounds: Rect2 = Rect2(0, 0, 960, 540)
var is_active: bool = true
var _fill_color: Color = Color(0.16, 0.43, 0.92, 1.0)
var _outline_color: Color = Color(0.95, 0.98, 1.0, 1.0)

@onready var _label: Label = Label.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(48, 48)
	size = custom_minimum_size
	if _label.get_parent() == null:
		_label.text = "你"
		_label.add_theme_color_override("font_color", Color.WHITE)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.anchors_preset = Control.PRESET_FULL_RECT
		add_child(_label)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_active:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		return
	position += direction * move_speed * delta
	_clamp_to_room()

func set_room_bounds(bounds: Rect2) -> void:
	room_bounds = bounds
	_clamp_to_room()

func center_in_room(bounds: Rect2) -> void:
	room_bounds = bounds
	position = room_bounds.position + (room_bounds.size - size) * 0.5
	_clamp_to_room()

func set_active(active: bool) -> void:
	is_active = active

func get_center_point() -> Vector2:
	return global_position + size * 0.5

func _clamp_to_room() -> void:
	position.x = clampf(position.x, room_bounds.position.x, room_bounds.end.x - size.x)
	position.y = clampf(position.y, room_bounds.position.y, room_bounds.end.y - size.y)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _fill_color, true)
	draw_rect(Rect2(Vector2.ZERO, size), _outline_color, false, 3.0)
