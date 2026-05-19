extends Control
class_name FoodQueueView

const TEXT_DARK := Color(0.26, 0.16, 0.07, 1.0)
const NORMAL_PLAYER_FILL := Color(0.95, 0.76, 0.37, 0.98)
const NORMAL_PLAYER_BORDER := Color(0.62, 0.42, 0.16, 0.96)
const BAD_PLAYER_FILL := Color(0.78, 0.55, 0.43, 0.98)
const BAD_PLAYER_BORDER := Color(0.50, 0.25, 0.17, 0.96)
const NORMAL_ENEMY_FILL := Color(0.96, 0.74, 0.43, 0.98)
const NORMAL_ENEMY_BORDER := Color(0.62, 0.40, 0.18, 0.96)
const BAD_ENEMY_FILL := Color(0.77, 0.48, 0.42, 0.98)
const BAD_ENEMY_BORDER := Color(0.47, 0.20, 0.19, 0.96)
const ORDER_FONT_SIZE := 12
const PREVIEW_FILL := Color(1.0, 0.95, 0.62, 0.44)
const PREVIEW_BORDER := Color(1.0, 0.78, 0.22, 0.98)

const SLOT_CENTERS: Array[Vector2] = [
	Vector2(71.0, 85.0),
	Vector2(38.0, 136.0),
	Vector2(100.5, 138.5),
	Vector2(69.5, 192.0),
	Vector2(40.5, 248.5),
	Vector2(102.0, 251.0),
	Vector2(71.0, 307.5),
]
const SLOT_SIZE := Vector2(42.0, 46.0)
const BADGE_SIZE := Vector2(22.0, 16.0)

@export var accent_mode: StringName = &"player"

var _queue_items: Array[Dictionary] = []
var _capacity: int = 0
var _preview_target_indices: Array[int] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_queue(_title: String, items: Array[Dictionary], capacity: int) -> void:
	_queue_items = items.duplicate(true)
	_capacity = maxi(0, capacity)
	queue_redraw()

func set_preview_targets(indices: Array[int]) -> void:
	_preview_target_indices.clear()
	for index in indices:
		if typeof(index) != TYPE_INT:
			continue
		_preview_target_indices.append(index)
	queue_redraw()

func _draw() -> void:
	var slot_limit: int = mini(maxi(_capacity, _queue_items.size()), SLOT_CENTERS.size())
	for index in range(slot_limit):
		if index >= _queue_items.size():
			continue
		var slot_center: Vector2 = SLOT_CENTERS[index]
		var slot_rect: Rect2 = Rect2(slot_center - SLOT_SIZE * 0.5, SLOT_SIZE)
		_draw_queue_item(slot_rect, _queue_items[index], index, _preview_target_indices.has(index))

func _draw_queue_item(slot_rect: Rect2, item: Dictionary, index: int, is_preview_target: bool) -> void:
	var fill_color: Color = _item_fill_color(item)
	var border_color: Color = _item_border_color(item)
	var shadow_rect: Rect2 = slot_rect.grow(2.0)
	_draw_hex(shadow_rect, Color(0.18, 0.10, 0.04, 0.18), Color(0, 0, 0, 0), 0.0)
	_draw_hex(slot_rect, fill_color, border_color, 2.5)
	_draw_hex(slot_rect.grow(-6.0), Color(1.0, 0.88, 0.63, 0.28), Color(1.0, 0.95, 0.80, 0.18), 1.0)
	if is_preview_target:
		_draw_hex(slot_rect.grow(5.0), Color(0, 0, 0, 0), PREVIEW_BORDER, 3.0)
		_draw_hex(slot_rect.grow(-3.0), PREVIEW_FILL, Color(0, 0, 0, 0), 0.0)

	var badge_rect: Rect2 = Rect2(
		slot_rect.position + Vector2((slot_rect.size.x - BADGE_SIZE.x) * 0.5, (slot_rect.size.y - BADGE_SIZE.y) * 0.5),
		BADGE_SIZE
	)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(1.0, 0.90, 0.70, 0.62)
	badge_style.corner_radius_top_left = 6
	badge_style.corner_radius_top_right = 6
	badge_style.corner_radius_bottom_left = 6
	badge_style.corner_radius_bottom_right = 6
	draw_style_box(badge_style, badge_rect)
	_draw_text_line(badge_rect, str(index + 1), ORDER_FONT_SIZE, TEXT_DARK)

func _item_fill_color(item: Dictionary) -> Color:
	var is_bad: bool = bool(item.get("is_bad", false))
	if accent_mode == &"enemy":
		return BAD_ENEMY_FILL if is_bad else NORMAL_ENEMY_FILL
	return BAD_PLAYER_FILL if is_bad else NORMAL_PLAYER_FILL

func _item_border_color(item: Dictionary) -> Color:
	var is_bad: bool = bool(item.get("is_bad", false))
	if accent_mode == &"enemy":
		return BAD_ENEMY_BORDER if is_bad else NORMAL_ENEMY_BORDER
	return BAD_PLAYER_BORDER if is_bad else NORMAL_PLAYER_BORDER

func _draw_hex(rect: Rect2, fill_color: Color, border_color: Color, border_width: float) -> void:
	var points := PackedVector2Array()
	var corner_ratio: float = 0.26
	points.append(rect.position + Vector2(rect.size.x * 0.5, 0.0))
	points.append(rect.position + Vector2(rect.size.x, rect.size.y * corner_ratio))
	points.append(rect.position + Vector2(rect.size.x, rect.size.y * (1.0 - corner_ratio)))
	points.append(rect.position + Vector2(rect.size.x * 0.5, rect.size.y))
	points.append(rect.position + Vector2(0.0, rect.size.y * (1.0 - corner_ratio)))
	points.append(rect.position + Vector2(0.0, rect.size.y * corner_ratio))
	draw_colored_polygon(points, fill_color)
	if border_width <= 0.0 or border_color.a <= 0.0:
		return
	for i in range(points.size()):
		var from_point: Vector2 = points[i]
		var to_point: Vector2 = points[(i + 1) % points.size()]
		draw_line(from_point, to_point, border_color, border_width, true)

func _draw_text_line(rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null or text.is_empty():
		return
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_position := Vector2(
		rect.position.x + maxf(0.0, (rect.size.x - text_size.x) * 0.5),
		rect.position.y + maxf(font_size, (rect.size.y + font_size) * 0.5 - 3.0)
	)
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)
