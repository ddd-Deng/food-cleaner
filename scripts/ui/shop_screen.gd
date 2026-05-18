@tool
extends Control
class_name ShopScreen

signal exit_requested

const CONFIRM_NORMAL: Texture2D = preload("res://sprites/map/商店界面/confirm.png")
const CONFIRM_ACTIVE: Texture2D = preload("res://sprites/map/商店界面/confirm2.png")
const CANCEL_NORMAL: Texture2D = preload("res://sprites/map/商店界面/cancel.png")
const CANCEL_ACTIVE: Texture2D = preload("res://sprites/map/商店界面/cancel2.png")
const EXIT_NORMAL: Texture2D = preload("res://sprites/map/商店界面/exit.png")
const EXIT_ACTIVE: Texture2D = preload("res://sprites/map/商店界面/exit2.png")

var _preview_visible := false

@onready var _confirm_layer: TextureRect = $ButtonLayers/ConfirmLayer
@onready var _cancel_layer: TextureRect = $ButtonLayers/CancelLayer
@onready var _exit_layer: TextureRect = $ButtonLayers/ExitLayer

@onready var _confirm_button: Button = $Hotspots/ConfirmButton
@onready var _cancel_button: Button = $Hotspots/CancelButton
@onready var _exit_button: Button = $Hotspots/ExitButton

@onready var _preview_nodes: Array[CanvasItem] = [
	$Hotspots/ConfirmButton/PreviewRect,
	$Hotspots/ConfirmButton/PreviewLabel,
	$Hotspots/CancelButton/PreviewRect,
	$Hotspots/CancelButton/PreviewLabel,
	$Hotspots/ExitButton/PreviewRect,
	$Hotspots/ExitButton/PreviewLabel,
]


func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)
	_apply_preview_visibility(Engine.is_editor_hint())
	_refresh_button_layers()


func _process(_delta: float) -> void:
	var should_show_preview := Engine.is_editor_hint()
	if should_show_preview != _preview_visible:
		_apply_preview_visibility(should_show_preview)
	_refresh_button_layers()


func _apply_preview_visibility(should_show: bool) -> void:
	_preview_visible = should_show
	for preview_node in _preview_nodes:
		if is_instance_valid(preview_node):
			preview_node.visible = should_show


func _refresh_button_layers() -> void:
	_confirm_layer.texture = _pick_button_texture(_confirm_button, CONFIRM_NORMAL, CONFIRM_ACTIVE)
	_cancel_layer.texture = _pick_button_texture(_cancel_button, CANCEL_NORMAL, CANCEL_ACTIVE)
	_exit_layer.texture = _pick_button_texture(_exit_button, EXIT_NORMAL, EXIT_ACTIVE)


func _pick_button_texture(button: BaseButton, normal_texture: Texture2D, active_texture: Texture2D) -> Texture2D:
	var draw_mode := button.get_draw_mode()
	if draw_mode == BaseButton.DRAW_HOVER or draw_mode == BaseButton.DRAW_PRESSED or draw_mode == BaseButton.DRAW_HOVER_PRESSED:
		return active_texture
	return normal_texture


func _on_confirm_pressed() -> void:
	pass


func _on_cancel_pressed() -> void:
	pass


func _on_exit_pressed() -> void:
	exit_requested.emit()
