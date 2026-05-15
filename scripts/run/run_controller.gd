extends Node
class_name RunController

const EXPLORE_SCENE: PackedScene = preload("res://scenes/explore/explore_scene.tscn")
const BATTLE_SCENE: PackedScene = preload("res://scenes/battle/battle_scene.tscn")

var run_state: RunState
var _active_node: Node
var _transition_overlay: SceneTransitionOverlay
var _is_transitioning: bool = false

func _ready() -> void:
	start_new_run()

func set_transition_overlay(transition_overlay: SceneTransitionOverlay) -> void:
	_transition_overlay = transition_overlay

func start_new_run() -> void:
	if _is_transitioning:
		return
	run_state = RunFactory.create_demo_run()
	_show_explore()

func _show_explore() -> void:
	var explore_scene := _build_explore_scene()
	if explore_scene == null:
		return
	_replace_active_node_with(explore_scene)

func _on_battle_requested(room_id: StringName) -> void:
	if _is_transitioning:
		return
	var room: RoomRuntimeData = run_state.get_room(room_id)
	if room == null:
		return
	var battle_definition := BattleDefinitionBuilder.build_for_room(run_state, room)
	await _run_scene_transition(Callable(self, "_show_battle").bind(room_id, room, battle_definition))

func _on_battle_resolved(room_id: StringName, result: Dictionary) -> void:
	if _is_transitioning:
		return
	var room: RoomRuntimeData = run_state.get_room(room_id)
	run_state.player_hp = int(result.get("player_hp", run_state.player_hp))
	var outcome: BattleTypes.BattleOutcome = result.get("outcome", BattleTypes.BattleOutcome.ONGOING)
	if outcome == BattleTypes.BattleOutcome.DEFEAT:
		run_state.is_run_over = true
		run_state.is_run_won = false
		run_state.set_message("战斗失败，探索结束。")
		await _run_scene_transition(Callable(self, "_show_explore"))
		return
	if room != null:
		room.cleared = true
		var reward_claimed: bool = room.payload.get("reward_claimed", false)
		var reward_gold: int = int(room.payload.get("reward_gold", 0))
		if not reward_claimed and reward_gold > 0:
			run_state.gold += reward_gold
			room.payload["reward_claimed"] = true
			run_state.set_message("战斗胜利，获得 %d 金币。" % reward_gold)
		else:
			run_state.set_message("战斗胜利，房间已净化。")
		if room.room_type == MapTypes.RoomType.BOSS:
			run_state.is_run_over = true
			run_state.is_run_won = true
	await _run_scene_transition(Callable(self, "_show_explore"))

func _on_room_change_requested(target_room_id: StringName) -> void:
	if _is_transitioning:
		return
	var target_room := run_state.get_room(target_room_id)
	if target_room == null:
		return
	run_state.move_to_room(target_room_id)
	run_state.set_message("进入了 %s。" % target_room.display_name)
	await _run_scene_transition(Callable(self, "_show_explore"))

func _replace_active_node() -> void:
	if _active_node != null:
		_active_node.queue_free()
		_active_node = null

func _replace_active_node_with(node: Node, disable_processing: bool = false) -> void:
	_replace_active_node()
	add_child(node)
	_active_node = node
	_set_active_node_processing_enabled(not disable_processing)

func _build_explore_scene() -> ExploreScene:
	var explore_scene := EXPLORE_SCENE.instantiate() as ExploreScene
	if explore_scene == null:
		return null
	if explore_scene is Control:
		(explore_scene as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	explore_scene.setup(run_state)
	explore_scene.battle_requested.connect(_on_battle_requested)
	explore_scene.room_change_requested.connect(_on_room_change_requested)
	explore_scene.restart_requested.connect(start_new_run)
	return explore_scene

func _show_battle(room_id: StringName, room: RoomRuntimeData, battle_definition: BattleDefinition) -> void:
	var battle_scene := BATTLE_SCENE.instantiate() as BattleScene
	if battle_scene == null:
		return
	battle_scene.start_demo_on_ready = false
	battle_scene.set_victory_reward_preview(
		int(room.payload.get("reward_gold", 0)),
		room.room_type == MapTypes.RoomType.BOSS
	)
	battle_scene.battle_resolved.connect(func(result: Dictionary) -> void:
		_on_battle_resolved(room_id, result)
	)
	battle_scene.start_battle(battle_definition)
	if battle_scene is Control:
		(battle_scene as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	_replace_active_node_with(battle_scene, _is_transitioning)

func _run_scene_transition(switch_callable: Callable) -> void:
	if _is_transitioning:
		return
	if _transition_overlay == null:
		switch_callable.call()
		return
	_is_transitioning = true
	_set_active_node_processing_enabled(false)
	_transition_overlay.play_transition()
	await _transition_overlay.midpoint_reached
	switch_callable.call()
	_set_active_node_processing_enabled(false)
	await _transition_overlay.transition_finished
	_set_active_node_processing_enabled(true)
	_is_transitioning = false

func _set_active_node_processing_enabled(enabled: bool) -> void:
	if _active_node == null:
		return
	_active_node.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
