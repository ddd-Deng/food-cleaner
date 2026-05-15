extends Control
class_name CardEffectPreviewPopup

const MAX_VISIBLE_RECORDS := 3
const DEFAULT_SIZE := Vector2(286, 170)
const VIEWPORT_PADDING := 12.0
const MARKER_GAP := 10.0
const HINT_BOX_TEXTURE: Texture2D = preload("res://sprites/提示框.png")
const HINT_BOX_REGION := Rect2(720, 107, 166, 168)

var _background: TextureRect
var _content_margin: MarginContainer
var _title_label: Label
var _content_label: Label

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = DEFAULT_SIZE
	_build_content()

func show_records(records: Array[CardEffectRecord], marker_global_rect: Rect2) -> void:
	if records.is_empty():
		hide_preview()
		return
	show_hint("卡牌生效于 %dt" % records[0].time_point, _records_text(records), marker_global_rect)

func show_hint(title_text: String, body_text: String, marker_global_rect: Rect2) -> void:
	if title_text.is_empty() and body_text.is_empty():
		hide_preview()
		return
	if _title_label == null:
		_build_content()

	_title_label.text = title_text
	_content_label.text = body_text
	visible = true
	size = DEFAULT_SIZE
	_reposition_near_marker(marker_global_rect)

func hide_preview() -> void:
	visible = false

func _build_content() -> void:
	if _title_label != null:
		return
	_background = TextureRect.new()
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.texture = _build_background_texture()
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_SCALE
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	_content_margin = MarginContainer.new()
	_content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_margin.add_theme_constant_override("margin_left", 18)
	_content_margin.add_theme_constant_override("margin_top", 20)
	_content_margin.add_theme_constant_override("margin_right", 18)
	_content_margin.add_theme_constant_override("margin_bottom", 20)
	add_child(_content_margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_content_margin.add_child(column)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.add_theme_font_size_override("font_size", 15)
	_title_label.add_theme_color_override("font_color", Color(0.28, 0.18, 0.09, 1.0))
	column.add_child(_title_label)

	_content_label = Label.new()
	_content_label.add_theme_font_size_override("font_size", 12)
	_content_label.add_theme_color_override("font_color", Color(0.38, 0.28, 0.15, 1.0))
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_content_label)

func _build_background_texture() -> Texture2D:
	var background_texture := AtlasTexture.new()
	background_texture.atlas = HINT_BOX_TEXTURE
	background_texture.region = HINT_BOX_REGION
	return background_texture

func _records_text(records: Array[CardEffectRecord]) -> String:
	var lines: PackedStringArray = []
	var visible_count: int = mini(records.size(), MAX_VISIBLE_RECORDS)
	for i in range(visible_count):
		var record: CardEffectRecord = records[i]
		lines.append("- %s | %dt | %s" % [
			record.card_name,
			record.time_cost,
			record.effect_summary,
		])
	if records.size() > MAX_VISIBLE_RECORDS:
		lines.append("还有 %d 条..." % (records.size() - MAX_VISIBLE_RECORDS))
	return "\n".join(lines)

func _reposition_near_marker(marker_global_rect: Rect2) -> void:
	var viewport_rect := get_viewport_rect()
	var desired_global_position := marker_global_rect.position + Vector2(marker_global_rect.size.x + MARKER_GAP, -DEFAULT_SIZE.y - MARKER_GAP)
	if desired_global_position.x + DEFAULT_SIZE.x > viewport_rect.size.x - VIEWPORT_PADDING:
		desired_global_position.x = marker_global_rect.position.x - DEFAULT_SIZE.x - MARKER_GAP
	if desired_global_position.y < VIEWPORT_PADDING:
		desired_global_position.y = marker_global_rect.position.y + marker_global_rect.size.y + MARKER_GAP
	desired_global_position.x = clampf(desired_global_position.x, VIEWPORT_PADDING, viewport_rect.size.x - DEFAULT_SIZE.x - VIEWPORT_PADDING)
	desired_global_position.y = clampf(desired_global_position.y, VIEWPORT_PADDING, viewport_rect.size.y - DEFAULT_SIZE.y - VIEWPORT_PADDING)
	global_position = desired_global_position
