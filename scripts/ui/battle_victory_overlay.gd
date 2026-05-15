extends Control
class_name BattleVictoryOverlay

signal continue_pressed

const BACKDROP_COLOR := Color(0.06, 0.05, 0.03, 0.74)

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = $Center/PanelRoot/OuterPanel/OuterMargin/Column/TitleCenter/TitlePanel/TitleLabel
@onready var summary_label: Label = $Center/PanelRoot/OuterPanel/OuterMargin/Column/SummaryLabel
@onready var gold_main_label: Label = $Center/PanelRoot/OuterPanel/OuterMargin/Column/InnerPanel/InnerMargin/RewardsColumn/GoldRewardPanel/GoldMargin/GoldRow/GoldTextColumn/GoldMainLabel
@onready var gold_sub_label: Label = $Center/PanelRoot/OuterPanel/OuterMargin/Column/InnerPanel/InnerMargin/RewardsColumn/GoldRewardPanel/GoldMargin/GoldRow/GoldTextColumn/GoldSubLabel
@onready var card_main_label: Label = $Center/PanelRoot/OuterPanel/OuterMargin/Column/InnerPanel/InnerMargin/RewardsColumn/CardRewardPanel/CardMargin/CardRow/CardTextColumn/CardMainLabel
@onready var card_sub_label: Label = $Center/PanelRoot/OuterPanel/OuterMargin/Column/InnerPanel/InnerMargin/RewardsColumn/CardRewardPanel/CardMargin/CardRow/CardTextColumn/CardSubLabel
@onready var footer_hint_label: Label = $Center/PanelRoot/OuterPanel/OuterMargin/Column/InnerPanel/InnerMargin/RewardsColumn/FooterHintLabel
@onready var continue_button: Button = $Center/PanelRoot/OuterPanel/OuterMargin/Column/ContinueCenter/ContinueButton

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.color = BACKDROP_COLOR
	continue_button.pressed.connect(_emit_continue)
	hide_overlay()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_emit_continue()

func show_result(data: Dictionary) -> void:
	title_label.text = String(data.get("title", "战斗胜利"))

	var summary_text: String = String(data.get("summary", "本次奖励预览"))
	summary_label.text = summary_text
	summary_label.visible = not summary_text.is_empty()

	var gold_reward: int = max(0, int(data.get("gold_reward", 0)))
	gold_main_label.text = String(data.get("gold_main", "获得 %d 金币" % gold_reward if gold_reward > 0 else "本场暂无金币奖励"))
	var gold_sub_text: String = String(data.get("gold_sub", "确认后结算"))
	gold_sub_label.text = gold_sub_text
	gold_sub_label.visible = not gold_sub_text.is_empty()

	card_main_label.text = String(data.get("card_main", "将 1 张牌加入你的牌组"))
	var card_sub_text: String = String(data.get("card_sub", "当前为展示占位"))
	card_sub_label.text = card_sub_text
	card_sub_label.visible = not card_sub_text.is_empty()

	var footer_hint_text: String = String(data.get("footer_hint", "奖励逻辑后续接入"))
	footer_hint_label.text = footer_hint_text
	footer_hint_label.visible = not footer_hint_text.is_empty()

	continue_button.text = String(data.get("continue_text", "继续探索"))

	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	call_deferred("_focus_continue_button")

func hide_overlay() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_open() -> bool:
	return visible

func _focus_continue_button() -> void:
	if continue_button != null:
		continue_button.grab_focus()

func _emit_continue() -> void:
	continue_pressed.emit()
