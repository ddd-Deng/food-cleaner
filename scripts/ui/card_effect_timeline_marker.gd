extends TextureRect
class_name CardEffectTimelineMarker

signal preview_requested(records: Array[CardEffectRecord], marker_global_rect: Rect2)
signal preview_dismissed

var records: Array[CardEffectRecord] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(new_records: Array[CardEffectRecord], marker_texture: Texture2D, marker_position: Vector2, marker_size: Vector2) -> void:
	records = new_records.duplicate()
	texture = marker_texture
	position = marker_position
	size = marker_size

func _on_mouse_entered() -> void:
	preview_requested.emit(records, get_global_rect())

func _on_mouse_exited() -> void:
	preview_dismissed.emit()
