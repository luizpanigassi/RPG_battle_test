extends Control

@onready var button: Button = $Button

func _ready() -> void:
	button.pressed.connect(_transition)
	
func _transition() -> void:
	SceneTransition.fade_transition_to_scene("res://ui/splash_screen.tscn")
