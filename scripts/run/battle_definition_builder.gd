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
	battle.monster_id = room.payload.get("monster_id", &"")
	for item in run_state.player_items:
		if item != null and item.definition != null:
			battle.starting_items.append(item.definition)
	if not battle.monster_id.is_empty():
		var monster_definition := MonsterCatalog.get_monster_definition(battle.monster_id)
		if monster_definition != null:
			battle.display_name = monster_definition.display_name
			battle.enemy = monster_definition.duplicate_enemy_definition()
	if battle.enemy == null:
		var enemy_definition: Variant = room.payload.get("enemy_definition", null)
		if enemy_definition is EnemyData:
			battle.enemy = enemy_definition
	return battle
