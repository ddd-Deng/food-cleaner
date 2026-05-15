extends Node2D
class_name ExploreInteractable

@export var interactable_id: StringName = &""
@export var display_name: String = "交互物":
	set(value):
		_display_name = value
		if is_node_ready():
			_refresh_visual()
@export var prompt_text: String = "交互"
@export var interactable_kind: StringName = &"generic"
@export var area_size: Vector2 = Vector2(220, 64):
	set(value):
		_area_size = value
		if is_node_ready():
			_refresh_shape()
var payload: Dictionary = {}
var _base_fill: Color = Color(0.29, 0.31, 0.35, 0.95)
var _base_outline: Color = Color(0.86, 0.90, 0.95, 1.0)
var _highlight_fill: Color = Color(0.91, 0.78, 0.43, 0.98)
var _highlight_outline: Color = Color(1.0, 0.98, 0.90, 1.0)
var _is_highlighted: bool = false
var _display_name: String = "交互物"
var _area_size: Vector2 = Vector2(220, 64)

@onready var area: Area2D = get_node_or_null("Area2D")
@onready var collision_shape: CollisionShape2D = get_node_or_null("Area2D/CollisionShape2D")
@onready var label: Label = get_node_or_null("Label")

func _ready() -> void:
	_configure_area()
	_configure_label()
	_refresh_shape()
	_refresh_visual()

func configure(new_id: StringName, new_name: String, new_prompt_text: String, new_kind: StringName, new_payload: Dictionary = {}) -> void:
	interactable_id = new_id
	display_name = new_name
	prompt_text = new_prompt_text
	interactable_kind = new_kind
	payload = new_payload
	if is_node_ready():
		_refresh_visual()

func set_highlighted(highlighted: bool) -> void:
	_is_highlighted = highlighted
	queue_redraw()

func get_center_point() -> Vector2:
	return global_position

func _configure_area() -> void:
	if area == null:
		area = Area2D.new()
		area.name = "Area2D"
	if area.get_parent() == null:
		add_child(area)
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
	if collision_shape.get_parent() == null:
		area.add_child(collision_shape)
	area.monitoring = true
	area.monitorable = true

func _configure_label() -> void:
	if label == null:
		label = Label.new()
		label.name = "Label"
	if label.get_parent() == null:
		add_child(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 2
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 16)
	label.position = -_area_size * 0.5
	label.size = _area_size

func _refresh_shape() -> void:
	if collision_shape == null:
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = _area_size
	collision_shape.shape = rectangle
	if label != null:
		label.position = -_area_size * 0.5
		label.size = _area_size
	queue_redraw()

func _refresh_visual() -> void:
	if label != null:
		label.text = _display_name
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(-_area_size * 0.5, _area_size)
	var fill := _highlight_fill if _is_highlighted else _base_fill
	var outline := _highlight_outline if _is_highlighted else _base_outline
	draw_rect(rect, fill, true)
	draw_rect(rect, outline, false, 3.0)
