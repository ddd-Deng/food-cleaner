@tool
extends ExploreInteractable
class_name MonsterEncounter

const OUTLINE_SHADER := preload("res://shaders/sprite_outline.gdshader")

@export var monster_id: StringName = &"":
	set(value):
		_monster_id = value
		_refresh_editor_preview()
@export var animation_fps: float = 10.0:
	set(value):
		_animation_fps = value
		_refresh_editor_preview()
@export var sprite_scale: Vector2 = Vector2.ONE:
	set(value):
		_sprite_scale = value
		if animated_sprite != null:
			animated_sprite.scale = _sprite_scale
@export var outline_color: Color = Color(1.0, 0.95, 0.72, 1.0):
	set(value):
		_outline_color = value
		_update_outline_material(_is_highlighted)
@export_range(0.0, 12.0, 0.1) var outline_thickness: float = 4.0:
	set(value):
		_outline_thickness = value
		_update_outline_material(_is_highlighted)

var _sprite_material: ShaderMaterial
var _monster_id: StringName = &""
var _animation_fps: float = 10.0
var _sprite_scale: Vector2 = Vector2.ONE
var _outline_color: Color = Color(1.0, 0.95, 0.72, 1.0)
var _outline_thickness: float = 4.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_base_fill = Color(0.0, 0.0, 0.0, 0.0)
	_highlight_fill = Color(0.0, 0.0, 0.0, 0.0)
	_base_outline = Color(0.0, 0.0, 0.0, 0.0)
	_highlight_outline = Color(0.0, 0.0, 0.0, 0.0)
	super._ready()
	_area_size = Vector2(220, 180)
	_apply_monster_definition()
	_refresh_visual()

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_refresh_editor_preview")

func set_highlighted(highlighted: bool) -> void:
	super.set_highlighted(highlighted)
	if _sprite_material == null:
		return
	_sprite_material.set_shader_parameter("outline_enabled", highlighted)

func configure_monster(new_monster_id: StringName) -> void:
	_monster_id = new_monster_id
	if is_node_ready():
		_apply_monster_definition()

func _configure_label() -> void:
	super._configure_label()
	label.visible = false

func _ensure_sprite_material() -> void:
	if animated_sprite == null:
		return
	if _sprite_material != null and animated_sprite.material == _sprite_material:
		return
	animated_sprite.centered = true
	animated_sprite.scale = _sprite_scale
	_sprite_material = ShaderMaterial.new()
	_sprite_material.shader = OUTLINE_SHADER
	animated_sprite.material = _sprite_material
	_update_outline_material(false)

func _apply_monster_definition() -> void:
	_ensure_sprite_material()
	var definition := MonsterCatalog.get_monster_definition(_monster_id)
	if definition == null:
		return
	_display_name = definition.display_name
	prompt_text = "发起战斗"
	interactable_kind = &"encounter"
	_animation_fps = definition.animation_fps
	_outline_color = definition.outline_color
	_outline_thickness = definition.outline_thickness
	payload["monster_id"] = definition.id
	_load_animation(definition.explore_animation_dir)
	animated_sprite.scale = _sprite_scale
	animated_sprite.visible = true
	_update_outline_material(_is_highlighted)

func _refresh_editor_preview() -> void:
	if not is_node_ready():
		return
	_apply_monster_definition()
	_refresh_shape()

func _load_animation(directory_path: String) -> void:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", _animation_fps)
	for texture in _load_frames_from_directory(directory_path):
		if texture != null:
			sprite_frames.add_frame("idle", texture)
	animated_sprite.sprite_frames = sprite_frames
	if sprite_frames.get_frame_count("idle") > 0:
		animated_sprite.visible = true
		animated_sprite.play("idle")

func _load_frames_from_directory(directory_path: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var file_names: PackedStringArray = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return frames
	directory.list_dir_begin()
	while true:
		var file_name := directory.get_next()
		if file_name.is_empty():
			break
		if directory.current_is_dir():
			continue
		if not file_name.to_lower().ends_with(".png"):
			continue
		file_names.append(file_name)
	directory.list_dir_end()
	file_names.sort()
	for file_name in file_names:
		var resource_path := "%s/%s" % [directory_path, file_name]
		var global_path := ProjectSettings.globalize_path(resource_path)
		if not FileAccess.file_exists(global_path):
			continue
		var image := Image.load_from_file(global_path)
		if image == null:
			continue
		frames.append(ImageTexture.create_from_image(image))
	return frames

func _update_outline_material(highlighted: bool) -> void:
	if _sprite_material == null:
		return
	_sprite_material.set_shader_parameter("outline_color", _outline_color)
	_sprite_material.set_shader_parameter("outline_thickness", _outline_thickness)
	_sprite_material.set_shader_parameter("outline_enabled", highlighted)
