extends Resource
class_name EnemyData

@export var id: StringName = &""
@export var display_name: String = "敌人"
@export var food_blocks: Array[FoodBlockData] = []
@export var purification_steps: Array[PurificationStepData] = []
@export var actions: Array[EnemyActionData] = []
@export var description: String = ""
