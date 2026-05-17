extends Control
class_name TitleScreen

const EYE_MAX_OFFSET := 50.0
const BEFORE_START_DIR := "res://sprites/标题界面/before_start"
const BEFORE_START_ANIMATION := &"before_start"
const BEFORE_START_FPS := 30.0
const TRANSITION_DIR := "res://sprites/transitionAnimation"
const TRANSITION_ANIMATION := &"transition"
const TRANSITION_FPS := 30.0

@onready var eye_1: Control = $Eye1
@onready var eye_2: Control = $Eye2
@onready var before_start_sprite: AnimatedSprite2D = $BeforeStartLayer/BeforeStartSprite
@onready var transition_sprite: AnimatedSprite2D = $TransitionLayer/TransitionSprite

var _eye_1_origin: Vector2
var _eye_2_origin: Vector2
var _transition_half_hidden: bool = false


func _ready() -> void:
	_eye_1_origin = eye_1.position
	_eye_2_origin = eye_2.position
	_setup_transition_animation()
	_setup_before_start_animation()
	_update_eye_offsets()


func _process(_delta: float) -> void:
	_update_eye_offsets()


func _update_eye_offsets() -> void:
	var viewport_rect: Rect2 = get_viewport_rect()
	var viewport_size: Vector2 = viewport_rect.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var viewport_center: Vector2 = viewport_size * 0.5
	var mouse_vector: Vector2 = get_global_mouse_position() - viewport_center
	var screen_radius: float = minf(viewport_size.x, viewport_size.y) * 0.5
	var offset_ratio: float = 0.0 if screen_radius <= 0.0 else minf(mouse_vector.length() / screen_radius, 1.0)
	var offset: Vector2 = Vector2.ZERO if mouse_vector.is_zero_approx() else mouse_vector.normalized() * EYE_MAX_OFFSET * offset_ratio
	eye_1.position = _eye_1_origin + offset
	eye_2.position = _eye_2_origin + offset


func _setup_before_start_animation() -> void:
	var sprite_frames: SpriteFrames = _build_sprite_frames_from_directory(BEFORE_START_DIR, BEFORE_START_ANIMATION, BEFORE_START_FPS, false)
	if sprite_frames == null:
		before_start_sprite.visible = false
		return
	before_start_sprite.sprite_frames = sprite_frames
	before_start_sprite.animation_finished.connect(_on_before_start_animation_finished)
	if sprite_frames.get_frame_count(BEFORE_START_ANIMATION) <= 0:
		before_start_sprite.visible = false
		return
	before_start_sprite.visible = true
	before_start_sprite.play(BEFORE_START_ANIMATION)


func _setup_transition_animation() -> void:
	var sprite_frames: SpriteFrames = _build_sprite_frames_from_directory(TRANSITION_DIR, TRANSITION_ANIMATION, TRANSITION_FPS, false)
	if sprite_frames == null:
		transition_sprite.visible = false
		return
	transition_sprite.sprite_frames = sprite_frames
	transition_sprite.frame_changed.connect(_on_transition_frame_changed)
	transition_sprite.animation_finished.connect(_on_transition_animation_finished)
	transition_sprite.visible = false


func _build_sprite_frames_from_directory(
	directory_path: String,
	animation_name: StringName,
	animation_fps: float,
	loop: bool
) -> SpriteFrames:
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, loop)
	sprite_frames.set_animation_speed(animation_name, animation_fps)
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return null
	var file_names: PackedStringArray = []
	directory.list_dir_begin()
	while true:
		var file_name: String = directory.get_next()
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
		var texture: Texture2D = load("%s/%s" % [directory_path, file_name]) as Texture2D
		if texture != null:
			sprite_frames.add_frame(animation_name, texture)
	return sprite_frames


func _on_before_start_animation_finished() -> void:
	if before_start_sprite.animation != BEFORE_START_ANIMATION:
		return
	before_start_sprite.stop()
	var last_frame_index: int = before_start_sprite.sprite_frames.get_frame_count(BEFORE_START_ANIMATION) - 1
	before_start_sprite.frame = max(last_frame_index, 0)
	if transition_sprite.sprite_frames == null or transition_sprite.sprite_frames.get_frame_count(TRANSITION_ANIMATION) <= 0:
		before_start_sprite.visible = false
		return
	_transition_half_hidden = false
	transition_sprite.visible = true
	transition_sprite.play(TRANSITION_ANIMATION)


func _on_transition_frame_changed() -> void:
	if transition_sprite.animation != TRANSITION_ANIMATION or _transition_half_hidden:
		return
	var frame_count: int = transition_sprite.sprite_frames.get_frame_count(TRANSITION_ANIMATION)
	if frame_count <= 0:
		return
	var midpoint_frame: int = maxi(0, frame_count / 2)
	if transition_sprite.frame >= midpoint_frame:
		_transition_half_hidden = true
		before_start_sprite.visible = false


func _on_transition_animation_finished() -> void:
	if transition_sprite.animation != TRANSITION_ANIMATION:
		return
	transition_sprite.visible = false
	before_start_sprite.visible = false
