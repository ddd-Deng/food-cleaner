extends AnimatedSprite2D
class_name BattlePlayerSprite

const IDLE_SIDE_DIR := "res://sprites/主角动画_256x144/主角待机动画右"
const ATTACK_FRONT_DIR := "res://sprites/主角动画_256x144/攻击_前"
const ATTACK_BACK_DIR := "res://sprites/主角动画_256x144/攻击_后"
const IDLE_ANIMATION: StringName = &"idle_right"
const ATTACK_FRONT_ANIMATION: StringName = &"attack_front"
const ATTACK_BACK_ANIMATION: StringName = &"attack_back"

enum PlaybackState {
	IDLE,
	ATTACK_FRONT,
	ATTACK_BACK,
}

@export var animation_fps: float = 12.0

var _playback_state: int = PlaybackState.IDLE

func _ready() -> void:
	centered = true
	animation_finished.connect(_on_animation_finished)
	_load_animations()
	_play_idle_animation()

func play_attack_animation() -> void:
	_play_attack_phase(ATTACK_FRONT_ANIMATION, PlaybackState.ATTACK_FRONT)

func _load_animations() -> void:
	var frames := SpriteFrames.new()
	_register_animation(frames, IDLE_ANIMATION, IDLE_SIDE_DIR, true)
	_register_animation(frames, ATTACK_FRONT_ANIMATION, ATTACK_FRONT_DIR, false)
	_register_animation(frames, ATTACK_BACK_ANIMATION, ATTACK_BACK_DIR, false)

	self.sprite_frames = frames

func _register_animation(frames: SpriteFrames, animation_id: StringName, directory_path: String, loop: bool) -> void:
	var animation_name := String(animation_id)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, animation_fps)

	for texture in _load_frames_from_directory(directory_path):
		if texture != null:
			frames.add_frame(animation_name, texture)

func _play_idle_animation() -> void:
	_playback_state = PlaybackState.IDLE
	_play_animation_from_start(IDLE_ANIMATION)

func _play_attack_phase(animation_id: StringName, playback_state: int) -> void:
	_playback_state = playback_state
	_play_animation_from_start(animation_id)

func _play_animation_from_start(animation_id: StringName) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(String(animation_id)):
		return
	stop()
	play(animation_id)
	set_frame_and_progress(0, 0.0)

func _on_animation_finished() -> void:
	match _playback_state:
		PlaybackState.ATTACK_FRONT:
			_play_attack_phase(ATTACK_BACK_ANIMATION, PlaybackState.ATTACK_BACK)
		PlaybackState.ATTACK_BACK:
			_play_idle_animation()
		_:
			pass

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
