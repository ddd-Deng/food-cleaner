extends RefCounted
class_name RunState

var player_max_hp: int = 20
var player_hp: int = 20
var player_max_hand_size: int = 8
var player_starting_hand_size: int = 4
var player_max_stomach_volume: int = 6
var gold: int = 0
var delete_card_cost: int = 5
var deck_entries: Array[CardPileEntryData] = []
var player_items: Array[PlayerItemInstance] = []
var rooms: Dictionary = {}
var current_room_id: StringName = &""
var shop_return_room_id: StringName = &""
var last_event_message: String = ""
var is_run_over: bool = false
var is_run_won: bool = false

func get_current_room() -> RoomRuntimeData:
	return rooms.get(current_room_id, null)

func get_room(room_id: StringName) -> RoomRuntimeData:
	return rooms.get(room_id, null)

func move_to_room(room_id: StringName) -> void:
	current_room_id = room_id
	var room: RoomRuntimeData = get_current_room()
	if room != null:
		room.visited = true

func set_message(message: String) -> void:
	last_event_message = message
