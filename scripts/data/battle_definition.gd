extends Resource
class_name BattleDefinition

@export var id: StringName = &""
@export var display_name: String = "Battle"
@export var player_max_hp: int = 20
@export var player_max_hand_size: int = 8
@export var player_starting_hand_size: int = 4
@export var player_max_stomach_volume: int = 3
@export var starting_items: Array[PlayerItemData] = []
@export var starting_deck: Array[CardPileEntryData] = []
@export var enemy: EnemyData
@export var description: String = ""
