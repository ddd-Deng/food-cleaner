extends Control
class_name FoodQueueView

const EMPTY_ITEM_COUNT := 3
const TITLE_COLOR := Color(0.24, 0.16, 0.08, 1.0)
const SUBTITLE_COLOR := Color(0.39, 0.28, 0.17, 0.92)
const EMPTY_SLOT_FILL := Color(0.31, 0.23, 0.15, 0.22)
const EMPTY_SLOT_BORDER := Color(0.55, 0.42, 0.25, 0.55)
const PLAYER_ITEM_FILL := Color(0.94, 0.80, 0.51, 0.96)
const PLAYER_ITEM_BORDER := Color(0.61, 0.44, 0.21, 0.92)
const ENEMY_ITEM_FILL := Color(0.83, 0.61, 0.55, 0.96)
const ENEMY_ITEM_BORDER := Color(0.52, 0.27, 0.24, 0.92)
const TEXT_DARK := Color(0.19, 0.12, 0.06, 1.0)
const TEXT_LIGHT := Color(0.98, 0.96, 0.91, 1.0)
const DIGESTION_COLOR := Color(0.28, 0.19, 0.08, 0.9)
const TITLE_FONT_SIZE := 18
const SUBTITLE_FONT_SIZE := 12
const ITEM_NAME_FONT_SIZE := 14
const ITEM_META_FONT_SIZE := 12

@export var title_text: String = "食物顺序"
@export var accent_mode: StringName = &"player"

var _queue_items: Array[Dictionary] = []
var _capacity: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_queue(title: String, items: Array[Dictionary], capacity: int) -> void:
	title_text = title
	_queue_items = items.duplicate(true)
	_capacity = max(0, capacity)
	queue_redraw()

func _draw() -> void:
	var content_rect: Rect2 = Rect2(Vector2(12, 12), size - Vector2(24, 24))
	if content_rect.size.x <= 0.0 or content_rect.size.y <= 0.0:
		return

	var title_height: float = 26.0
	var title_rect: Rect2 = Rect2(content_rect.position, Vector2(content_rect.size.x, title_height))
	_draw_text_line(title_rect, title_text, TITLE_FONT_SIZE, TITLE_COLOR, HORIZONTAL_ALIGNMENT_LEFT)

	var list_top: float = title_rect.end.y + 12.0

	var visible_count: int = max(max(_queue_items.size(), _capacity), EMPTY_ITEM_COUNT)
	var available_height: float = max(48.0, content_rect.end.y - list_top)
	var gap: float = 7.0
	var item_height: float = floor((available_height - gap * float(visible_count - 1)) / float(visible_count))
	item_height = clampf(item_height, 42.0, 58.0)
	var total_height: float = item_height * float(visible_count) + gap * float(visible_count - 1)
	var current_y: float = list_top + max(0.0, (available_height - total_height) * 0.5)

	for index in range(visible_count):
		var item_rect: Rect2 = Rect2(Vector2(content_rect.position.x, current_y), Vector2(content_rect.size.x, item_height))
		if index < _queue_items.size():
			_draw_queue_item(item_rect, _queue_items[index], index)
		else:
			_draw_empty_item(item_rect, index)
		current_y += item_height + gap

func _draw_queue_item(rect: Rect2, item: Dictionary, index: int) -> void:
	var fill_color: Color = PLAYER_ITEM_FILL if accent_mode == &"player" else ENEMY_ITEM_FILL
	var border_color: Color = PLAYER_ITEM_BORDER if accent_mode == &"player" else ENEMY_ITEM_BORDER
	var text_color: Color = TEXT_DARK
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	draw_style_box(style, rect)

	var badge_rect: Rect2 = Rect2(rect.position + Vector2(8, 8), Vector2(28, rect.size.y - 16))
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = Color(1, 1, 1, 0.22)
	badge_style.corner_radius_top_left = 8
	badge_style.corner_radius_top_right = 8
	badge_style.corner_radius_bottom_left = 8
	badge_style.corner_radius_bottom_right = 8
	draw_style_box(badge_style, badge_rect)
	_draw_text_line(badge_rect, str(index + 1), ITEM_NAME_FONT_SIZE, text_color, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

	var item_name: String = str(item.get("name", "食物块"))
	var meta: String = str(item.get("meta", ""))
	var body_x: float = badge_rect.end.x + 8.0
	var body_width: float = rect.end.x - body_x - 10.0
	var name_rect: Rect2 = Rect2(Vector2(body_x, rect.position.y + 7.0), Vector2(body_width, 20.0))
	_draw_text_line(name_rect, item_name, ITEM_NAME_FONT_SIZE, text_color, HORIZONTAL_ALIGNMENT_LEFT)
	if not meta.is_empty():
		var meta_rect: Rect2 = Rect2(Vector2(body_x, rect.position.y + rect.size.y - 22.0), Vector2(body_width, 16.0))
		_draw_text_line(meta_rect, meta, ITEM_META_FONT_SIZE, DIGESTION_COLOR if accent_mode == &"player" else TEXT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)

func _draw_empty_item(rect: Rect2, _index: int) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = EMPTY_SLOT_FILL
	style.border_color = EMPTY_SLOT_BORDER
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	draw_style_box(style, rect)

	_draw_text_line(rect, "空位", ITEM_META_FONT_SIZE, SUBTITLE_COLOR, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

func _draw_text_line(rect: Rect2, text: String, font_size: int, color: Color, alignment: HorizontalAlignment, vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null or text.is_empty():
		return
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var x: float = rect.position.x
	match alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			x += max(0.0, (rect.size.x - text_size.x) * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			x += max(0.0, rect.size.x - text_size.x)
	var y: float = rect.position.y
	match vertical_alignment:
		VERTICAL_ALIGNMENT_TOP:
			y += font_size
		VERTICAL_ALIGNMENT_BOTTOM:
			y += rect.size.y
		_:
			y += max(font_size, (rect.size.y + font_size) * 0.5 - 3.0)
	draw_string(font, Vector2(x, y), text, alignment, rect.size.x, font_size, color)
