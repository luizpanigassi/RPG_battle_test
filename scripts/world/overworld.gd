extends Node2D

@onready var mirana_world: MiranaWorld = $MiranaWorld
@onready var player_world: CharacterBody2D = $PlayerWorld
@onready var badguy_world: BadguyWorld = $BadguyWorld
@onready var holy_mcguffin: HolyMcguffin = $HolyMcguffin
@onready var ui_layer: CanvasLayer = $UILayer

var dialog_scene = preload("res://ui/dialog.tscn")
var dialog_instance: DialogScreen = null
var boss_dialog_scene = preload("res://ui/badguy_dialog.tscn")
var boss_dialog_instance: BadguyDialog = null
var holy_dialog_scene = preload("res://ui/holy_mcguffin_dialog.tscn")
var holy_dialog_instance: HolyMcguffinDialog = null
var pending_mirana_info: bool = false

func _ready() -> void:
	mirana_world.dialogue_requested.connect(_on_mirana_dialogue_requested)
	badguy_world.boss_dialogue_requested.connect(_on_boss_dialogue_requested)
	holy_mcguffin.pickup_requested.connect(_on_pickup_requested)


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
	pending_mirana_info = true

func _on_dialog_declined() -> void:
	player_world.set_physics_process(true)
	mirana_world.close_dialogue()

func _on_dialog_closed() -> void:
	if dialog_instance != null and is_instance_valid(dialog_instance):
		dialog_instance.queue_free()
	player_world.set_physics_process(true)
	dialog_instance = null
	if pending_mirana_info:
		pending_mirana_info = false
		mirana_world.close_dialogue()
		_open_mirana_info_dialog()
		return

func _open_mirana_info_dialog() -> void:
	if dialog_instance != null and is_instance_valid(dialog_instance):
		return
	
	dialog_instance = dialog_scene.instantiate()
	ui_layer.add_child(dialog_instance)
	
	dialog_instance.accepted.connect(_on_mirana_info_ok)
	dialog_instance.closed.connect(_on_mirana_info_closed)

	dialog_instance.open_dialogue(
		"Mirana",
		"Great! Now, we will need the Holy McGuffin. It should be in a clearing near here!",
		"OK",
		""
	)

	dialog_instance.decline_button.visible = false
	dialog_instance.decline_button.disabled = true

func _on_mirana_info_ok() -> void:
	pass

func _on_mirana_info_closed() -> void:
	if dialog_instance != null and is_instance_valid(dialog_instance):
		dialog_instance.queue_free()
		dialog_instance = null
		player_world.set_physics_process(true)


func _on_boss_dialogue_requested() -> void:
	if boss_dialog_instance != null and is_instance_valid(boss_dialog_instance):
		return

	boss_dialog_instance = boss_dialog_scene.instantiate()
	ui_layer.add_child(boss_dialog_instance)

	boss_dialog_instance.boss_accepted.connect(_on_boss_dialogue_accepted)
	boss_dialog_instance.boss_declined.connect(_on_boss_dialogue_declined)
	boss_dialog_instance.boss_closed.connect(_on_boss_dialog_closed)

	player_world.velocity = Vector2.ZERO
	player_world.set_physics_process(false)

	boss_dialog_instance.boss_dialog_open(
		"Tim, the Badguy",
		"I am the evil necromancer! There are some who call me... Tim. Do you wish to face me in battle?",
		"I fear no evil! Fight me!",
		"I fear all evil, and I will run like the chicken I am"
		)

func _on_boss_dialogue_accepted() -> void:
	GameManager.set_pending_encounter(["badguy"])
	SceneTransition.transition_to_scene("res://scenes/battle/battle_scene.tscn")

func _on_boss_dialogue_declined() -> void:
	player_world.set_physics_process(true)
	badguy_world.close_dialogue()

func _on_boss_dialog_closed() -> void:
	if boss_dialog_instance != null and is_instance_valid(boss_dialog_instance):
		boss_dialog_instance.queue_free()
	player_world.set_physics_process(true)
	boss_dialog_instance = null
	badguy_world.close_dialogue()

func _on_pickup_requested() -> void:
	if holy_dialog_instance != null and is_instance_valid(holy_dialog_instance):
		return
	
	holy_dialog_instance = holy_dialog_scene.instantiate()
	ui_layer.add_child(holy_dialog_instance)

	holy_dialog_instance.holy_accepted.connect(_on_holy_accepted)
	holy_dialog_instance.holy_declined.connect(_on_holy_declined)
	holy_dialog_instance.holy_closed.connect(_on_holy_closed)

	player_world.velocity = Vector2.ZERO
	player_world.set_physics_process(false)

	holy_dialog_instance.open_holy_dialogue(
		"The Holy McGuffin!",
		"Brave hero, I have the power you need to fight the evil lord. Will you wield me in battle?",
		"Take the Holy McGuffin",
		"Run away from this weird sword"
	)

func _on_holy_accepted() -> void:
	GameManager.has_holy_mcguffin = true
	holy_mcguffin.collect()
	holy_mcguffin.call_deferred("queue_free")
	player_world.set_physics_process(true)

func _on_holy_declined() -> void:
	player_world.set_physics_process(true)
	holy_mcguffin.close_holy_dialogue()

func _on_holy_closed() -> void:
	if holy_dialog_instance != null and is_instance_valid(holy_dialog_instance):
		holy_dialog_instance.queue_free()
	player_world.set_physics_process(true)
	holy_dialog_instance = null
	holy_mcguffin.close_holy_dialogue()
