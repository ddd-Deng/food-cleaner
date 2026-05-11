extends RefCounted
class_name RunFactory

static func create_demo_run() -> RunState:
	var run_state := RunState.new()
	run_state.player_max_hp = 20
	run_state.player_hp = 20
	run_state.player_max_hand_size = 8
	run_state.player_starting_hand_size = 4
	run_state.player_max_stomach_volume = 3
	run_state.gold = 10
	run_state.deck_entries = CardCatalog.build_card_entries()
	run_state.player_items = [_create_starter_item()]
	run_state.rooms = MapGenerator.build_demo_rooms()
	run_state.move_to_room(&"start")
	run_state.set_message("已进入探索。WASD 移动，E 交互。")
	return run_state

static func _create_starter_item() -> PlayerItemInstance:
	var item_data := PlayerItemData.new()
	item_data.id = &"starter_spoon"
	item_data.display_name = "起始汤匙"
	item_data.description = "当前仍是占位道具。"
	return PlayerItemInstance.from_definition(item_data)
