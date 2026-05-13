extends RefCounted
class_name RoomRuntimeData

var id: StringName = &""
var display_name: String = ""
var room_type: MapTypes.RoomType = MapTypes.RoomType.EVENT
var scene_path: String = ""
var linked_room_ids: Array[StringName] = []
var visited: bool = false
var cleared: bool = false
var payload: Dictionary = {}

func type_label() -> String:
	match room_type:
		MapTypes.RoomType.START:
			return "起点"
		MapTypes.RoomType.MONSTER:
			return "怪物房"
		MapTypes.RoomType.CHEST:
			return "宝箱房"
		MapTypes.RoomType.SHOP:
			return "商店"
		MapTypes.RoomType.BOSS:
			return "Boss房"
		MapTypes.RoomType.EVENT:
			return "事件房"
		_:
			return "房间"

func requires_clear_before_exit() -> bool:
	return room_type == MapTypes.RoomType.MONSTER or room_type == MapTypes.RoomType.BOSS
