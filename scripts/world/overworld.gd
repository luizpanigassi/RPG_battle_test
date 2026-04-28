extends Node2D

@onready var mirana_world: MiranaWorld = $MiranaWorld
@onready var player_world: CharacterBody2D = $PlayerWorld
@onready var ui_layer: CanvasLayer = $UILayer

var dialog_scene = preload("res://ui/dialog.tscn")
var dialog_instance: DialogScreen = null

func _ready() -> void:
	mirana_world.dialogue_requested.connect(_on_mirana_dialogue_requested)

func _on_mirana_dialogue_requested() -> void:
	if dialog_instance != null and is_instance_valid(dialog_instance):
		return
	
	dialog_instance = dialog_scene.instantiate()
	ui_layer.add_child(dialog_instance)

	dialog_instance.accepted.connect(_on_dialog_accepted)
	dialog_instance.declined.connect(_on_dialog_declined)
	dialog_instance.closed.connect(_on_dialog_closed)

	player_world.velocity = Vector2.ZERO
	player_world.set_physics_process(false)

	dialog_instance.open_dialogue(
		"Mirana",
		"Hi, I'm Mirana! I am also a hero of light, destined to fight the evil lord Badguy! Do you want me to join you in your cause? I'm sure you can't continue without me!",
		"Yes!",
		"No"
	)

func _on_dialog_accepted() -> void:
	GameManager.add_party_member("mirana")
	mirana_world.recruit()
	mirana_world.call_deferred("queue_free")
	player_world.set_physics_process(true)

func _on_dialog_declined() -> void:
	player_world.set_physics_process(true)
	mirana_world.close_dialogue()

func _on_dialog_closed() -> void:
	if dialog_instance != null and is_instance_valid(dialog_instance):
		dialog_instance.queue_free()
	player_world.set_physics_process(true)
	dialog_instance = null
	mirana_world.close_dialogue()
