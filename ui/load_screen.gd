extends Control

@onready var game_1_button: Button = $CenterContainer/VBoxContainer/LoadGameButton1
@onready var back_button: Button = $BackButton

func _ready():
	game_1_button.pressed.connect(_on_1_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
func _on_1_button_pressed() -> void:
	print("HAHA, nothing happens")

func _on_back_button_pressed() -> void:
	SceneTransition.transition_to_scene("res://ui/splash_screen.tscn")
