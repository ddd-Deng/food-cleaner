extends RefCounted
class_name MapGenerator

static func build_demo_rooms() -> Dictionary:
	var rooms: Dictionary = {}

	var start_room := RoomRuntimeData.new()
	start_room.id = &"start"
	start_room.display_name = "入口前厅"
	start_room.room_type = MapTypes.RoomType.START
	start_room.scene_path = "res://scenes/rooms/start_room.tscn"
	start_room.linked_room_ids = [&"marshmallow_room", &"candy_bean_room", &"chest_room"]
	rooms[start_room.id] = start_room

	rooms[&"marshmallow_room"] = _build_monster_room(
		&"marshmallow_room",
		&"marshmallow",
		[&"start", &"strawberry_room"],
		8
	)

	rooms[&"candy_bean_room"] = _build_monster_room(
		&"candy_bean_room",
		&"candy_bean",
		[&"start", &"strawberry_room"],
		10
	)

	var chest_room := RoomRuntimeData.new()
	chest_room.id = &"chest_room"
	chest_room.display_name = "补给角落"
	chest_room.room_type = MapTypes.RoomType.CHEST
	chest_room.scene_path = "res://scenes/rooms/chest_room.tscn"
	chest_room.linked_room_ids = [&"start"]
	chest_room.payload = {
		"opened": false,
		"gold_reward": 12,
	}
	rooms[chest_room.id] = chest_room

	rooms[&"strawberry_room"] = _build_monster_room(
		&"strawberry_room",
		&"strawberry",
		[&"marshmallow_room", &"candy_bean_room", &"fish_boss_room"],
		12
	)

	var boss_room := _build_monster_room(
		&"fish_boss_room",
		&"fish_boss",
		[&"strawberry_room"],
		20,
		MapTypes.RoomType.BOSS
	)
	rooms[boss_room.id] = boss_room

	return rooms

static func _build_monster_room(
	room_id: StringName,
	monster_id: StringName,
	linked_room_ids: Array[StringName],
	reward_gold: int,
	room_type: MapTypes.RoomType = MapTypes.RoomType.MONSTER
) -> RoomRuntimeData:
	var monster_definition := MonsterCatalog.get_monster_definition(monster_id)
	var room := RoomRuntimeData.new()
	room.id = room_id
	room.display_name = monster_definition.room_display_name if monster_definition != null else "怪物房"
	room.room_type = room_type
	room.scene_path = monster_definition.room_scene_path if monster_definition != null else ""
	room.linked_room_ids = linked_room_ids
	room.payload = {
		"monster_id": monster_id,
		"reward_gold": reward_gold,
		"reward_claimed": false,
	}
	return room
