extends Control

@onready var start_button: Button = $ButtonsContainer/StartButton
@onready var load_button: Button = $ButtonsContainer/LoadButton
@onready var options_button: Button = $ButtonsContainer/OptionsButton
@onready var quit_button: Button = $ButtonsContainer/QuitButton

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	GameManager.reset_run()
	SceneTransition.transition_to_scene("res://scenes/world/overworld.tscn")

func _on_load_button_pressed() -> void:
	SceneTransition.fade_transition_to_scene("res://ui/load_screen.tscn")

func _on_options_button_pressed() -> void:
	SceneTransition.fade_transition_to_scene("res://ui/options.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
