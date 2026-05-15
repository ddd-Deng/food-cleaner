extends RefCounted
class_name MonsterDefinition

var id: StringName = &""
var display_name: String = ""
var room_display_name: String = ""
var room_scene_path: String = ""
var explore_animation_dir: String = ""
var battle_animation_dir: String = ""
var animation_fps: float = 10.0
var outline_color: Color = Color(1.0, 0.95, 0.70, 1.0)
var outline_thickness: float = 3.0
var enemy_definition: EnemyData

func duplicate_enemy_definition() -> EnemyData:
	if enemy_definition == null:
		return null
	return enemy_definition.duplicate(true) as EnemyData
