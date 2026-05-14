extends PanelContainer
class_name CardEffectPreviewPopup

const MAX_VISIBLE_RECORDS := 3
const DEFAULT_SIZE := Vector2(270, 118)
const VIEWPORT_PADDING := 12.0
const MARKER_GAP := 10.0

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
	if _title_label == null:
		_build_content()

	var time_point: int = records[0].time_point
	_title_label.text = "卡牌生效于 %dt" % time_point
	_content_label.text = _records_text(records)
	visible = true
	size = DEFAULT_SIZE
	_reposition_near_marker(marker_global_rect)

func hide_preview() -> void:
	visible = false

func _build_content() -> void:
	if _title_label != null:
		return
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.add_theme_color_override("font_color", Color(0.30, 0.21, 0.12, 1.0))
	column.add_child(_title_label)

	_content_label = Label.new()
	_content_label.add_theme_font_size_override("font_size", 12)
	_content_label.add_theme_color_override("font_color", Color(0.42, 0.31, 0.18, 1.0))
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_content_label)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.94, 0.78, 0.96)
	panel_style.border_color = Color(0.39, 0.24, 0.10, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", panel_style)

func _records_text(records: Array[CardEffectRecord]) -> String:
	var lines: PackedStringArray = []
	var visible_count: int = mini(records.size(), MAX_VISIBLE_RECORDS)
	for i in range(visible_count):
		var record: CardEffectRecord = records[i]
		lines.append("%s | %dt | %s" % [
			record.card_name,
			record.time_cost,
			record.effect_summary,
		])
	if records.size() > MAX_VISIBLE_RECORDS:
		lines.append("还有 %d 张..." % (records.size() - MAX_VISIBLE_RECORDS))
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
