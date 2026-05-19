extends AnimatedSprite2D
class_name BattleEnemySprite

@export var fallback_animation_fps: float = 10.0

var _intent_anchor: Node2D
var _intent_panel: PanelContainer
var _intent_label: Label

func _ready() -> void:
	centered = true
	_ensure_intent_ui()

func setup_from_monster(monster_id: StringName) -> void:
	var definition := MonsterCatalog.get_monster_definition(monster_id)
	if definition == null:
		_set_intent_text("")
		hide()
		return
	show()
	_load_animation(definition.battle_animation_dir, definition.animation_fps)

func set_intent_text(intent_text: String) -> void:
	_ensure_intent_ui()
	_set_intent_text(intent_text)

func _load_animation(directory_path: String, animation_fps: float) -> void:
	var loaded_frames := MonsterCatalog.get_animation_frames(
		directory_path,
		animation_fps if animation_fps > 0.0 else fallback_animation_fps
	)
	self.sprite_frames = loaded_frames
	if loaded_frames.get_frame_count("idle") > 0:
		play("idle")

func _ensure_intent_ui() -> void:
	if _intent_anchor != null:
		return
	_intent_anchor = Node2D.new()
	_intent_anchor.name = "IntentAnchor"
	_intent_anchor.position = Vector2(0.0, -124.0)
	add_child(_intent_anchor)

	_intent_panel = PanelContainer.new()
	_intent_panel.name = "IntentPanel"
	_intent_panel.visible = false
	_intent_panel.z_as_relative = false
	_intent_panel.z_index = 20
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.96, 0.91, 0.77, 0.95)
	panel_style.border_color = Color(0.56, 0.38, 0.19, 0.92)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.content_margin_left = 14.0
	panel_style.content_margin_top = 7.0
	panel_style.content_margin_right = 14.0
	panel_style.content_margin_bottom = 7.0
	panel_style.shadow_color = Color(0, 0, 0, 0.14)
	panel_style.shadow_size = 4
	_intent_panel.add_theme_stylebox_override("panel", panel_style)
	_intent_anchor.add_child(_intent_panel)

	_intent_label = Label.new()
	_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intent_label.add_theme_font_size_override("font_size", 16)
	_intent_label.add_theme_color_override("font_color", Color(0.24, 0.15, 0.06, 1.0))
	_intent_label.add_theme_color_override("font_outline_color", Color(1.0, 0.97, 0.90, 0.70))
	_intent_label.add_theme_constant_override("outline_size", 1)
	_intent_panel.add_child(_intent_label)

func _set_intent_text(intent_text: String) -> void:
	if _intent_panel == null or _intent_label == null:
		return
	var clean_text := intent_text.strip_edges()
	_intent_panel.visible = not clean_text.is_empty()
	if clean_text.is_empty():
		return
	_intent_label.text = clean_text
	_refresh_intent_panel_layout()

func _refresh_intent_panel_layout() -> void:
	if _intent_panel == null or _intent_label == null:
		return
	var font: Font = _intent_label.get_theme_font("font")
	var font_size: int = _intent_label.get_theme_font_size("font_size")
	var intent_text: String = _intent_label.text
	var text_size: Vector2 = font.get_string_size(intent_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size) if font != null else Vector2(96.0, 20.0)
	var panel_width: float = maxf(108.0, text_size.x + 28.0)
	var panel_height: float = 38.0
	var panel_size: Vector2 = Vector2(panel_width, panel_height)
	_intent_panel.custom_minimum_size = panel_size
	_intent_panel.size = panel_size
	_intent_panel.position = Vector2(-panel_size.x * 0.5, -panel_size.y * 0.5)
	_intent_label.position = Vector2.ZERO
	_intent_label.custom_minimum_size = Vector2(panel_width - 20.0, 22.0)
