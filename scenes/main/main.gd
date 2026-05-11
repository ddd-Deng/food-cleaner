extends Control

const RUN_CONTROLLER_SCRIPT := preload("res://scripts/run/run_controller.gd")

func _ready() -> void:
	var run_controller := RUN_CONTROLLER_SCRIPT.new()
	add_child(run_controller)
