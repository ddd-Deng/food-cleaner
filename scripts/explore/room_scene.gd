@tool
extends Control
class_name ExploreRoomScene

@export var fallback_room_tint: Color = Color.WHITE

func get_player_spawn_position(default_position: Vector2) -> Vector2:
	var anchors := _anchors_of_kind(&"player_spawn")
	if anchors.is_empty():
		return default_position
	return _anchor_center(anchors[0])

func _anchors_of_kind(kind: StringName) -> Array[RoomAnchor]:
	var matching: Array[RoomAnchor] = []
	for node in find_children("*", "RoomAnchor", true, false):
		if node is RoomAnchor and (node as RoomAnchor).anchor_kind == kind:
			matching.append(node as RoomAnchor)
	matching.sort_custom(func(a: RoomAnchor, b: RoomAnchor) -> bool:
		return a.anchor_order < b.anchor_order
	)
	return matching

func _anchor_center(anchor: RoomAnchor) -> Vector2:
	return anchor.position + anchor.size * 0.5
