extends Area2D
class_name BadguyWorld

signal boss_dialogue_requested

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $Label

var player_in_range := false
var boss_dialogue_open := false

func _ready() -> void:
	prompt_label.hide()
	sprite.play("badguy_idle")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if boss_dialogue_open:
		return
	if not player_in_range:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_start_dialogue()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		player_in_range = true
		prompt_label.show()

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		prompt_label.hide()

func _start_dialogue() -> void:
	boss_dialogue_open = true
	prompt_label.hide()
	boss_dialogue_requested.emit()

func close_dialogue() -> void:
	boss_dialogue_open = false
	if player_in_range:
		prompt_label.show()
	
