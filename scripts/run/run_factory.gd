extends RefCounted
class_name RunFactory

static func create_demo_run() -> RunState:
	var run_state := RunState.new()
	run_state.player_max_hp = 20
	run_state.player_hp = 20
	run_state.player_max_hand_size = 8
	run_state.player_starting_hand_size = 4
	run_state.player_max_stomach_volume = 6
	run_state.gold = 10
	run_state.deck_entries = CardCatalog.build_card_entries()
	run_state.player_items = [_create_starter_item()]
	run_state.rooms = MapGenerator.build_demo_rooms()
	run_state.move_to_room(&"start")
	run_state.set_message("已进入探索。WASD 移动，E 交互，先清理各个怪物房再前往 Boss 房。")
	_print_room_connections(run_state)
	return run_state

static func _create_starter_item() -> PlayerItemInstance:
	var item_data := PlayerItemData.new()
	item_data.id = &"starter_spoon"
	item_data.display_name = "起始汤匙"
	item_data.description = "当前仍是占位道具。"
	return PlayerItemInstance.from_definition(item_data)

static func _print_room_connections(run_state: RunState) -> void:
	if run_state == null or run_state.rooms.is_empty():
		return
	var ordered_room_ids: Array[StringName] = [
		&"start",
		&"monster_slot_a",
		&"monster_slot_b",
		&"chest_room",
		&"monster_slot_c",
		&"monster_slot_d",
		&"monster_slot_hub",
		&"fish_boss_room",
	]
	print("[MapDebug] 本局探索房间连接：")
	for room_id in ordered_room_ids:
		var room: RoomRuntimeData = run_state.get_room(room_id)
		if room == null:
			continue
		var target_labels: PackedStringArray = []
		for target_room_id in room.linked_room_ids:
			var target_room: RoomRuntimeData = run_state.get_room(target_room_id)
			if target_room == null:
				target_labels.append("%s(缺失)" % String(target_room_id))
				continue
			target_labels.append("%s[%s]" % [target_room.display_name, String(target_room.id)])
		print(
			"[MapDebug] %s(%s)[%s] -> %s"
			% [
				room.display_name,
				room.type_label(),
				String(room.id),
				", ".join(target_labels),
			]
		)
