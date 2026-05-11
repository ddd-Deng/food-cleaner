extends Control
class_name ExploreInteractable

var interactable_id: StringName = &""
var display_name: String = "交互物"
var prompt_text: String = "交互"
var interactable_kind: StringName = &"generic"
var payload: Dictionary = {}
var _base_fill: Color = Color(0.29, 0.31, 0.35, 0.95)
var _base_outline: Color = Color(0.86, 0.90, 0.95, 1.0)
var _highlight_fill: Color = Color(0.91, 0.78, 0.43, 0.98)
var _highlight_outline: Color = Color(1.0, 0.98, 0.90, 1.0)
var _is_highlighted: bool = false

@onready var _label: Label = Label.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(220, 64)
	size = custom_minimum_size
	if _label.get_parent() == null:
		_label.anchors_preset = Control.PRESET_FULL_RECT
		_label.offset_left = 10.0
		_label.offset_top = 6.0
		_label.offset_right = -10.0
		_label.offset_bottom = -6.0
		_label.add_theme_color_override("font_color", Color.WHITE)
		_label.add_theme_font_size_override("font_size", 16)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.max_lines_visible = 2
		add_child(_label)
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
	return global_position + size * 0.5

func _refresh_visual() -> void:
	_label.text = display_name
	queue_redraw()

func _draw() -> void:
	var fill := _highlight_fill if _is_highlighted else _base_fill
	var outline := _highlight_outline if _is_highlighted else _base_outline
	draw_rect(Rect2(Vector2.ZERO, size), fill, true)
	draw_rect(Rect2(Vector2.ZERO, size), outline, false, 3.0)
