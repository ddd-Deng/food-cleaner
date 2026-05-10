extends Control

const BATTLE_SCENE: PackedScene = preload("res://scenes/battle/battle_scene.tscn")

func _ready() -> void:
	var battle_scene := BATTLE_SCENE.instantiate()
	add_child(battle_scene)
	if battle_scene is Control:
		(battle_scene as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
