extends Node
class_name RunController

const EXPLORE_SCENE: PackedScene = preload("res://scenes/explore/explore_scene.tscn")
const BATTLE_SCENE: PackedScene = preload("res://scenes/battle/battle_scene.tscn")

var run_state: RunState
var _active_node: Node

func _ready() -> void:
	start_new_run()

func start_new_run() -> void:
	run_state = RunFactory.create_demo_run()
	_show_explore()

func _show_explore() -> void:
	_replace_active_node()
	var explore_scene := EXPLORE_SCENE.instantiate() as ExploreScene
	add_child(explore_scene)
	_active_node = explore_scene
	if explore_scene is Control:
		(explore_scene as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	explore_scene.setup(run_state)
	explore_scene.battle_requested.connect(_on_battle_requested)
	explore_scene.restart_requested.connect(start_new_run)

func _on_battle_requested(room_id: StringName) -> void:
	var room: RoomRuntimeData = run_state.get_room(room_id)
	if room == null:
		return
	var battle_definition := BattleDefinitionBuilder.build_for_room(run_state, room)
	_replace_active_node()
	var battle_scene := BATTLE_SCENE.instantiate() as BattleScene
	battle_scene.start_demo_on_ready = false
	battle_scene.set_victory_reward_preview(
		int(room.payload.get("reward_gold", 0)),
		room.room_type == MapTypes.RoomType.BOSS
	)
	add_child(battle_scene)
	_active_node = battle_scene
	battle_scene.battle_resolved.connect(func(result: Dictionary) -> void:
		_on_battle_resolved(room_id, result)
	)
	battle_scene.start_battle(battle_definition)
	if battle_scene is Control:
		(battle_scene as Control).set_anchors_preset(Control.PRESET_FULL_RECT)

func _on_battle_resolved(room_id: StringName, result: Dictionary) -> void:
	var room: RoomRuntimeData = run_state.get_room(room_id)
	run_state.player_hp = int(result.get("player_hp", run_state.player_hp))
	var outcome: BattleTypes.BattleOutcome = result.get("outcome", BattleTypes.BattleOutcome.ONGOING)
	if outcome == BattleTypes.BattleOutcome.DEFEAT:
		run_state.is_run_over = true
		run_state.is_run_won = false
		run_state.set_message("战斗失败，探索结束。")
		_show_explore()
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
	_show_explore()

func _replace_active_node() -> void:
	if _active_node != null:
		_active_node.queue_free()
		_active_node = null
