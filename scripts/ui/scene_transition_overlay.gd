extends CanvasLayer
class_name SceneTransitionOverlay

signal midpoint_reached
signal transition_finished

const ANIMATION_DIR := "res://sprites/transitionAnimation"
const ANIMATION_NAME := &"transition"

@export var animation_fps: float = 30.0

@onready var overlay_root: Control = $OverlayRoot
@onready var animated_sprite: AnimatedSprite2D = $OverlayRoot/AnimatedSprite2D

var _is_transitioning: bool = false
var _midpoint_frame: int = 0
var _midpoint_emitted: bool = false

func _ready() -> void:
	layer = 100
	overlay_root.visible = false
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	animated_sprite.centered = true
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	overlay_root.resized.connect(_update_sprite_position)
	_load_frames()
	_update_sprite_position()

func play_transition() -> void:
	if _is_transitioning:
		return
	var frame_count := animated_sprite.sprite_frames.get_frame_count(ANIMATION_NAME) if animated_sprite.sprite_frames != null else 0
	if frame_count <= 0:
		_start_empty_transition()
		return
	_is_transitioning = true
	_midpoint_emitted = false
	@warning_ignore("integer_division")
	_midpoint_frame = max(0, frame_count / 2)
	overlay_root.visible = true
	overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	animated_sprite.stop()
	animated_sprite.frame = 0
	animated_sprite.play(ANIMATION_NAME)
	if _midpoint_frame <= 0:
		_midpoint_emitted = true
		midpoint_reached.emit()

func is_transitioning() -> bool:
	return _is_transitioning

func _load_frames() -> void:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(ANIMATION_NAME)
	sprite_frames.set_animation_loop(ANIMATION_NAME, false)
	sprite_frames.set_animation_speed(ANIMATION_NAME, animation_fps)

	var directory := DirAccess.open(ANIMATION_DIR)
	if directory == null:
		animated_sprite.sprite_frames = sprite_frames
		return

	var file_names: PackedStringArray = []
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
		var texture := load("%s/%s" % [ANIMATION_DIR, file_name]) as Texture2D
		if texture != null:
			sprite_frames.add_frame(ANIMATION_NAME, texture)

	animated_sprite.sprite_frames = sprite_frames

func _update_sprite_position() -> void:
	animated_sprite.position = overlay_root.size * 0.5

func _on_frame_changed() -> void:
	if not _is_transitioning or _midpoint_emitted:
		return
	if animated_sprite.frame >= _midpoint_frame:
		_midpoint_emitted = true
		midpoint_reached.emit()

func _on_animation_finished() -> void:
	if not _is_transitioning:
		return
	_finish_transition()

func _start_empty_transition() -> void:
	_is_transitioning = true
	overlay_root.visible = true
	overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	call_deferred("_emit_empty_transition_midpoint")

func _emit_empty_transition_midpoint() -> void:
	if not _is_transitioning:
		return
	midpoint_reached.emit()
	call_deferred("_finish_transition")

func _finish_transition() -> void:
	if not _is_transitioning:
		return
	_is_transitioning = false
	animated_sprite.stop()
	animated_sprite.frame = 0
	overlay_root.visible = false
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit()
