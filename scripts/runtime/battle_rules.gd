extends RefCounted
class_name BattleRules

const TIMELINE_HISTORY_START_TIME := 0
const TIMELINE_FUTURE_PREVIEW_SLOTS := 7

static func create_state(definition: BattleDefinition) -> BattleState:
	var state: BattleState = BattleState.new()
	state.definition = definition
	state.player_max_hp = definition.player_max_hp
	state.player_hp = clampi(definition.player_starting_hp, 0, definition.player_max_hp)
	state.player_block = 0
	state.player_gold = max(0, definition.player_starting_gold)
	state.player_max_hand_size = definition.player_max_hand_size
	state.player_starting_hand_size = definition.player_starting_hand_size
	state.player_max_stomach_volume = definition.player_max_stomach_volume
	state.player_items.clear()
	for item_definition in definition.starting_items:
		if item_definition != null:
			state.player_items.append(PlayerItemInstance.from_definition(item_definition))
	state.enemy = EnemyRuntime.from_definition(definition.enemy)
	_fill_draw_pile(state, definition)
	state.battle_time = 0
	state.phase = BattleTypes.BattlePhase.ACTIVE
	state.player_current_intent = "等待打出第一张牌"
	state.add_log("战斗开始：%s" % definition.display_name)
	_draw_to_target_hand_size(state)
	_refresh_battle_readouts(state)
	return state

static func play_card(state: BattleState, hand_index: int) -> bool:
	if state.is_finished():
		state.add_log("战斗已经结束。")
		return false
	if hand_index < 0 or hand_index >= state.hand.size():
		state.add_log("选中的卡牌无效。")
		return false
	var card: CardInstance = state.hand[hand_index]
	var validation_error: String = _validate_card_play(state, card)
	if not validation_error.is_empty():
		state.add_log(validation_error)
		_refresh_battle_readouts(state)
		return false

	var card_time: int = maxi(0, card.get_time_cost())
	state.hand.remove_at(hand_index)
	state.last_played_card_name = card.get_display_name()
	state.last_played_card_time_cost = card_time
	state.last_played_effect_summary = _summarize_effects(card.definition.effects if card.definition != null else [])
	state.last_played_sequence += 1
	state.add_log("打出了 %s。" % card.get_display_name())

	_advance_time_and_resolve(state, card_time)
	if state.is_finished():
		state.discard_pile.append(card)
		_refresh_battle_readouts(state)
		return true

	_record_card_effect(state, card)
	if card.definition != null:
		for effect in card.definition.effects:
			_apply_effect(state, effect)
			if state.is_finished():
				break

	state.discard_pile.append(card)
	if not state.is_finished():
		_draw_one_card(state)
		state.add_log("抽取了一张补充牌。")

	_refresh_battle_readouts(state)
	return true

static func preview_card_play(state: BattleState, hand_index: int) -> Dictionary:
	var preview := {
		"can_play": false,
		"reason": "",
		"start_time": 0,
		"end_time": 0,
		"time_cost": 0,
		"enemy_actions_crossed": [],
		"requested_eat_count": 0,
		"eat_count": 0,
		"eat_volume": 0,
		"eat_target_indices": [],
	}
	if state == null:
		preview.reason = "当前没有战斗状态。"
		return preview
	preview.start_time = max(0, state.battle_time)
	preview.end_time = preview.start_time
	if state.is_finished():
		preview.reason = "战斗已经结束。"
		return preview
	if hand_index < 0 or hand_index >= state.hand.size():
		preview.reason = "选中的卡牌无效。"
		return preview
	var card: CardInstance = state.hand[hand_index]
	var requested_eat_count: int = _requested_eat_count_for_card(card)
	var eat_preview: Dictionary = _build_eat_preview(state, requested_eat_count)
	preview.requested_eat_count = requested_eat_count
	preview.eat_count = int(eat_preview.get("actual_count", 0))
	preview.eat_volume = int(eat_preview.get("required_volume", 0))
	preview.eat_target_indices = (eat_preview.get("target_indices", []) as Array).duplicate()
	var validation_error: String = _validate_card_play(state, card)
	if not validation_error.is_empty():
		preview.reason = validation_error
		preview.time_cost = max(0, card.get_time_cost()) if card != null else 0
		preview.end_time = preview.start_time + preview.time_cost
		preview.enemy_actions_crossed = _enemy_actions_between(state, preview.start_time, preview.end_time)
		return preview
	preview.can_play = true
	preview.time_cost = max(0, card.get_time_cost()) if card != null else 0
	preview.end_time = preview.start_time + preview.time_cost
	preview.enemy_actions_crossed = _enemy_actions_between(state, preview.start_time, preview.end_time)
	return preview

static func _validate_card_play(state: BattleState, card: CardInstance) -> String:
	if card == null or card.definition == null:
		return "这张牌当前没有可用定义。"
	var total_requested_eat_count: int = _requested_eat_count_for_card(card)
	if total_requested_eat_count > 0:
		if state.enemy == null or state.enemy.blocks.is_empty():
			return "当前没有可吃掉的敌方食物块。"
		var eat_preview: Dictionary = _build_eat_preview(state, total_requested_eat_count)
		var required_volume: int = int(eat_preview.get("required_volume", 0))
		if required_volume <= 0:
			return "当前没有可吃掉的敌方食物块。"
		if required_volume > state.get_stomach_capacity_left():
			return "胃容量不足，无法打出这张吃牌。"
	return ""

static func _requested_eat_count_for_card(card: CardInstance) -> int:
	if card == null or card.definition == null:
		return 0
	var total_requested_eat_count := 0
	for effect in card.definition.effects:
		if effect.kind == BattleTypes.EffectKind.EAT_ENEMY_BLOCK:
			total_requested_eat_count += max(1, effect.amount)
	return total_requested_eat_count

static func _build_eat_preview(state: BattleState, count: int) -> Dictionary:
	var preview := {
		"actual_count": 0,
		"required_volume": 0,
		"target_indices": [],
	}
	if state == null or state.enemy == null or count <= 0:
		return preview
	var limit: int = mini(count, state.enemy.blocks.size())
	var target_indices: Array[int] = []
	var required_volume := 0
	for i in range(limit):
		var block := state.enemy.blocks[i]
		if block == null:
			continue
		required_volume += block.volume
		target_indices.append(i)
	preview.actual_count = target_indices.size()
	preview.required_volume = required_volume
	preview.target_indices = target_indices
	return preview

static func _advance_time_and_resolve(state: BattleState, delta: int) -> void:
	for _step in range(delta):
		if state.is_finished():
			break
		state.battle_time += 1
		_digest_front_food_for_time_step(state)
		_process_enemy_actions_at_current_time(state)
	_refresh_battle_readouts(state)
	_check_outcome(state)

static func _digest_front_food_for_time_step(state: BattleState) -> void:
	if state.stomach.is_empty():
		return
	var front: FoodBlockInstance = state.stomach[0]
	front.remaining_digest_time -= 1
	state.add_log("%s 的消化时间减少到 %d。" % [front.get_display_name(), front.remaining_digest_time])
	while not state.stomach.is_empty():
		var current: FoodBlockInstance = state.stomach[0]
		if current.remaining_digest_time > 0:
			break
		state.stomach.remove_at(0)
		state.add_log("%s 被自然消化完毕。" % current.get_display_name())
		var digest_effects := current.get_digest_effects()
		if not digest_effects.is_empty():
			for effect in digest_effects:
				_apply_effect(state, effect)
				if state.is_finished():
					return

static func _process_enemy_actions_at_current_time(state: BattleState) -> void:
	while state.enemy != null and state.enemy.get_current_action_time() == state.battle_time and not state.is_finished():
		_execute_enemy_action(state)

static func _execute_enemy_action(state: BattleState) -> void:
	var action: EnemyActionData = state.enemy.current_action()
	if action == null:
		state.enemy.next_action_time = -1
		return
	state.last_enemy_action_name = action.display_name
	match action.action_type:
		BattleTypes.EnemyActionType.ATTACK:
			_apply_enemy_attack(state, action.amount + state.enemy.charged_attack_bonus)
			state.enemy.charged_attack_bonus = 0
		BattleTypes.EnemyActionType.ADD_BLOCK:
			var block_definition: Variant = action.payload.get("block_definition", null)
			if block_definition is FoodBlockData:
				state.enemy.add_block(block_definition)
				state.add_log("%s 生成了新的食物块。" % _enemy_name(state))
			else:
				state.add_log("%s 想生成食物块，但当前没有配置内容。" % _enemy_name(state))
		BattleTypes.EnemyActionType.CORRUPT_BLOCK:
			_corrupt_enemy_blocks(state, maxi(1, action.amount))
		BattleTypes.EnemyActionType.CHARGE_ATTACK:
			state.enemy.charged_attack_bonus += action.amount
			state.add_log("%s 正在蓄力，下次攻击额外造成 %d 点伤害。" % [_enemy_name(state), action.amount])
		_:
			state.add_log("%s 暂时没有动作。" % _enemy_name(state))
	state.enemy.advance_action()
	_check_outcome(state)

static func _apply_enemy_attack(state: BattleState, damage: int) -> void:
	var incoming: int = maxi(0, damage)
	var blocked: int = mini(state.player_block, incoming)
	if blocked > 0:
		state.player_block -= blocked
		incoming -= blocked
		state.add_log("防御抵挡了 %d 点伤害。" % blocked)
	if incoming > 0:
		state.player_hp -= incoming
		state.add_log("%s 造成了 %d 点伤害。" % [_enemy_name(state), incoming])
	else:
		state.add_log("%s 的攻击被完全挡下。" % _enemy_name(state))

static func _apply_effect(state: BattleState, effect: BattleEffectData) -> void:
	match effect.kind:
		BattleTypes.EffectKind.DRAW_CARDS:
			for _i in range(max(0, effect.amount)):
				_draw_one_card(state)
		BattleTypes.EffectKind.DISCARD_RANDOM_CARDS:
			for _i in range(max(0, effect.amount)):
				_discard_random_card(state)
		BattleTypes.EffectKind.GAIN_BLOCK:
			state.player_block += max(0, effect.amount)
			state.add_log("获得了 %d 点防御。" % max(0, effect.amount))
		BattleTypes.EffectKind.GAIN_STOMACH_CAPACITY:
			state.player_extra_stomach_capacity += max(0, effect.amount)
			state.add_log("胃容量提升了 %d。" % max(0, effect.amount))
		BattleTypes.EffectKind.EAT_ENEMY_BLOCK:
			_eat_enemy_blocks(state, max(1, effect.amount))
		BattleTypes.EffectKind.DIGEST_STOMACH_ITEM:
			_digest_stomach_item(state)
		BattleTypes.EffectKind.DIGEST_LAST_STOMACH_ITEM:
			_digest_last_stomach_item(state)
		BattleTypes.EffectKind.DIGEST_ALL_STOMACH_ITEMS:
			_digest_all_stomach_items(state)
		BattleTypes.EffectKind.ADVANCE_PURIFICATION:
			_advance_purification(state, effect.purification_action)
		BattleTypes.EffectKind.DELAY_ENEMY_NEXT_ACTION:
			if state.enemy != null:
				state.enemy.delay_next_action(effect.amount)
				state.add_log("敌人的下一次行动延迟了 %d。" % max(0, effect.amount))
		BattleTypes.EffectKind.DELAY_ENEMY_ALL_ACTIONS:
			if state.enemy != null:
				state.enemy.delay_all_actions(effect.amount)
				state.add_log("敌人的后续行动整体延迟了 %d。" % max(0, effect.amount))
		BattleTypes.EffectKind.MOVE_STOMACH_FRONT_TO_BACK:
			_move_stomach_front_to_back(state)
		BattleTypes.EffectKind.MOVE_STOMACH_BACK_TO_FRONT:
			_move_stomach_back_to_front(state)
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

static func _eat_enemy_blocks(state: BattleState, count: int) -> void:
	if state.enemy == null or state.enemy.blocks.is_empty():
		state.add_log("当前没有可吃掉的敌方食物块。")
		return
	var eaten_count: int = 0
	while eaten_count < count and not state.enemy.blocks.is_empty():
		var block: FoodBlockInstance = state.enemy.blocks[0]
		if state.get_stomach_capacity_left() < block.volume:
			state.add_log("胃容量已经满了，剩余食物块无法继续吃下。")
			break
		state.enemy.remove_front_block()
		state.stomach.append(block)
		eaten_count += 1
		state.add_log("吃掉了 %s，剩余消化时间 %d。" % [block.get_display_name(), block.remaining_digest_time])

static func _digest_stomach_item(state: BattleState) -> void:
	if state.stomach.is_empty():
		state.add_log("胃里没有可消化的食物块。")
		return
	var item: FoodBlockInstance = state.stomach[0]
	state.stomach.remove_at(0)
	state.add_log("立即消化了 %s。" % item.get_display_name())
	var digest_effects := item.get_digest_effects()
	if not digest_effects.is_empty():
		for effect in digest_effects:
			_apply_effect(state, effect)

static func _digest_last_stomach_item(state: BattleState) -> void:
	if state.stomach.is_empty():
		state.add_log("胃里没有可消化的食物块。")
		return
	var item: FoodBlockInstance = state.stomach[state.stomach.size() - 1]
	state.stomach.remove_at(state.stomach.size() - 1)
	state.add_log("立即消化了最后一个食物块：%s。" % item.get_display_name())
	var digest_effects := item.get_digest_effects()
	if not digest_effects.is_empty():
		for effect in digest_effects:
			_apply_effect(state, effect)

static func _digest_all_stomach_items(state: BattleState) -> void:
	if state.stomach.is_empty():
		state.add_log("胃里没有可消化的食物块。")
		return
	while not state.stomach.is_empty():
		_digest_stomach_item(state)

static func _corrupt_enemy_blocks(state: BattleState, count: int) -> void:
	if state.enemy == null or state.enemy.blocks.is_empty():
		state.add_log("%s 想让食物块变质，但当前队列是空的。" % _enemy_name(state))
		return
	var corrupted_names: PackedStringArray = []
	for block in state.enemy.blocks:
		if block == null or not block.can_be_corrupted():
			continue
		if block.corrupt():
			corrupted_names.append(block.get_display_name())
		if corrupted_names.size() >= count:
			break
	if corrupted_names.is_empty():
		state.add_log("%s 想让前排食物块变质，但当前已经没有可变质的“好”食物块了。" % _enemy_name(state))
		return
	state.add_log("%s 让前排 %d 个好食物块变质了：%s。" % [
		_enemy_name(state),
		corrupted_names.size(),
		"、".join(corrupted_names),
	])

static func _move_stomach_front_to_back(state: BattleState) -> void:
	if state.stomach.size() <= 1:
		return
	var item: FoodBlockInstance = state.stomach.pop_front()
	state.stomach.append(item)
	state.add_log("胃中最前方的食物块已移到最后。")

static func _move_stomach_back_to_front(state: BattleState) -> void:
	if state.stomach.size() <= 1:
		return
	var item: FoodBlockInstance = state.stomach.pop_back()
	state.stomach.push_front(item)
	state.add_log("胃中最后方的食物块已移到最前。")

static func _discard_random_card(state: BattleState) -> void:
	if state.hand.is_empty():
		state.add_log("没有可弃掉的手牌。")
		return
	var discard_index: int = randi() % state.hand.size()
	var card: CardInstance = state.hand[discard_index]
	state.hand.remove_at(discard_index)
	state.discard_pile.append(card)
	state.add_log("随机弃掉了 %s。" % card.get_display_name())

static func _advance_purification(state: BattleState, action: BattleTypes.PurificationActionType) -> void:
	if state.enemy == null:
		state.add_log("当前没有敌人可供净化。")
		return
	var step: PurificationStepData = state.enemy.complete_purification_action(action)
	if step == null:
		state.add_log("当前没有匹配的净化任务。")
		return
	state.add_log("完成了净化任务：%s。" % step.display_name)

static func _draw_to_target_hand_size(state: BattleState) -> void:
	while state.hand.size() < mini(state.player_starting_hand_size, state.player_max_hand_size):
		var before_count: int = state.hand.size()
		_draw_one_card(state)
		if state.hand.size() == before_count:
			break

static func _draw_one_card(state: BattleState) -> void:
	if state.hand.size() >= state.player_max_hand_size:
		state.add_log("手牌已满，无法继续抽牌。")
		return
	if state.draw_pile.is_empty():
		_shuffle_discard_into_draw_pile(state)
	if state.draw_pile.is_empty():
		state.add_log("没有可以抽取的卡牌了。")
		return
	var card: CardInstance = state.draw_pile.pop_back()
	state.hand.append(card)
	state.add_log("抽到了 %s。" % card.get_display_name())

static func _refresh_battle_readouts(state: BattleState) -> void:
	state.set_timeline(_build_timeline_preview(state))
	_update_enemy_intent(state)

static func _record_card_effect(state: BattleState, card: CardInstance) -> void:
	state.add_card_effect_record(CardEffectRecord.from_card(
		card,
		state.battle_time,
		state.last_played_effect_summary,
		state.last_played_sequence
	))

static func _build_timeline_preview(state: BattleState) -> Array[String]:
	var entries: Array[String] = []
	var start_time: int = TIMELINE_HISTORY_START_TIME
	var end_time: int = max(start_time, state.battle_time + TIMELINE_FUTURE_PREVIEW_SLOTS)
	for time_point in range(start_time, end_time + 1):
		var marker: String = "%dt" % time_point
		if state.enemy != null:
			var action_labels: Array[String] = state.enemy.get_action_labels_at_time(time_point)
			if not action_labels.is_empty():
				marker = "%dt %s" % [time_point, "/".join(action_labels)]
		entries.append(marker)
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

static func _check_outcome(state: BattleState) -> void:
	if state.outcome != BattleTypes.BattleOutcome.ONGOING:
		return
	if state.player_hp <= 0:
		state.outcome = BattleTypes.BattleOutcome.DEFEAT
		state.phase = BattleTypes.BattlePhase.FINISHED
		state.add_log("你被击败了。")
		return
	if state.enemy == null:
		return
	if state.enemy.is_purified():
		state.outcome = BattleTypes.BattleOutcome.VICTORY_PURIFIED
		state.phase = BattleTypes.BattlePhase.FINISHED
		state.add_log("所有净化任务均已完成。")
		return
	if state.enemy.is_cleared():
		state.outcome = BattleTypes.BattleOutcome.VICTORY_CLEARED
		state.phase = BattleTypes.BattlePhase.FINISHED
		state.add_log("敌人的食物块已被吃完。")

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
	state.add_log("弃牌堆洗回了抽牌堆。")

static func _refresh_after_state_change(state: BattleState) -> void:
	state.set_timeline(_build_timeline_preview(state))
	_update_enemy_intent(state)

static func _refresh_enemy_preview(state: BattleState) -> void:
	_update_enemy_intent(state)

static func _enemy_actions_between(state: BattleState, start_time: int, end_time: int) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if state == null or state.enemy == null:
		return actions
	for time_point in range(start_time + 1, end_time + 1):
		var labels := state.enemy.get_action_labels_at_time(time_point)
		if labels.is_empty():
			continue
		actions.append({
			"time_point": time_point,
			"labels": labels.duplicate(),
		})
	return actions

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
		BattleTypes.EffectKind.GAIN_BLOCK:
			return "获得 %d 点防御" % max(0, effect.amount)
		BattleTypes.EffectKind.EAT_ENEMY_BLOCK:
			return "吃 %d 个食物块" % max(1, effect.amount)
		BattleTypes.EffectKind.DIGEST_STOMACH_ITEM:
			return "立即消化胃里最前方食物块"
		BattleTypes.EffectKind.ADVANCE_PURIFICATION:
			return "净化%s" % _purification_action_name(effect.purification_action)
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
		BattleTypes.PurificationActionType.WASH:
			return "“脏污”"
		BattleTypes.PurificationActionType.TRIM:
			return "“腐败”"
		BattleTypes.PurificationActionType.CORRECT:
			return "“劣质”"
		BattleTypes.PurificationActionType.DEWORM:
			return "“虫蚀”"
		BattleTypes.PurificationActionType.PURGE:
			return "“污秽”"
		_:
			return "净化任务"
