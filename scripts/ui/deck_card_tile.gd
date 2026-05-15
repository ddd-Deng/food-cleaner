extends Control
class_name DeckCardTile

const CARD_BODY_REGION := Rect2(332, 191, 336, 448)
const ATTACK_CARD_TEXTURE: Texture2D = preload("res://sprites/攻击卡.png")
const SKILL_CARD_TEXTURE: Texture2D = preload("res://sprites/技能卡.png")
const PURIFY_CARD_TEXTURE: Texture2D = preload("res://sprites/净化卡.png")

@onready var background: TextureRect = $Background
@onready var quantity_badge: PanelContainer = $QuantityBadge
@onready var quantity_label: Label = $QuantityBadge/QuantityLabel
@onready var cost_label: Label = $Margin/Content/TopRow/CostLabel
@onready var name_label: Label = $Margin/Content/TopRow/NameLabel
@onready var art_label: Label = $Margin/Content/ArtSpacer/ArtLabel
@onready var description_label: Label = $Margin/Content/DescriptionSpacer/DescriptionLabel

var _card_data: CardData
var _quantity: int = 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_quantity_badge_style()
	_refresh_content()

func setup_from_definition(card_data: CardData, quantity: int = 1) -> void:
	_card_data = card_data
	_quantity = max(1, quantity)
	_refresh_content()

func _refresh_content() -> void:
	if not is_node_ready():
		return
	quantity_label.text = "x%d" % _quantity
	if _card_data == null:
		cost_label.text = "-t"
		name_label.text = "未知卡牌"
		art_label.text = "?"
		description_label.text = "当前卡牌缺少定义数据。"
		background.texture = _build_card_atlas(ATTACK_CARD_TEXTURE)
		return
	cost_label.text = "%dt" % max(0, _card_data.time_cost)
	name_label.text = _card_data.display_name
	art_label.text = _card_data.art_label if not _card_data.art_label.is_empty() else _fallback_art_label(_card_data.display_name)
	description_label.text = _card_data.description
	background.texture = _build_card_atlas(_texture_for_type(_card_data.card_type))

func _apply_quantity_badge_style() -> void:
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.28, 0.18, 0.08, 0.94)
	badge_style.border_color = Color(0.86, 0.72, 0.34, 1.0)
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left = 8
	badge_style.corner_radius_top_right = 8
	badge_style.corner_radius_bottom_left = 8
	badge_style.corner_radius_bottom_right = 8
	quantity_badge.add_theme_stylebox_override("panel", badge_style)
	quantity_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.82, 1.0))

func _texture_for_type(card_type: BattleTypes.CardType) -> Texture2D:
	match card_type:
		BattleTypes.CardType.ATTACK:
			return ATTACK_CARD_TEXTURE
		BattleTypes.CardType.SKILL:
			return SKILL_CARD_TEXTURE
		BattleTypes.CardType.PURIFY:
			return PURIFY_CARD_TEXTURE
		_:
			return ATTACK_CARD_TEXTURE

func _build_card_atlas(texture: Texture2D) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = CARD_BODY_REGION
	return atlas

func _fallback_art_label(card_name: String) -> String:
	if card_name.is_empty():
		return "?"
	return card_name.substr(0, 1)
