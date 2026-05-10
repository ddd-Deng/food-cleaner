extends Resource
class_name EnemyActionData

@export var id: StringName = &""
@export var display_name: String = "敌人行动"
@export var action_type: BattleTypes.EnemyActionType = BattleTypes.EnemyActionType.NONE
@export var time_delay: int = 0
@export var amount: int = 0
@export var payload: Dictionary = {}
@export var description: String = ""
