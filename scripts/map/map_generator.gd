extends RefCounted
class_name MapGenerator

const MONSTER_SLOT_DEFINITIONS := [
	{
		"id": &"monster_slot_a",
		"scene_path": "res://scenes/rooms/marshmallow_room.tscn",
		"linked_room_ids": [&"start", &"monster_slot_c"],
		"reward_gold": 8,
	},
	{
		"id": &"monster_slot_b",
		"scene_path": "res://scenes/rooms/candy_bean_room.tscn",
		"linked_room_ids": [&"start", &"monster_slot_d"],
		"reward_gold": 10,
	},
	{
		"id": &"monster_slot_c",
		"scene_path": "res://scenes/rooms/cake_room.tscn",
		"linked_room_ids": [&"monster_slot_a", &"monster_slot_hub"],
		"reward_gold": 11,
	},
	{
		"id": &"monster_slot_d",
		"scene_path": "res://scenes/rooms/bread_room.tscn",
		"linked_room_ids": [&"monster_slot_b", &"monster_slot_hub"],
		"reward_gold": 11,
	},
	{
		"id": &"monster_slot_hub",
		"scene_path": "res://scenes/rooms/strawberry_room.tscn",
		"linked_room_ids": [&"monster_slot_c", &"monster_slot_d", &"fish_boss_room"],
		"reward_gold": 12,
	},
]

const RANDOMIZED_MONSTER_IDS: Array[StringName] = [
	&"marshmallow",
	&"candy_bean",
	&"cake",
	&"bread",
	&"strawberry",
]

static func build_demo_rooms() -> Dictionary:
	var rooms: Dictionary = {}
	var random_monster_ids: Array[StringName] = RANDOMIZED_MONSTER_IDS.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_shuffle_string_name_array(random_monster_ids, rng)

	var start_room := RoomRuntimeData.new()
	start_room.id = &"start"
	start_room.display_name = "入口前厅"
	start_room.room_type = MapTypes.RoomType.START
	start_room.scene_path = "res://scenes/rooms/start_room.tscn"
	start_room.linked_room_ids = [&"monster_slot_a", &"chest_room", &"monster_slot_b"]
	rooms[start_room.id] = start_room

	for index in MONSTER_SLOT_DEFINITIONS.size():
		var slot_definition: Dictionary = MONSTER_SLOT_DEFINITIONS[index]
		var slot_monster_id: StringName = random_monster_ids[index]
		var linked_room_ids: Array[StringName] = []
		for linked_room_id in slot_definition.get("linked_room_ids", []):
			if linked_room_id is StringName:
				linked_room_ids.append(linked_room_id)
		rooms[slot_definition.get("id", &"")] = _build_monster_room(
			slot_definition.get("id", &""),
			slot_monster_id,
			linked_room_ids,
			int(slot_definition.get("reward_gold", 0)),
			MapTypes.RoomType.MONSTER,
			String(slot_definition.get("scene_path", ""))
		)

	var chest_room := RoomRuntimeData.new()
	chest_room.id = &"chest_room"
	chest_room.display_name = "补给角落"
	chest_room.room_type = MapTypes.RoomType.CHEST
	chest_room.scene_path = "res://scenes/rooms/chest_room.tscn"
	chest_room.linked_room_ids = [&"start", &"shop_room"]
	chest_room.payload = {
		"opened": false,
		"gold_reward": 12,
	}
	rooms[chest_room.id] = chest_room

	var shop_room := RoomRuntimeData.new()
	shop_room.id = &"shop_room"
	shop_room.display_name = "商店"
	shop_room.room_type = MapTypes.RoomType.SHOP
	shop_room.scene_path = "res://scenes/ui/shop_screen.tscn"
	shop_room.linked_room_ids = []
	rooms[shop_room.id] = shop_room

	var boss_room := _build_monster_room(
		&"fish_boss_room",
		&"fish_boss",
		[&"monster_slot_hub"],
		20,
		MapTypes.RoomType.BOSS,
		"res://scenes/rooms/fish_boss_room.tscn"
	)
	rooms[boss_room.id] = boss_room

	return rooms

static func _build_monster_room(
	room_id: StringName,
	monster_id: StringName,
	linked_room_ids: Array[StringName],
	reward_gold: int,
	room_type: MapTypes.RoomType = MapTypes.RoomType.MONSTER,
	scene_path: String = ""
) -> RoomRuntimeData:
	var monster_definition := MonsterCatalog.get_monster_definition(monster_id)
	var room := RoomRuntimeData.new()
	room.id = room_id
	room.display_name = monster_definition.room_display_name if monster_definition != null else "怪物房"
	room.room_type = room_type
	room.scene_path = scene_path
	room.linked_room_ids = linked_room_ids
	room.payload = {
		"monster_id": monster_id,
		"reward_gold": reward_gold,
		"reward_claimed": false,
	}
	return room

static func _shuffle_string_name_array(values: Array[StringName], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		if swap_index == index:
			continue
		var current_value := values[index]
		values[index] = values[swap_index]
		values[swap_index] = current_value
