extends Control

func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
	SceneTransition.fade_transition_to_scene("res://ui/splash_screen.tscn")
