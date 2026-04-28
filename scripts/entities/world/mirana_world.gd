extends Area2D
class_name MiranaWorld

signal dialogue_requested

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $Label

var player_in_range := false
var dialogue_open := false
var recruited := false

func _ready() -> void:
	prompt_label.hide()
	sprite.play("mirana_idle")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if recruited:
		return
	if dialogue_open:
		return
	if not player_in_range:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_start_dialogue()

func _on_body_entered(body: Node) -> void:
	if recruited:
		return
	if body is CharacterBody2D:
		player_in_range = true
		prompt_label.show()

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		prompt_label.hide()

func _start_dialogue() -> void:
	dialogue_open = true
	prompt_label.hide()
	dialogue_requested.emit()

func close_dialogue() -> void:
	dialogue_open = false
	if player_in_range and not recruited:
		prompt_label.show()

func recruit() -> void:
	recruited = true
	player_in_range = false
	prompt_label.hide()
	monitoring = false
