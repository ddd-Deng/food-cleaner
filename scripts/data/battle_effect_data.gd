extends Resource
class_name BattleEffectData

@export var kind: BattleTypes.EffectKind = BattleTypes.EffectKind.NONE
@export var amount: int = 0
@export var target: BattleTypes.CardTarget = BattleTypes.CardTarget.NONE
@export var purification_action: BattleTypes.PurificationActionType = BattleTypes.PurificationActionType.NONE
@export var payload: Dictionary = {}
@export var description: String = ""
