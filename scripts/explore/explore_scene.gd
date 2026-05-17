extends Control
class_name ExploreScene

signal battle_requested(room_id: StringName)
signal room_change_requested(target_room_id: StringName)
signal restart_requested

const DEFAULT_PLAYER_SPAWN_POSITION := Vector2(456, 246)

@onready var hp_label: Label = get_node_or_null("HudLayer/Stats/HpValue")
@onready var gold_label: Label = get_node_or_null("HudLayer/Stats/GoldValue")
@onready var room_canvas: Control = $RoomCanvas
@onready var player_actor: PlayerActor = $RoomCanvas/PlayerActor
@onready var overlay_panel: PanelContainer = $OverlayPanel
@onready var overlay_label: Label = $OverlayPanel/OverlayInner/OverlayLabel
@onready var restart_button: Button = $OverlayPanel/OverlayInner/RestartButton

var run_state: RunState
var _spawned_interactables: Array[ExploreInteractable] = []
var _interactables_in_range: Array[ExploreInteractable] = []
var _nearest_interactable: ExploreInteractable
var _active_room_scene: ExploreRoomScene
var _pending_room_layout_sync: bool = false
var _room_layout_sync_version: int = 0

func _ready() -> void:
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	room_canvas.resized.connect(_on_room_canvas_resized)
	player_actor.get_interaction_area().area_entered.connect(_on_player_interaction_area_entered)
	player_actor.get_interaction_area().area_exited.connect(_on_player_interaction_area_exited)
	if run_state != null:
		_refresh_view()

func setup(state: RunState) -> void:
	run_state = state
	if is_node_ready():
		_refresh_view()

func _process(_delta: float) -> void:
	if run_state == null or not is_visible_in_tree():
		return
	_update_nearest_interactable()

func _unhandled_input(event: InputEvent) -> void:
	if run_state == null or run_state.is_run_over:
		return
	if event.is_action_pressed("interact") and _nearest_interactable != null:
		get_viewport().set_input_as_handled()
		_activate_interactable(_nearest_interactable)

func _refresh_view() -> void:
	var room := run_state.get_current_room()
	if room == null:
		return
	if hp_label != null:
		hp_label.text = "HP %d / %d" % [run_state.player_hp, run_state.player_max_hp]
	if gold_label != null:
		gold_label.text = "金币 %d" % run_state.gold
	overlay_panel.visible = run_state.is_run_over
	if run_state.is_run_over:
		overlay_label.text = "Boss 已被击败，探索暂时结束。" if run_state.is_run_won else "生命值归零，本局结束。"
		restart_button.visible = true
	else:
		restart_button.visible = false
	_rebuild_room(room)
	_request_room_layout_sync()

func _reset_player_position() -> void:
	player_actor.set_active(not run_state.is_run_over)
	var spawn_center := _get_room_player_spawn_position()
	if _active_room_scene == null:
		player_actor.position = spawn_center
	else:
		player_actor.global_position = _active_room_scene.get_global_transform() * spawn_center
	_update_nearest_interactable()

func _rebuild_room(room: RoomRuntimeData) -> void:
	_move_player_to_room_canvas()
	_clear_room_scene()
	_spawned_interactables.clear()
	_interactables_in_range.clear()
	_nearest_interactable = null

	_load_room_scene(room)
	_move_player_to_room_layer()
	_collect_room_interactables(room)

func _update_nearest_interactable() -> void:
	var best: ExploreInteractable = null
	var best_distance: float = INF
	var player_center := player_actor.get_center_point()
	for interactable in _interactables_in_range:
		if interactable == null or not is_instance_valid(interactable):
			continue
		var distance := player_center.distance_to(interactable.get_center_point())
		if distance < best_distance:
			best_distance = distance
			best = interactable
	for interactable in _spawned_interactables:
		if interactable != null and is_instance_valid(interactable):
			interactable.set_highlighted(interactable == best)
	_nearest_interactable = best

func _activate_interactable(interactable: ExploreInteractable) -> void:
	match interactable.interactable_kind:
		&"message":
			run_state.set_message(String(interactable.payload.get("message", "这里暂时没有更多内容。")))
		&"encounter":
			var room: RoomRuntimeData = run_state.get_room(interactable.payload.get("room_id", &""))
			if room == null:
				return
			if room.cleared:
				run_state.set_message("这个房间已经净化完成，可以直接离开。")
				return
			run_state.set_message("准备进入战斗：%s" % room.display_name)
			battle_requested.emit(room.id)
		&"chest":
			_open_chest(interactable)
		&"shop":
			run_state.set_message("商店流程还未接入，当前仅保留房间占位。")
		&"exit":
			_try_change_room(interactable)

func _open_chest(interactable: ExploreInteractable) -> void:
	var room_id: Variant = interactable.payload.get("room_id", &"")
	var room: RoomRuntimeData = run_state.get_room(room_id)
	if room == null:
		return
	if room.payload.get("opened", false):
		run_state.set_message("宝箱已经打开过了。")
		return
	var gold_reward: int = int(room.payload.get("gold_reward", 0))
	room.payload["opened"] = true
	run_state.gold += gold_reward
	run_state.set_message("打开宝箱，获得 %d 金币。卡牌/道具奖励后续再接入。" % gold_reward)
	_refresh_view()

func _try_change_room(interactable: ExploreInteractable) -> void:
	var current_room := run_state.get_current_room()
	if current_room == null:
		return
	if current_room.requires_clear_before_exit() and not current_room.cleared:
		run_state.set_message("这个房间还没有处理完，出口暂时关闭。")
		return
	var target_room_id: Variant = interactable.payload.get("target_room_id", &"")
	if target_room_id is not StringName or not current_room.linked_room_ids.has(target_room_id):
		run_state.set_message("这个出口当前没有连通到有效房间。")
		return
	room_change_requested.emit(target_room_id)

func _room_color(room_type: MapTypes.RoomType) -> Color:
	match room_type:
		MapTypes.RoomType.START:
			return Color(0.88, 0.94, 0.88, 1.0)
		MapTypes.RoomType.MONSTER:
			return Color(0.98, 0.88, 0.82, 1.0)
		MapTypes.RoomType.CHEST:
			return Color(0.95, 0.92, 0.78, 1.0)
		MapTypes.RoomType.SHOP:
			return Color(0.84, 0.93, 0.95, 1.0)
		MapTypes.RoomType.BOSS:
			return Color(0.93, 0.82, 0.82, 1.0)
		_:
			return Color(0.9, 0.9, 0.9, 1.0)

func _load_room_scene(room: RoomRuntimeData) -> void:
	_active_room_scene = null
	if room == null or room.scene_path.is_empty():
		room_canvas.self_modulate = _room_color(room.room_type)
		return
	var scene_resource := load(room.scene_path)
	if scene_resource is not PackedScene:
		room_canvas.self_modulate = _room_color(room.room_type)
		return
	var room_scene := (scene_resource as PackedScene).instantiate()
	if room_scene is not ExploreRoomScene:
		room_scene.queue_free()
		room_canvas.self_modulate = _room_color(room.room_type)
		return
	_active_room_scene = room_scene as ExploreRoomScene
	room_canvas.self_modulate = Color.WHITE
	room_canvas.add_child(_active_room_scene)
	room_canvas.move_child(_active_room_scene, 0)
	_active_room_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	_active_room_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _collect_room_interactables(room: RoomRuntimeData) -> void:
	if _active_room_scene == null:
		return
	for node in _active_room_scene.find_children("*", "ExploreInteractable", true, false):
		if node is not ExploreInteractable:
			continue
		var interactable := node as ExploreInteractable
		_sync_interactable_runtime_state(interactable, room)
		_spawned_interactables.append(interactable)

func _sync_interactable_runtime_state(interactable: ExploreInteractable, room: RoomRuntimeData) -> void:
	match interactable.interactable_kind:
		&"encounter":
			var monster_name := "污染怪物"
			var monster_id: StringName = room.payload.get("monster_id", &"") if room != null else &""
			if not monster_id.is_empty():
				var monster_definition := MonsterCatalog.get_monster_definition(monster_id)
				if monster_definition != null:
					monster_name = monster_definition.display_name
			interactable.payload["room_id"] = room.id if room != null else &""
			interactable.payload["monster_id"] = monster_id
			if interactable is MonsterEncounter:
				(interactable as MonsterEncounter).configure_monster(monster_id)
			if room != null and room.cleared:
				interactable.display_name = "已净化房间"
				interactable.prompt_text = "查看房间状态"
			else:
				interactable.display_name = monster_name
				interactable.prompt_text = "发起战斗"
		&"chest":
			var opened: bool = room != null and bool(room.payload.get("opened", false))
			interactable.payload["room_id"] = room.id if room != null else &""
			interactable.display_name = "已开宝箱" if opened else "补给宝箱"
			interactable.prompt_text = "开启宝箱"
		&"exit":
			var target_room_id: Variant = interactable.payload.get("target_room_id", &"")
			var target_room: RoomRuntimeData = run_state.get_room(target_room_id) if target_room_id is StringName else null
			var target_room_name := target_room.display_name if target_room != null else "未知房间"
			interactable.display_name = "出口 -> %s" % target_room_name
			interactable.prompt_text = "前往 %s" % target_room_name
	interactable.refresh_runtime_visual()

func _clear_room_scene() -> void:
	_move_player_to_room_canvas()
	if _active_room_scene != null:
		_active_room_scene.queue_free()
		_active_room_scene = null
	_interactables_in_range.clear()
	_nearest_interactable = null

func _move_player_to_room_canvas() -> void:
	_reparent_player(room_canvas)

func _move_player_to_room_layer() -> void:
	var target_parent: Node = room_canvas
	if _active_room_scene != null:
		var y_sort_container := _active_room_scene.get_y_sort_container()
		if y_sort_container != null:
			target_parent = y_sort_container
	_reparent_player(target_parent)

func _reparent_player(new_parent: Node) -> void:
	if new_parent == null or player_actor == null:
		return
	if player_actor.get_parent() == new_parent:
		return
	var preserved_global_position := player_actor.global_position
	var current_parent := player_actor.get_parent()
	if current_parent != null:
		current_parent.remove_child(player_actor)
	new_parent.add_child(player_actor)
	player_actor.global_position = preserved_global_position

func _get_room_player_spawn_position() -> Vector2:
	if _active_room_scene == null:
		return DEFAULT_PLAYER_SPAWN_POSITION
	return _active_room_scene.get_player_spawn_position(DEFAULT_PLAYER_SPAWN_POSITION)

func _request_room_layout_sync() -> void:
	_pending_room_layout_sync = true
	_schedule_room_layout_sync()

func _on_room_canvas_resized() -> void:
	if not _pending_room_layout_sync:
		return
	_schedule_room_layout_sync()

func _schedule_room_layout_sync() -> void:
	_room_layout_sync_version += 1
	call_deferred("_run_room_layout_sync", _room_layout_sync_version)

func _run_room_layout_sync(sync_version: int) -> void:
	await get_tree().process_frame
	if sync_version != _room_layout_sync_version:
		return
	if not _pending_room_layout_sync:
		return
	_pending_room_layout_sync = false
	_reset_player_position()

func _on_player_interaction_area_entered(area: Area2D) -> void:
	if area == null:
		return
	var interactable := area.get_parent()
	if interactable is not ExploreInteractable:
		return
	var typed_interactable := interactable as ExploreInteractable
	if _interactables_in_range.has(typed_interactable):
		return
	_interactables_in_range.append(typed_interactable)

func _on_player_interaction_area_exited(area: Area2D) -> void:
	if area == null:
		return
	var interactable := area.get_parent()
	if interactable is not ExploreInteractable:
		return
	var typed_interactable := interactable as ExploreInteractable
	_interactables_in_range.erase(typed_interactable)
