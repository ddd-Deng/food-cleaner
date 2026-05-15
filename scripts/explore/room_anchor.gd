@tool
extends ColorRect
class_name RoomAnchor

@export var anchor_kind: StringName = &"feature"
@export var anchor_order: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(96, 44)
	if size == Vector2.ZERO:
		size = custom_minimum_size
	_apply_editor_visual()
	if not Engine.is_editor_hint():
		visible = false

func _apply_editor_visual() -> void:
	if not Engine.is_editor_hint():
		return
	match anchor_kind:
		&"feature":
			color = Color(0.97, 0.72, 0.31, 0.55)
		&"exit":
			color = Color(0.43, 0.79, 0.95, 0.55)
		&"player_spawn":
			color = Color(0.41, 0.84, 0.56, 0.55)
		_:
			color = Color(0.82, 0.82, 0.82, 0.45)
