extends RefCounted
class_name BattleRules

static func create_state(definition: BattleDefinition) -> BattleState:
	var state: BattleState = BattleState.new()
	state.definition = definition
	state.player_hp = definition.player_max_hp
	state.player_max_hp = definition.player_max_hp
	state.player_max_hand_size = definition.player_max_hand_size
	state.player_starting_hand_size = definition.player_starting_hand_size
	state.player_max_stomach_volume = definition.player_max_stomach_volume
	state.player_items.clear()
	for item_definition in definition.starting_items:
		if item_definition != null:
			state.player_items.append(PlayerItemInstance.from_definition(item_definition))
	state.enemy = EnemyRuntime.from_definition(definition.enemy)
	_fill_draw_pile(state, definition)
	state.add_log("战斗开始：%s" % definition.display_name)
	state.set_timeline(_build_timeline_preview(state))
	state.battle_time = 0
	state.phase = BattleTypes.BattlePhase.ACTIVE
	state.player_current_intent = "等待打出第一张牌"
	_draw_to_target_hand_size(state)
	_update_enemy_intent(state)
	return state

static func play_card(state: BattleState, hand_index: int) -> bool:
	if state.is_finished():
		state.add_log("战斗已经结束。")
		return false
	if hand_index < 0 or hand_index >= state.hand.size():
		state.add_log("选中的卡牌无效。")
		return false
	var card: CardInstance = state.hand[hand_index]
	var card_time: int = maxi(0, card.get_time_cost())
	state.hand.remove_at(hand_index)
	state.discard_pile.append(card)
	state.last_played_card_name = card.get_display_name()
	state.last_played_card_time_cost = card_time
	state.last_played_effect_summary = _summarize_effects(card.definition.effects if card.definition != null else [])
	state.last_played_sequence += 1
	state.add_log("打出了 %s。" % card.get_display_name())
	_advance_time_and_resolve(state, card_time)
	if card.definition != null:
		for effect in card.definition.effects:
			_apply_effect(state, effect)
			if state.is_finished():
				return true
	if not state.is_finished():
		_draw_one_card(state)
		state.add_log("抽取了一张补充牌。")
	return true

static func _advance_time_and_resolve(state: BattleState, delta: int) -> void:
	if delta <= 0:
		_process_pending_enemy_actions(state)
		_update_enemy_intent(state)
		_check_outcome(state)
		return
	var target_time: int = state.battle_time + delta
	while state.enemy != null and state.enemy.get_current_action_time() >= 0 and state.enemy.get_current_action_time() <= target_time and not state.is_finished():
		state.battle_time = state.enemy.get_current_action_time()
		_execute_enemy_action(state)
	_update_enemy_intent(state)
	state.battle_time = target_time
	_check_outcome(state)

static func _process_pending_enemy_actions(state: BattleState) -> void:
	while state.enemy != null and state.enemy.get_current_action_time() >= 0 and state.enemy.get_current_action_time() <= state.battle_time and not state.is_finished():
		_execute_enemy_action(state)

static func _execute_enemy_action(state: BattleState) -> void:
	var action: EnemyActionData = state.enemy.current_action()
	if action == null:
		state.enemy.next_action_time = -1
		state.player_current_intent = "敌人暂无意图"
		return
	state.last_enemy_action_name = action.display_name
	match action.action_type:
		BattleTypes.EnemyActionType.ATTACK:
			state.player_hp -= action.amount
			state.add_log("%s 造成了 %d 点伤害。" % [_enemy_name(state), action.amount])
		BattleTypes.EnemyActionType.ADD_BLOCK:
			var block_definition: Variant = action.payload.get("block_definition", null)
			if block_definition is FoodBlockData:
				state.enemy.add_block(block_definition)
				state.add_log("%s 生成了新的食物块。" % _enemy_name(state))
			else:
				state.add_log("%s 想生成食物块，但当前没有配置内容。" % _enemy_name(state))
		BattleTypes.EnemyActionType.CORRUPT_BLOCK:
			state.add_log("%s 触发了变质效果，但目前仍是占位实现。" % _enemy_name(state))
		BattleTypes.EnemyActionType.CHARGE_ATTACK:
			state.add_log("%s 正在蓄力。" % _enemy_name(state))
		_:
			state.add_log("%s 暂时没有动作。" % _enemy_name(state))
	state.enemy.advance_action()
	_update_enemy_intent(state)
	_check_outcome(state)

static func _apply_effect(state: BattleState, effect: BattleEffectData) -> void:
	match effect.kind:
		BattleTypes.EffectKind.DRAW_CARDS:
			for _i in range(max(0, effect.amount)):
				_draw_one_card(state)
		BattleTypes.EffectKind.GAIN_ENERGY:
			state.add_log("获得了 %d 点临时体力。" % effect.amount)
		BattleTypes.EffectKind.EAT_ENEMY_BLOCK:
			_eat_enemy_block(state)
		BattleTypes.EffectKind.DIGEST_STOMACH_ITEM:
			_digest_stomach_item(state)
		BattleTypes.EffectKind.ADVANCE_PURIFICATION:
			_advance_purification(state, effect.purification_action)
		BattleTypes.EffectKind.DEAL_PLAYER_DAMAGE:
			state.player_hp -= effect.amount
			state.add_log("受到了 %d 点伤害。" % effect.amount)
		BattleTypes.EffectKind.SUMMON_ENEMY_BLOCK:
			var block_definition: Variant = effect.payload.get("block_definition", null)
			if block_definition is FoodBlockData:
				state.enemy.add_block(block_definition)
				state.add_log("敌人身上出现了新的食物块。")
		_:
			state.add_log("这个效果暂时还没有接入。")
	_check_outcome(state)

static func _draw_to_target_hand_size(state: BattleState) -> void:
	while state.hand.size() < state.player_starting_hand_size and not state.draw_pile.is_empty():
		_draw_one_card(state)

static func _draw_one_card(state: BattleState) -> void:
	if state.draw_pile.is_empty():
		_shuffle_discard_into_draw_pile(state)
	if state.draw_pile.is_empty():
		state.add_log("没有可以抽取的卡牌了。")
		return
	var card: CardInstance = state.draw_pile.pop_back()
	state.hand.append(card)
	state.add_log("抽到了 %s。" % card.get_display_name())

static func _build_timeline_preview(_state: BattleState) -> Array[String]:
	var entries: Array[String] = []
	for i in range(16):
		entries.append("%dt" % i)
	return entries

static func _update_enemy_intent(state: BattleState) -> void:
	if state.enemy == null:
		state.player_current_intent = "没有敌人"
		return
	var action: EnemyActionData = state.enemy.current_action()
	if action == null:
		state.player_current_intent = "敌人待机"
		return
	var action_time: int = state.enemy.get_current_action_time()
	if action_time < 0:
		state.player_current_intent = "敌人待机"
		return
	state.player_current_intent = "%s（%dt 后）" % [action.display_name, max(0, action_time - state.battle_time)]

static func _eat_enemy_block(state: BattleState) -> void:
	if state.enemy.is_purified():
		state.add_log("敌人已经被净化。")
		return
	if state.enemy.blocks.is_empty():
		state.add_log("当前没有可吃掉的敌方食物块。")
		return
	var block: FoodBlockInstance = state.enemy.blocks[0]
	if state.get_stomach_capacity_left() < block.volume:
		state.add_log("胃容量已经满了。")
		return
	state.enemy.remove_front_block()
	state.stomach.append(block)
	state.add_log("吃掉了 %s。" % block.get_display_name())

static func _digest_stomach_item(state: BattleState) -> void:
	if state.stomach.is_empty():
		state.add_log("胃里没有可消化的食物块。")
		return
	var item: FoodBlockInstance = state.stomach[0]
	state.stomach.remove_at(0)
	state.add_log("消化了 %s。" % item.get_display_name())
	if item.definition != null and not item.definition.digest_effects.is_empty():
		for effect in item.definition.digest_effects:
			_apply_effect(state, effect)

static func _advance_purification(state: BattleState, action: BattleTypes.PurificationActionType) -> void:
	var current_step: PurificationStepData = state.enemy.current_step()
	if current_step == null:
		state.add_log("已经没有剩余的净化步骤。")
		return
	if current_step.required_action != action:
		state.add_log("净化步骤不匹配。")
		return
	state.enemy.purification_index += 1
	state.add_log("净化步骤推进：%s。" % current_step.display_name)

static func _check_outcome(state: BattleState) -> void:
	if state.player_hp <= 0:
		state.outcome = BattleTypes.BattleOutcome.DEFEAT
		state.phase = BattleTypes.BattlePhase.FINISHED
		state.add_log("你被击败了。")
		return
	if state.enemy.is_purified():
		state.outcome = BattleTypes.BattleOutcome.VICTORY_PURIFIED
		state.phase = BattleTypes.BattlePhase.FINISHED
		state.add_log("敌人已被净化。")
		return
	if state.enemy.is_cleared():
		state.outcome = BattleTypes.BattleOutcome.VICTORY_CLEARED
		state.phase = BattleTypes.BattlePhase.FINISHED
		state.add_log("敌人已被清除。")

static func _fill_draw_pile(state: BattleState, definition: BattleDefinition) -> void:
	if definition == null:
		return
	for entry in definition.starting_deck:
		if entry == null or entry.card == null:
			continue
		for _i in range(max(0, entry.quantity)):
			state.draw_pile.append(CardInstance.from_definition(entry.card))
	state.draw_pile.shuffle()

static func _shuffle_discard_into_draw_pile(state: BattleState) -> void:
	if state.discard_pile.is_empty():
		return
	state.draw_pile.append_array(state.discard_pile)
	state.discard_pile.clear()
	state.draw_pile.shuffle()

static func _enemy_name(state: BattleState) -> String:
	if state.enemy == null or state.enemy.definition == null:
		return "敌人"
	return state.enemy.definition.display_name

static func _summarize_effects(effects: Array[BattleEffectData]) -> String:
	if effects.is_empty():
		return "无额外效果"
	var summary_parts: PackedStringArray = []
	for effect in effects:
		summary_parts.append(_effect_summary_text(effect))
	return "，".join(summary_parts)

static func _effect_summary_text(effect: BattleEffectData) -> String:
	if effect == null:
		return "未知效果"
	if not effect.description.is_empty():
		return effect.description
	match effect.kind:
		BattleTypes.EffectKind.DRAW_CARDS:
			return "抽 %d 张牌" % max(0, effect.amount)
		BattleTypes.EffectKind.GAIN_ENERGY:
			return "获得 %d 点体力" % effect.amount
		BattleTypes.EffectKind.EAT_ENEMY_BLOCK:
			return "吞下最前方食物块"
		BattleTypes.EffectKind.DIGEST_STOMACH_ITEM:
			return "消化胃里最前方食物块"
		BattleTypes.EffectKind.ADVANCE_PURIFICATION:
			return "推进%s步骤" % _purification_action_name(effect.purification_action)
		BattleTypes.EffectKind.DEAL_PLAYER_DAMAGE:
			return "玩家受到 %d 点伤害" % effect.amount
		BattleTypes.EffectKind.DEAL_ENEMY_DAMAGE:
			return "对敌人造成 %d 点伤害" % effect.amount
		BattleTypes.EffectKind.SUMMON_ENEMY_BLOCK:
			return "生成新的敌方食物块"
		_:
			return "暂未命名效果"

static func _purification_action_name(action: BattleTypes.PurificationActionType) -> String:
	match action:
		BattleTypes.PurificationActionType.CLEAN:
			return "清洗"
		BattleTypes.PurificationActionType.CUT:
			return "切除"
		BattleTypes.PurificationActionType.BAKE:
			return "烘烤"
		_:
			return "净化"
