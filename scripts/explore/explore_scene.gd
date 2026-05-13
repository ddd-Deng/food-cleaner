extends Control
class_name ExploreScene

signal battle_requested(room_id: StringName)
signal restart_requested

const INTERACTABLE_SCENE := preload("res://scripts/explore/explore_interactable.gd")
const DEFAULT_EXIT_POSITIONS := [
	Vector2(70, 230),
	Vector2(822, 230),
	Vector2(446, 56),
	Vector2(446, 404),
]
const DEFAULT_FEATURE_POSITION := Vector2(430, 170)
const DEFAULT_PLAYER_SPAWN_POSITION := Vector2(456, 246)

@onready var room_title_label: Label = $Root/Layout/Header/RoomTitle
@onready var room_type_label: Label = $Root/Layout/Header/RoomType
@onready var hp_label: Label = $Root/Layout/Header/Stats/HpValue
@onready var gold_label: Label = $Root/Layout/Header/Stats/GoldValue
@onready var room_canvas: Control = $Root/Layout/RoomPanel/RoomCanvas
@onready var player_actor: PlayerActor = $Root/Layout/RoomPanel/RoomCanvas/PlayerActor
@onready var prompt_label: Label = $Root/Layout/Footer/FooterInner/PromptValue
@onready var status_label: RichTextLabel = $Root/Layout/Footer/FooterInner/StatusValue
@onready var overlay_panel: PanelContainer = $Root/Layout/RoomPanel/OverlayPanel
@onready var overlay_label: Label = $Root/Layout/RoomPanel/OverlayPanel/OverlayInner/OverlayLabel
@onready var restart_button: Button = $Root/Layout/RoomPanel/OverlayPanel/OverlayInner/RestartButton

var run_state: RunState
var _spawned_interactables: Array[ExploreInteractable] = []
var _nearest_interactable: ExploreInteractable
var _active_room_scene: ExploreRoomScene
var _pending_room_layout_sync: bool = false
var _room_layout_sync_version: int = 0

func _ready() -> void:
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	room_canvas.resized.connect(_on_room_canvas_resized)
	if run_state != null:
		_refresh_view()

func setup(state: RunState) -> void:
	run_state = state
	if is_node_ready():
		_refresh_view()

func _process(_delta: float) -> void:
	if run_state == null or not is_visible_in_tree():
		return
	if run_state.is_run_over:
		prompt_label.text = "本局已结束。"
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
	room_title_label.text = room.display_name
	room_type_label.text = room.type_label()
	hp_label.text = "HP %d / %d" % [run_state.player_hp, run_state.player_max_hp]
	gold_label.text = "金币 %d" % run_state.gold
	status_label.text = run_state.last_event_message
	overlay_panel.visible = run_state.is_run_over
	if run_state.is_run_over:
		overlay_label.text = "Boss 已被击败，探索暂时结束。" if run_state.is_run_won else "生命值归零，本局结束。"
		restart_button.visible = true
	else:
		restart_button.visible = false
	_rebuild_room(room)
	_request_room_layout_sync()

func _reset_player_position() -> void:
	var inner_margin := Vector2(8, 8)
	var bounds := Rect2(
		inner_margin,
		room_canvas.size - inner_margin * 2.0
	)
	player_actor.set_active(not run_state.is_run_over)
	var spawn_center := _get_room_player_spawn_position()
	player_actor.position = spawn_center
	player_actor.set_room_bounds(bounds)
	_update_nearest_interactable()

func _rebuild_room(room: RoomRuntimeData) -> void:
	_clear_room_scene()
	for interactable in _spawned_interactables:
		interactable.queue_free()
	_spawned_interactables.clear()

	_load_room_scene(room)
	_spawn_room_feature(room)
	_spawn_room_exits(room)

func _spawn_room_feature(room: RoomRuntimeData) -> void:
	var feature_position := _get_room_feature_position()
	match room.room_type:
		MapTypes.RoomType.START:
			_add_interactable(&"guide", "清扫路线图", "查看提示", &"message", {
				"message": "前往怪物房清理污染，再尝试进入 Boss 房。宝箱房当前提供基础金币奖励。",
			}, feature_position)
		MapTypes.RoomType.MONSTER, MapTypes.RoomType.BOSS:
			var cleared_name := "已净化房间" if room.cleared else "污染怪物"
			var prompt := "查看房间状态" if room.cleared else "发起战斗"
			_add_interactable(&"enemy", cleared_name, prompt, &"encounter", {
				"room_id": room.id,
			}, feature_position)
		MapTypes.RoomType.CHEST:
			var opened: bool = room.payload.get("opened", false)
			_add_interactable(&"chest", "已开宝箱" if opened else "补给宝箱", "开启宝箱", &"chest", {
				"room_id": room.id,
			}, feature_position)
		MapTypes.RoomType.SHOP:
			_add_interactable(&"merchant", "流动商人", "打开商店", &"shop", {
				"room_id": room.id,
			}, feature_position)

func _spawn_room_exits(room: RoomRuntimeData) -> void:
	var positions := _get_room_exit_positions()
	for index in range(room.linked_room_ids.size()):
		var target_room_id: StringName = room.linked_room_ids[index]
		var target_room: RoomRuntimeData = run_state.get_room(target_room_id)
		if target_room == null:
			continue
		var display_name := "出口 -> %s" % target_room.type_label()
		_add_interactable(
			StringName("exit_%s" % String(target_room_id)),
			display_name,
			"前往 %s" % target_room.display_name,
			&"exit",
			{"target_room_id": target_room_id},
			positions[index % max(1, positions.size())]
		)

func _add_interactable(id: StringName, display_name: String, prompt: String, kind: StringName, payload: Dictionary, position_value: Vector2) -> void:
	var interactable: ExploreInteractable = INTERACTABLE_SCENE.new()
	room_canvas.add_child(interactable)
	interactable.configure(id, display_name, prompt, kind, payload)
	interactable.position = position_value
	_spawned_interactables.append(interactable)

func _update_nearest_interactable() -> void:
	var best: ExploreInteractable = null
	var best_distance: float = 120.0
	var player_center := player_actor.get_center_point()
	for interactable in _spawned_interactables:
		var distance := player_center.distance_to(interactable.get_center_point())
		if distance < best_distance:
			best_distance = distance
			best = interactable
	for interactable in _spawned_interactables:
		interactable.set_highlighted(interactable == best)
	_nearest_interactable = best
	if best == null:
		prompt_label.text = "WASD 移动，靠近对象后按 E 交互。"
		return
	prompt_label.text = "E %s" % best.prompt_text

func _activate_interactable(interactable: ExploreInteractable) -> void:
	match interactable.interactable_kind:
		&"message":
			run_state.set_message(String(interactable.payload.get("message", "这里暂时没有更多内容。")))
			status_label.text = run_state.last_event_message
		&"encounter":
			var room: RoomRuntimeData = run_state.get_room(interactable.payload.get("room_id", &""))
			if room == null:
				return
			if room.cleared:
				run_state.set_message("这个房间已经净化完成，可以直接离开。")
				status_label.text = run_state.last_event_message
				return
			run_state.set_message("准备进入战斗：%s" % room.display_name)
			status_label.text = run_state.last_event_message
			battle_requested.emit(room.id)
		&"chest":
			_open_chest(interactable)
		&"shop":
			run_state.set_message("商店流程还未接入，当前仅保留房间占位。")
			status_label.text = run_state.last_event_message
		&"exit":
			_try_change_room(interactable)

func _open_chest(interactable: ExploreInteractable) -> void:
	var room_id: Variant = interactable.payload.get("room_id", &"")
	var room: RoomRuntimeData = run_state.get_room(room_id)
	if room == null:
		return
	if room.payload.get("opened", false):
		run_state.set_message("宝箱已经打开过了。")
		status_label.text = run_state.last_event_message
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
		status_label.text = run_state.last_event_message
		return
	var target_room_id: Variant = interactable.payload.get("target_room_id", &"")
	run_state.move_to_room(target_room_id)
	var target_room := run_state.get_current_room()
	run_state.set_message("进入了 %s。" % (target_room.display_name if target_room != null else "下一个房间"))
	_refresh_view()

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

func _clear_room_scene() -> void:
	if _active_room_scene != null:
		_active_room_scene.queue_free()
		_active_room_scene = null

func _get_room_feature_position() -> Vector2:
	if _active_room_scene == null:
		return DEFAULT_FEATURE_POSITION
	return _active_room_scene.get_feature_anchor_position(DEFAULT_FEATURE_POSITION)

func _get_room_exit_positions() -> Array[Vector2]:
	if _active_room_scene == null:
		return DEFAULT_EXIT_POSITIONS.duplicate()
	var positions := _active_room_scene.get_exit_anchor_positions(DEFAULT_EXIT_POSITIONS)
	return DEFAULT_EXIT_POSITIONS.duplicate() if positions.is_empty() else positions

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
