extends Resource
class_name CardData

@export var id: StringName = &""
@export var display_name: String = "Card"
@export var time_cost: int = 1
@export var card_type: BattleTypes.CardType = BattleTypes.CardType.NONE
@export var art_label: String = ""
@export var description: String = ""
@export var target: BattleTypes.CardTarget = BattleTypes.CardTarget.NONE
@export var tags: Array[StringName] = []
@export var effects: Array[BattleEffectData] = []
