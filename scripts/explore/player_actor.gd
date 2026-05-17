extends CharacterBody2D
class_name PlayerActor

const ANIMATION_ROOT := "res://sprites/主角动画_256x144"
const IDLE_FRONT_DIR := ANIMATION_ROOT + "/主角待机动画前"
const IDLE_BACK_DIR := ANIMATION_ROOT + "/主角待机动画后"
const IDLE_SIDE_DIR := ANIMATION_ROOT + "/主角待机动画右"
const WALK_FRONT_DIR := ANIMATION_ROOT + "/走路动画前"
const WALK_BACK_DIR := ANIMATION_ROOT + "/走路动画后"
const WALK_SIDE_DIR := ANIMATION_ROOT + "/走路动画右"
const OUTLINE_SHADER := preload("res://shaders/player_outline.gdshader")

enum FacingMode {
	FRONT,
	BACK,
	SIDE,
}

@export var move_speed: float = 260.0
@export var animation_fps: float = 12.0
@export var interaction_radius: float = 90.0
@export var body_collision_size: Vector2 = Vector2(40, 28)
@export var outline_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		_outline_color = value
		_update_outline_material()
@export_range(0.0, 12.0, 0.1) var outline_thickness: float = 2.0:
	set(value):
		_outline_thickness = value
		_update_outline_material()

var is_active: bool = true
var collision_size: Vector2 = Vector2(48, 48)
var _animation_sets: Dictionary = {}
var _facing_mode: FacingMode = FacingMode.FRONT
var _is_facing_left: bool = false
var _outline_material: ShaderMaterial
var _outline_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _outline_thickness: float = 2.0

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $BodyCollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/CollisionShape2D

func _ready() -> void:
	_load_animation_sets()
	_apply_default_size()
	_configure_body_collision()
	_configure_interaction_area()
	_configure_outline_material()
	_update_animation_state(false)

func _process(delta: float) -> void:
	if not is_active:
		velocity = Vector2.ZERO
		_update_animation_state(false)
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_moving := not direction.is_zero_approx()
	velocity = direction * move_speed
	move_and_slide()
	_update_facing_from_direction(direction)
	_update_animation_state(is_moving)

func set_active(active: bool) -> void:
	is_active = active
	if not is_active:
		velocity = Vector2.ZERO

func get_center_point() -> Vector2:
	return position

func get_collision_size() -> Vector2:
	return collision_size

func get_interaction_area() -> Area2D:
	return interaction_area

func _configure_animated_sprite() -> void:
	if _animated_sprite != null:
		_animated_sprite.centered = true

func _configure_body_collision() -> void:
	if body_shape == null:
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = body_collision_size
	body_shape.shape = rectangle

func _configure_outline_material() -> void:
	if _animated_sprite == null:
		return
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = OUTLINE_SHADER
	_animated_sprite.material = _outline_material
	_update_outline_material()

func _configure_interaction_area() -> void:
	if interaction_area == null or interaction_shape == null:
		return
	interaction_area.monitoring = true
	interaction_area.monitorable = false
	interaction_shape.position = Vector2.ZERO
	var circle := CircleShape2D.new()
	circle.radius = interaction_radius
	interaction_shape.shape = circle

func _load_animation_sets() -> void:
	var sprite_frames := SpriteFrames.new()
	_animation_sets = {
		&"idle_front": _load_frames_from_directory(IDLE_FRONT_DIR),
		&"idle_back": _load_frames_from_directory(IDLE_BACK_DIR),
		&"idle_side": _load_frames_from_directory(IDLE_SIDE_DIR),
		&"walk_front": _load_frames_from_directory(WALK_FRONT_DIR),
		&"walk_back": _load_frames_from_directory(WALK_BACK_DIR),
		&"walk_side": _load_frames_from_directory(WALK_SIDE_DIR),
	}
	for animation_name in _animation_sets.keys():
		sprite_frames.add_animation(String(animation_name))
		sprite_frames.set_animation_loop(String(animation_name), true)
		sprite_frames.set_animation_speed(String(animation_name), animation_fps)
		var frames: Array[Texture2D] = []
		var raw_frames: Variant = _animation_sets.get(animation_name, [])
		if raw_frames is Array:
			for frame_variant in raw_frames:
				if frame_variant is Texture2D:
					frames.append(frame_variant)
		for frame in frames:
			if frame != null:
				sprite_frames.add_frame(String(animation_name), frame)
	_animated_sprite.sprite_frames = sprite_frames

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
		var texture := _load_texture_from_source_file("%s/%s" % [directory_path, file_name])
		if texture != null:
			frames.append(texture)
	return frames

func _load_texture_from_source_file(resource_path: String) -> Texture2D:
	var global_path := ProjectSettings.globalize_path(resource_path)
	if not FileAccess.file_exists(global_path):
		return null
	var image := Image.load_from_file(global_path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)

func _apply_default_size() -> void:
	var frames: Array[Texture2D] = []
	var raw_frames: Variant = _animation_sets.get(&"idle_front", [])
	if raw_frames is Array:
		for frame_variant in raw_frames:
			if frame_variant is Texture2D:
				frames.append(frame_variant)
	if frames.is_empty():
		collision_size = Vector2(48, 48)
		return
	collision_size = frames[0].get_size()

func _update_facing_from_direction(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	if absf(direction.x) > absf(direction.y):
		_facing_mode = FacingMode.SIDE
		_is_facing_left = direction.x < 0.0
	else:
		_facing_mode = FacingMode.BACK if direction.y < 0.0 else FacingMode.FRONT

func _update_animation_state(is_moving: bool) -> void:
	var animation_name := _animation_name_for_state(is_moving)
	if _animated_sprite.sprite_frames == null or not _animated_sprite.sprite_frames.has_animation(animation_name):
		return
	_animated_sprite.flip_h = _facing_mode == FacingMode.SIDE and _is_facing_left
	_animated_sprite.sprite_frames.set_animation_speed(animation_name, animation_fps)
	if _animated_sprite.animation != animation_name:
		_animated_sprite.play(animation_name)
	elif not _animated_sprite.is_playing():
		_animated_sprite.play()

func _animation_name_for_state(is_moving: bool) -> StringName:
	if is_moving:
		match _facing_mode:
			FacingMode.SIDE:
				return &"walk_side"
			FacingMode.BACK:
				return &"walk_back"
			_:
				return &"walk_front"
	match _facing_mode:
		FacingMode.SIDE:
			return &"idle_side"
		FacingMode.BACK:
			return &"idle_back"
		_:
			return &"idle_front"

func _update_outline_material() -> void:
	if _outline_material == null:
		return
	_outline_material.set_shader_parameter("outline_color", _outline_color)
	_outline_material.set_shader_parameter("outline_thickness", _outline_thickness)
