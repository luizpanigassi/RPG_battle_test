extends Area2D
class_name HolyMcguffin

signal pickup_requested

@onready var sprite: Sprite2D = $Sprite2D
@onready var holy_label: Label = $Label

var player_in_holy_range := false
var pickup_open := false
var collected := false

func _ready() -> void:
	holy_label.hide()
	body_entered.connect(_on_holy_entered)
	body_exited.connect(_on_holy_exited)

func _unhandled_input(event: InputEvent) -> void:
	if collected:
		return
	if pickup_open:
		return
	if not player_in_holy_range:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_start_holy_dialogue()

func _on_holy_entered(body: Node) -> void:
	if collected:
		return
	if body is CharacterBody2D:
		player_in_holy_range = true
		holy_label.show()

func _on_holy_exited(body: Node) -> void:
	if body is CharacterBody2D:
		player_in_holy_range = false
		holy_label.hide()

func _start_holy_dialogue() -> void:
	pickup_open = true
	holy_label.hide()
	pickup_requested.emit()

func close_holy_dialogue() -> void:
	pickup_open = false
	if player_in_holy_range and not collected:
		holy_label.show()

func collect() -> void:
	collected = true
	player_in_holy_range = false
	holy_label.hide()
	monitoring = false
	sprite.hide()
