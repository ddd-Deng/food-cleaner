@tool
extends ExploreInteractable
class_name MonsterEncounter

const OUTLINE_SHADER := preload("res://shaders/sprite_outline.gdshader")

@export var monster_id: StringName = &""
@export var animation_fps: float = 10.0
@export var sprite_scale: Vector2 = Vector2.ONE
@export var outline_color: Color = Color(1.0, 0.95, 0.72, 1.0)
@export_range(0.0, 12.0, 0.1) var outline_thickness: float = 4.0

var _sprite_material: ShaderMaterial

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_base_fill = Color(0.0, 0.0, 0.0, 0.0)
	_highlight_fill = Color(0.0, 0.0, 0.0, 0.0)
	_base_outline = Color(0.0, 0.0, 0.0, 0.0)
	_highlight_outline = Color(0.0, 0.0, 0.0, 0.0)
	area_size = Vector2(220, 180)
	super._ready()
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
	monster_id = new_monster_id
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
	animated_sprite.scale = sprite_scale
	_sprite_material = ShaderMaterial.new()
	_sprite_material.shader = OUTLINE_SHADER
	animated_sprite.material = _sprite_material
	_update_outline_material(false)

func _apply_monster_definition() -> void:
	_ensure_sprite_material()
	var definition := MonsterCatalog.get_monster_definition(monster_id)
	if definition == null:
		return
	display_name = definition.display_name
	prompt_text = "发起战斗"
	interactable_kind = &"encounter"
	animation_fps = definition.animation_fps
	outline_color = definition.outline_color
	outline_thickness = definition.outline_thickness
	payload["monster_id"] = definition.id
	_load_animation(definition.explore_animation_dir)
	animated_sprite.scale = sprite_scale
	animated_sprite.visible = true
	_update_outline_material(_is_highlighted)

func _refresh_editor_preview() -> void:
	if not is_node_ready():
		return
	_apply_monster_definition()
	_refresh_shape()

func _load_animation(directory_path: String) -> void:
	var sprite_frames := MonsterCatalog.get_animation_frames(directory_path, animation_fps)
	animated_sprite.sprite_frames = sprite_frames
	if sprite_frames.get_frame_count("idle") > 0:
		animated_sprite.visible = true
		animated_sprite.play("idle")

func _update_outline_material(highlighted: bool) -> void:
	if _sprite_material == null:
		return
	_sprite_material.set_shader_parameter("outline_color", outline_color)
	_sprite_material.set_shader_parameter("outline_thickness", outline_thickness)
	_sprite_material.set_shader_parameter("outline_enabled", highlighted)
