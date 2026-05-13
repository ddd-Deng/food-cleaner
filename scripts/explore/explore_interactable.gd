extends Node2D
class_name ExploreInteractable

@export var interactable_id: StringName = &""
@export var display_name: String = "交互物":
	set(value):
		display_name = value
		_refresh_visual()
@export var prompt_text: String = "交互"
@export var interactable_kind: StringName = &"generic"
@export var area_size: Vector2 = Vector2(220, 64):
	set(value):
		area_size = value
		_refresh_shape()
var payload: Dictionary = {}
var _base_fill: Color = Color(0.29, 0.31, 0.35, 0.95)
var _base_outline: Color = Color(0.86, 0.90, 0.95, 1.0)
var _highlight_fill: Color = Color(0.91, 0.78, 0.43, 0.98)
var _highlight_outline: Color = Color(1.0, 0.98, 0.90, 1.0)
var _is_highlighted: bool = false

@onready var area: Area2D = Area2D.new()
@onready var collision_shape: CollisionShape2D = CollisionShape2D.new()
@onready var label: Label = Label.new()

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
	add_child(area)
	area.add_child(collision_shape)
	area.monitoring = true
	area.monitorable = true

func _configure_label() -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 2
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 16)
	label.position = -area_size * 0.5
	label.size = area_size
	add_child(label)

func _refresh_shape() -> void:
	if collision_shape == null:
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = area_size
	collision_shape.shape = rectangle
	if label != null:
		label.position = -area_size * 0.5
		label.size = area_size
	queue_redraw()

func _refresh_visual() -> void:
	if label != null:
		label.text = display_name
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(-area_size * 0.5, area_size)
	var fill := _highlight_fill if _is_highlighted else _base_fill
	var outline := _highlight_outline if _is_highlighted else _base_outline
	draw_rect(rect, fill, true)
	draw_rect(rect, outline, false, 3.0)
