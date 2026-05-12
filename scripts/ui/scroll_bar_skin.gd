extends RefCounted
class_name ScrollBarSkin

const TRACK_TEXTURE: Texture2D = preload("res://sprites/滚动条/滚动条的条.png")
const GRABBER_TEXTURE: Texture2D = preload("res://sprites/滚动条/滚动条的滚轮.png")

const TRACK_REGION := Rect2(1095, 119, 17, 481)
const GRABBER_REGION := Rect2(1092, 135, 24, 40)

const TRACK_SLICE := 8.0
const GRABBER_SLICE := 10.0
const TRACK_THICKNESS := 17.0
const GRABBER_THICKNESS := 24.0
const CONTENT_SEPARATION := 8
const TRACK_PADDING := 4
const TIMELINE_SCROLLBAR_THICKNESS := 14.0
const TIMELINE_SCROLLBAR_SEPARATION := 2

static var _empty_texture: Texture2D
static var _vertical_track_texture: Texture2D
static var _horizontal_track_texture: Texture2D
static var _vertical_grabber_texture: Texture2D
static var _horizontal_grabber_texture: Texture2D

static func apply_to_scroll_container(scroll_container: ScrollContainer, separation: int = CONTENT_SEPARATION) -> void:
	if scroll_container == null:
		return
	scroll_container.add_theme_constant_override("scrollbar_h_separation", separation)
	scroll_container.add_theme_constant_override("scrollbar_v_separation", separation)
	_apply_to_scroll_bar(scroll_container.get_v_scroll_bar(), true)
	_apply_to_scroll_bar(scroll_container.get_h_scroll_bar(), false)

static func apply_compact_horizontal_to_scroll_container(scroll_container: ScrollContainer) -> void:
	if scroll_container == null:
		return
	scroll_container.add_theme_constant_override("scrollbar_h_separation", TIMELINE_SCROLLBAR_SEPARATION)
	_apply_to_scroll_bar(scroll_container.get_h_scroll_bar(), false, TIMELINE_SCROLLBAR_THICKNESS)

static func apply_to_rich_text_label(rich_text_label: RichTextLabel) -> void:
	if rich_text_label == null:
		return
	_apply_to_scroll_bar(rich_text_label.get_v_scroll_bar(), true)

static func apply_to_scroll_bar(scroll_bar: ScrollBar) -> void:
	if scroll_bar == null:
		return
	_apply_to_scroll_bar(scroll_bar, scroll_bar is VScrollBar)

static func _apply_to_scroll_bar(scroll_bar: ScrollBar, is_vertical: bool, custom_thickness: float = -1.0) -> void:
	if scroll_bar == null:
		return
	scroll_bar.focus_mode = Control.FOCUS_NONE
	scroll_bar.add_theme_stylebox_override("scroll", _make_track_stylebox(is_vertical))
	scroll_bar.add_theme_stylebox_override("scroll_focus", _make_track_stylebox(is_vertical))
	scroll_bar.add_theme_stylebox_override("grabber", _make_grabber_stylebox(is_vertical, Color.WHITE))
	scroll_bar.add_theme_stylebox_override("grabber_highlight", _make_grabber_stylebox(is_vertical, Color(1.07, 1.07, 1.07, 1.0)))
	scroll_bar.add_theme_stylebox_override("grabber_pressed", _make_grabber_stylebox(is_vertical, Color(0.9, 0.96, 0.94, 1.0)))
	_apply_arrow_overrides(scroll_bar)

	var thickness := custom_thickness if custom_thickness > 0.0 else GRABBER_THICKNESS + TRACK_PADDING * 2.0
	if is_vertical:
		scroll_bar.custom_minimum_size.x = thickness
		scroll_bar.add_theme_constant_override("padding_left", TRACK_PADDING)
		scroll_bar.add_theme_constant_override("padding_right", TRACK_PADDING)
	else:
		scroll_bar.custom_minimum_size.y = thickness
		scroll_bar.add_theme_constant_override("padding_top", TRACK_PADDING)
		scroll_bar.add_theme_constant_override("padding_bottom", TRACK_PADDING)

static func _make_track_stylebox(is_vertical: bool) -> StyleBoxTexture:
	var style_box := StyleBoxTexture.new()
	style_box.texture = _get_track_texture(is_vertical)
	style_box.draw_center = true
	style_box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style_box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style_box.set_texture_margin_all(TRACK_SLICE)
	if is_vertical:
		style_box.content_margin_left = TRACK_THICKNESS * 0.5
		style_box.content_margin_right = TRACK_THICKNESS * 0.5
		style_box.content_margin_top = TRACK_PADDING
		style_box.content_margin_bottom = TRACK_PADDING
	else:
		style_box.content_margin_left = TRACK_PADDING
		style_box.content_margin_right = TRACK_PADDING
		style_box.content_margin_top = TRACK_THICKNESS * 0.5
		style_box.content_margin_bottom = TRACK_THICKNESS * 0.5
	return style_box

static func _make_grabber_stylebox(is_vertical: bool, modulate_color: Color) -> StyleBoxTexture:
	var style_box := StyleBoxTexture.new()
	style_box.texture = _get_grabber_texture(is_vertical)
	style_box.draw_center = true
	style_box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style_box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style_box.set_texture_margin_all(GRABBER_SLICE)
	style_box.modulate_color = modulate_color
	return style_box

static func _apply_arrow_overrides(scroll_bar: ScrollBar) -> void:
	var empty_texture := _get_empty_texture()
	scroll_bar.add_theme_icon_override("decrement", empty_texture)
	scroll_bar.add_theme_icon_override("decrement_highlight", empty_texture)
	scroll_bar.add_theme_icon_override("decrement_pressed", empty_texture)
	scroll_bar.add_theme_icon_override("increment", empty_texture)
	scroll_bar.add_theme_icon_override("increment_highlight", empty_texture)
	scroll_bar.add_theme_icon_override("increment_pressed", empty_texture)

static func _get_track_texture(is_vertical: bool) -> Texture2D:
	if is_vertical:
		if _vertical_track_texture == null:
			_vertical_track_texture = _make_atlas_texture(TRACK_TEXTURE, TRACK_REGION)
		return _vertical_track_texture
	if _horizontal_track_texture == null:
		_horizontal_track_texture = _make_rotated_region_texture(TRACK_TEXTURE, TRACK_REGION)
	return _horizontal_track_texture

static func _get_grabber_texture(is_vertical: bool) -> Texture2D:
	if is_vertical:
		if _vertical_grabber_texture == null:
			_vertical_grabber_texture = _make_atlas_texture(GRABBER_TEXTURE, GRABBER_REGION)
		return _vertical_grabber_texture
	if _horizontal_grabber_texture == null:
		_horizontal_grabber_texture = _make_rotated_region_texture(GRABBER_TEXTURE, GRABBER_REGION)
	return _horizontal_grabber_texture

static func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = texture
	atlas_texture.region = region
	return atlas_texture

static func _make_rotated_region_texture(texture: Texture2D, region: Rect2) -> Texture2D:
	var source_image := texture.get_image()
	if source_image == null:
		return texture
	var region_i := Rect2i(region.position, region.size)
	var cropped_image := Image.create_empty(region_i.size.x, region_i.size.y, false, source_image.get_format())
	cropped_image.blit_rect(source_image, region_i, Vector2i.ZERO)
	return ImageTexture.create_from_image(_rotate_image_clockwise(cropped_image))

static func _rotate_image_clockwise(image: Image) -> Image:
	if image == null:
		return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	if width <= 1 or height <= 1:
		return image
	var rotated := Image.create_empty(height, width, false, image.get_format())
	for y in range(height):
		for x in range(width):
			rotated.set_pixel(height - 1 - y, x, image.get_pixel(x, y))
	return rotated

static func _get_empty_texture() -> Texture2D:
	if _empty_texture != null:
		return _empty_texture
	var empty_image := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color(0, 0, 0, 0))
	_empty_texture = ImageTexture.create_from_image(empty_image)
	return _empty_texture
