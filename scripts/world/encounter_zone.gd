extends Area2D

@export var encounter_rate := 0.02
@export var max_enemies := 3
@export var min_enemies := 1
@export var encounter_pool: Array[Dictionary] = [
	{"id": "slime", "weight": 60},
	{"id": "goblin", "weight": 30},
	{"id": "kobold", "weight": 10},
]

var battle_started: bool = false

func _physics_process(_delta: float) -> void:
	
	if not has_overlapping_bodies():
		return
		
	if randf() < encounter_rate:
		start_battle()
		
func start_battle():
	if battle_started:
		return

	battle_started = true
	set_physics_process(false)

	for body in get_overlapping_bodies():
		if body is CharacterBody2D:
			body.velocity = Vector2.ZERO

	var ids := _generate_encounter_enemy_ids()
	if ids.is_empty():
		ids = ["slime"] # só de fallback

	GameManager.set_pending_encounter(ids)
	await SceneTransition.transition_to_scene("res://scenes/battle/battle_scene.tscn")

func _roll_enemy_count() -> int:
	return randi_range(min_enemies, max_enemies)

func _pick_weighted_enemy_id() -> String:
	if encounter_pool.is_empty():
		return ""

	var total := 0
	for e in encounter_pool:
		total += int(e.get("weight", 0))

	if total <= 0:
		return ""

	var roll := randi_range(1, total)
	var acc := 0

	for e in encounter_pool:
		acc += int(e.get("weight", 0))
		if roll <= acc:
			return String(e.get("id", ""))

	return ""

func _generate_encounter_enemy_ids() -> Array[String]:
	var result: Array[String] = []
	var count := _roll_enemy_count()

	for i in count:
		var id := _pick_weighted_enemy_id()
		if id != "":
			result.append(id)

	return result
