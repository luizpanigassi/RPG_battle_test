extends Control

@onready var game_1_button: Button = $CenterContainer/VBoxContainer/LoadGameButton1
@onready var back_button: Button = $BackButton
@onready var lol_label: Label = $LOLLabel

func _ready():
	game_1_button.pressed.connect(_on_1_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	lol_label.hide()
	
func _on_1_button_pressed() -> void:
	print("HAHA, nothing happens")
	lol_label.show()
	await get_tree().create_timer(2).timeout
	lol_label.hide()

func _on_back_button_pressed() -> void:
	SceneTransition.fade_transition_to_scene("res://ui/splash_screen.tscn")
