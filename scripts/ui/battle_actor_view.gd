extends Control
class_name BattleActorView

const MODE_PLAYER: StringName = &"player"
const MODE_ENEMY: StringName = &"enemy"

var _actor_mode: StringName = MODE_PLAYER
var _player_hp: int = 0
var _player_max_hp: int = 1
var _player_block: int = 0
var _player_stomach_used: int = 0
var _player_stomach_capacity: int = 0

var _enemy_name: String = "敌人"
var _enemy_intent: String = "待机"
var _enemy_purification_done: int = 0
var _enemy_purification_total: int = 0
var _enemy_block_count: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(132, 156)

func set_actor_mode(mode: StringName) -> void:
	_actor_mode = mode
	queue_redraw()

func set_player_snapshot(hp: int, max_hp: int, block: int, stomach_used: int, stomach_capacity: int) -> void:
	_player_hp = max(0, hp)
	_player_max_hp = max(1, max_hp)
	_player_block = max(0, block)
	_player_stomach_used = max(0, stomach_used)
	_player_stomach_capacity = max(0, stomach_capacity)
	queue_redraw()

func set_enemy_snapshot(enemy_name: String, intent: String, purification_done: int, purification_total: int, block_count: int) -> void:
	_enemy_name = enemy_name if not enemy_name.is_empty() else "敌人"
	_enemy_intent = intent if not intent.is_empty() else "待机"
	_enemy_purification_done = max(0, purification_done)
	_enemy_purification_total = max(0, purification_total)
	_enemy_block_count = max(0, block_count)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.22, 0.22, 0.22, 0.15), true)
	if _actor_mode == MODE_ENEMY:
		_draw_enemy(rect)
	else:
		_draw_player(rect)

func _draw_player(rect: Rect2) -> void:
	var base_y: float = rect.size.y * 0.88
	var center_x: float = rect.size.x * 0.50
	var body_color := Color(0.82, 0.86, 0.74, 1.0)
	var accent_color := Color(0.95, 0.78, 0.36, 1.0)
	var outline := Color(0.10, 0.10, 0.10, 1.0)

	_draw_oval(Rect2(center_x - 34.0, base_y - 10.0, 68.0, 14.0), Color(0.05, 0.05, 0.05, 0.30))
	draw_circle(Vector2(center_x, base_y - 72.0), 19.0, body_color)
	draw_line(Vector2(center_x, base_y - 52.0), Vector2(center_x, base_y - 10.0), outline, 8.0)
	draw_line(Vector2(center_x - 7.0, base_y - 10.0), Vector2(center_x - 20.0, base_y + 22.0), outline, 8.0)
	draw_line(Vector2(center_x + 7.0, base_y - 10.0), Vector2(center_x + 20.0, base_y + 22.0), outline, 8.0)
	draw_line(Vector2(center_x - 4.0, base_y - 38.0), Vector2(center_x - 28.0, base_y - 28.0), outline, 7.0)
	draw_line(Vector2(center_x + 4.0, base_y - 38.0), Vector2(center_x + 25.0, base_y - 40.0), outline, 7.0)
	draw_line(Vector2(center_x + 24.0, base_y - 42.0), Vector2(center_x + 42.0, base_y - 64.0), outline, 5.5)
	draw_circle(Vector2(center_x + 45.0, base_y - 68.0), 8.0, accent_color)
	draw_circle(Vector2(center_x + 45.0, base_y - 68.0), 8.0, Color(0, 0, 0, 0), false, 2.5)

func _draw_enemy(rect: Rect2) -> void:
	var base_y: float = rect.size.y * 0.90
	var center_x: float = rect.size.x * 0.50
	var outline := Color(0.10, 0.10, 0.10, 1.0)

	_draw_oval(Rect2(center_x - 40.0, base_y - 10.0, 80.0, 14.0), Color(0.05, 0.05, 0.05, 0.30))
	var tray := PackedVector2Array([
		Vector2(center_x - 42.0, base_y - 72.0),
		Vector2(center_x + 30.0, base_y - 80.0),
		Vector2(center_x + 44.0, base_y - 34.0),
		Vector2(center_x - 26.0, base_y - 20.0),
	])
	draw_colored_polygon(tray, Color(0.42, 0.36, 0.30, 1.0))
	_draw_polyline_loop(tray, outline, 3.0)

	draw_rect(Rect2(center_x - 30.0, base_y - 68.0, 24.0, 18.0), Color(0.88, 0.88, 0.78, 1.0), true)
	draw_rect(Rect2(center_x - 2.0, base_y - 64.0, 20.0, 16.0), Color(0.58, 0.30, 0.26, 1.0), true)
	draw_rect(Rect2(center_x + 22.0, base_y - 60.0, 14.0, 14.0), Color(0.36, 0.56, 0.30, 1.0), true)
	draw_circle(Vector2(center_x - 10.0, base_y - 40.0), 7.0, Color(0.74, 0.66, 0.28, 1.0))
	draw_circle(Vector2(center_x + 12.0, base_y - 36.0), 9.0, Color(0.40, 0.22, 0.18, 1.0))
	draw_circle(Vector2(center_x + 28.0, base_y - 28.0), 6.0, Color(0.28, 0.48, 0.24, 1.0))

func _draw_polyline_loop(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	for index in range(points.size()):
		var next_index: int = (index + 1) % points.size()
		draw_line(points[index], points[next_index], color, width)

func _draw_oval(rect: Rect2, color: Color, point_count: int = 24) -> void:
	var points := PackedVector2Array()
	var center := rect.get_center()
	var radius_x: float = rect.size.x * 0.5
	var radius_y: float = rect.size.y * 0.5
	for index in range(point_count):
		var angle: float = TAU * float(index) / float(point_count)
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)
