extends AnimatedSprite2D
class_name BattleEnemySprite

@export var fallback_animation_fps: float = 10.0

func _ready() -> void:
	centered = true

func setup_from_monster(monster_id: StringName) -> void:
	var definition := MonsterCatalog.get_monster_definition(monster_id)
	if definition == null:
		hide()
		return
	show()
	_load_animation(definition.battle_animation_dir, definition.animation_fps)

func _load_animation(directory_path: String, animation_fps: float) -> void:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", animation_fps if animation_fps > 0.0 else fallback_animation_fps)
	for texture in _load_frames_from_directory(directory_path):
		if texture != null:
			sprite_frames.add_frame("idle", texture)
	self.sprite_frames = sprite_frames
	if sprite_frames.get_frame_count("idle") > 0:
		play("idle")

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
