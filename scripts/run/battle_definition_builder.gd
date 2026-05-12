extends RefCounted
class_name BattleDefinitionBuilder

static func build_for_room(run_state: RunState, room: RoomRuntimeData) -> BattleDefinition:
	var battle: BattleDefinition = BattleDefinition.new()
	battle.id = StringName("battle_%s" % String(room.id))
	battle.display_name = room.display_name
	battle.player_max_hp = run_state.player_max_hp
	battle.player_starting_hp = run_state.player_hp
	battle.player_max_hand_size = run_state.player_max_hand_size
	battle.player_starting_hand_size = run_state.player_starting_hand_size
	battle.player_max_stomach_volume = run_state.player_max_stomach_volume
	battle.player_starting_gold = run_state.gold
	battle.starting_deck = run_state.deck_entries.duplicate()
	for item in run_state.player_items:
		if item != null and item.definition != null:
			battle.starting_items.append(item.definition)
	var enemy_definition: Variant = room.payload.get("enemy_definition", null)
	if enemy_definition is EnemyData:
		battle.enemy = enemy_definition
	return battle
