extends Control
class_name DeckCardTile

const CARD_BODY_REGION := Rect2(399, 47, 366, 506)
const ATTACK_CARD_TEXTURE: Texture2D = preload("res://sprites/红.png")
const SKILL_CARD_TEXTURE: Texture2D = preload("res://sprites/蓝.png")
const PURIFY_CARD_TEXTURE: Texture2D = preload("res://sprites/绿.png")
const CARD_FONT: FontFile = preload("res://黄油面包体.ttf")

@onready var background: TextureRect = $Background
@onready var quantity_badge: PanelContainer = $QuantityBadge
@onready var quantity_label: Label = $QuantityBadge/QuantityLabel
@onready var cost_sprite: TextureRect = $CostSprite
@onready var name_label: Label = $NameLabel
@onready var art_label: Label = $ArtLabel
@onready var description_label: Label = $DescriptionLabel

var _card_data: CardData
var _quantity: int = 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_card_font()
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
		_refresh_cost_sprite(0, BattleTypes.CardType.ATTACK)
		name_label.text = "未知卡牌"
		art_label.text = "?"
		description_label.text = "当前卡牌缺少定义数据。"
		background.texture = _build_card_atlas(ATTACK_CARD_TEXTURE)
		return
	_refresh_cost_sprite(_card_data.time_cost, _card_data.card_type)
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

func _apply_card_font() -> void:
	var card_theme := Theme.new()
	card_theme.default_font = CARD_FONT
	theme = card_theme

func _refresh_cost_sprite(time_cost: int, card_type: BattleTypes.CardType) -> void:
	if cost_sprite == null:
		return
	var color_dir := _digit_color_dir_for_type(card_type)
	var digit := clampi(time_cost, 0, 9)
	var digit_texture := load("res://sprites/数字/%s/%d.png" % [color_dir, digit]) as Texture2D
	if digit_texture == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = digit_texture
	atlas.region = Rect2(413, 63, 54, 63)
	cost_sprite.texture = atlas

func _digit_color_dir_for_type(card_type: BattleTypes.CardType) -> String:
	match card_type:
		BattleTypes.CardType.ATTACK:
			return "红"
		BattleTypes.CardType.SKILL:
			return "蓝"
		BattleTypes.CardType.PURIFY:
			return "绿"
		_:
			return "红"
