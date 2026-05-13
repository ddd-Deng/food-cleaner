extends Node2D
class_name PlayerActor

const ANIMATION_ROOT := "res://sprites/主角动画_256x144"
const IDLE_FRONT_DIR := ANIMATION_ROOT + "/主角待机动画前"
const IDLE_SIDE_DIR := ANIMATION_ROOT + "/主角待机动画右"
const WALK_FRONT_DIR := ANIMATION_ROOT + "/走路动画前"
const WALK_SIDE_DIR := ANIMATION_ROOT + "/走路动画右"

enum FacingMode {
	FRONT,
	SIDE,
}

@export var move_speed: float = 260.0
@export var animation_fps: float = 12.0

var room_bounds: Rect2 = Rect2(0, 0, 960, 540)
var is_active: bool = true
var collision_size: Vector2 = Vector2(48, 48)
var _animation_sets: Dictionary = {}
var _facing_mode: FacingMode = FacingMode.FRONT
var _is_facing_left: bool = false

@onready var _animated_sprite: AnimatedSprite2D = AnimatedSprite2D.new()

func _ready() -> void:
	_configure_animated_sprite()
	_load_animation_sets()
	_apply_default_size()
	_update_animation_state(false)

func _process(delta: float) -> void:
	if not is_active:
		_update_animation_state(false)
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_moving := not direction.is_zero_approx()
	if is_moving:
		position += direction * move_speed * delta
		_clamp_to_room()
	_update_facing_from_direction(direction)
	_update_animation_state(is_moving)

func set_room_bounds(bounds: Rect2) -> void:
	room_bounds = bounds
	_clamp_to_room()

func center_in_room(bounds: Rect2) -> void:
	room_bounds = bounds
	position = room_bounds.position + room_bounds.size * 0.5
	_clamp_to_room()

func set_active(active: bool) -> void:
	is_active = active

func get_center_point() -> Vector2:
	return position

func get_collision_size() -> Vector2:
	return collision_size

func _configure_animated_sprite() -> void:
	_animated_sprite.centered = true
	add_child(_animated_sprite)

func _load_animation_sets() -> void:
	var sprite_frames := SpriteFrames.new()
	_animation_sets = {
		&"idle_front": _load_frames_from_directory(IDLE_FRONT_DIR),
		&"idle_side": _load_frames_from_directory(IDLE_SIDE_DIR),
		&"walk_front": _load_frames_from_directory(WALK_FRONT_DIR),
		&"walk_side": _load_frames_from_directory(WALK_SIDE_DIR),
	}
	for animation_name in _animation_sets.keys():
		sprite_frames.add_animation(String(animation_name))
		sprite_frames.set_animation_loop(String(animation_name), true)
		sprite_frames.set_animation_speed(String(animation_name), animation_fps)
		var frames: Array[Texture2D] = _animation_sets.get(animation_name, [])
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
	var frames: Array[Texture2D] = _animation_sets.get(&"idle_front", [])
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
		_facing_mode = FacingMode.FRONT

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
		return &"walk_side" if _facing_mode == FacingMode.SIDE else &"walk_front"
	return &"idle_side" if _facing_mode == FacingMode.SIDE else &"idle_front"

func _clamp_to_room() -> void:
	var half_size := collision_size * 0.5
	position.x = clampf(position.x, room_bounds.position.x + half_size.x, room_bounds.end.x - half_size.x)
	position.y = clampf(position.y, room_bounds.position.y + half_size.y, room_bounds.end.y - half_size.y)
