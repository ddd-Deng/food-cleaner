@tool
extends Control
class_name ExploreRoomScene

@export var fallback_room_tint: Color = Color.WHITE

func get_feature_anchor_position(default_position: Vector2) -> Vector2:
	var anchors := _anchors_of_kind(&"feature")
	if anchors.is_empty():
		return default_position
	return _anchor_center(anchors[0])

func get_exit_anchor_positions(default_positions: Array) -> Array[Vector2]:
	var anchors := _anchors_of_kind(&"exit")
	if anchors.is_empty():
		var fallback_positions: Array[Vector2] = []
		for position_value in default_positions:
			if position_value is Vector2:
				fallback_positions.append(position_value)
		return fallback_positions
	var positions: Array[Vector2] = []
	for anchor in anchors:
		positions.append(_anchor_center(anchor))
	return positions

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
