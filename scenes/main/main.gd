extends Control

const RUN_CONTROLLER_SCRIPT := preload("res://scripts/run/run_controller.gd")
const SCENE_TRANSITION_OVERLAY_SCENE := preload("res://scenes/ui/scene_transition_overlay.tscn")

func _ready() -> void:
	var run_controller := RUN_CONTROLLER_SCRIPT.new()
	add_child(run_controller)
	var transition_overlay := SCENE_TRANSITION_OVERLAY_SCENE.instantiate() as SceneTransitionOverlay
	if transition_overlay != null:
		add_child(transition_overlay)
		run_controller.set_transition_overlay(transition_overlay)
