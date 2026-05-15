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
	var sprite_frames := MonsterCatalog.get_animation_frames(
		directory_path,
		animation_fps if animation_fps > 0.0 else fallback_animation_fps
	)
	self.sprite_frames = sprite_frames
	if sprite_frames.get_frame_count("idle") > 0:
		play("idle")
