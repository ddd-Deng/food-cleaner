extends RefCounted
class_name MapGenerator

static func build_demo_rooms() -> Dictionary:
	var rooms: Dictionary = {}

	var start_room := RoomRuntimeData.new()
	start_room.id = &"start"
	start_room.display_name = "入口前厅"
	start_room.room_type = MapTypes.RoomType.START
	start_room.linked_room_ids = [&"monster_room", &"chest_room"]
	rooms[start_room.id] = start_room

	var monster_room := RoomRuntimeData.new()
	monster_room.id = &"monster_room"
	monster_room.display_name = "脏污餐台"
	monster_room.room_type = MapTypes.RoomType.MONSTER
	monster_room.linked_room_ids = [&"start", &"boss_room"]
	monster_room.payload = {
		"enemy_definition": _build_enemy_variant("变质便当", 0),
		"reward_gold": 8,
		"reward_claimed": false,
	}
	rooms[monster_room.id] = monster_room

	var chest_room := RoomRuntimeData.new()
	chest_room.id = &"chest_room"
	chest_room.display_name = "补给角落"
	chest_room.room_type = MapTypes.RoomType.CHEST
	chest_room.linked_room_ids = [&"start"]
	chest_room.payload = {
		"opened": false,
		"gold_reward": 12,
	}
	rooms[chest_room.id] = chest_room

	var boss_room := RoomRuntimeData.new()
	boss_room.id = &"boss_room"
	boss_room.display_name = "深处后厨"
	boss_room.room_type = MapTypes.RoomType.BOSS
	boss_room.linked_room_ids = [&"monster_room"]
	boss_room.payload = {
		"enemy_definition": _build_enemy_variant("污秽盛宴", 1),
		"reward_gold": 20,
		"reward_claimed": false,
	}
	rooms[boss_room.id] = boss_room

	return rooms

static func _build_enemy_variant(display_name: String, extra_block_count: int) -> EnemyData:
	var base_battle: BattleDefinition = SampleBattleFactory.create_demo_battle_definition()
	var enemy: EnemyData = base_battle.enemy.duplicate(true) as EnemyData
	enemy.display_name = display_name
	for _i in range(extra_block_count):
		if not enemy.food_blocks.is_empty():
			enemy.food_blocks.append(enemy.food_blocks[0].duplicate(true))
	return enemy
