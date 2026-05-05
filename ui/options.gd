extends Control

@onready var test_button: Button = $CenterContainer/VBoxContainer/WishButton
@onready var back_button: Button = $BackButton
@onready var wish_label: Label = $WishLabel

func _ready():
	test_button.pressed.connect(_on_1_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	wish_label.hide()
	
func _on_1_button_pressed() -> void:
	print("HAHA, nothing happens")
	wish_label.show()
	await get_tree().create_timer(2).timeout
	wish_label.hide()

func _on_back_button_pressed() -> void:
	SceneTransition.fade_transition_to_scene("res://ui/splash_screen.tscn")
