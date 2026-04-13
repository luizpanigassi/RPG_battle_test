extends Node

var player_data
var pending_enemy_ids: Array[String] = []

var enemy_factories := {
	"goblin": func(): return Goblin.new(),
	"kobold": func(): return Kobold.new(),
	"slime": func(): return Slime.new(),
}

func set_pending_encounter(enemy_ids: Array[String]) -> void:
	pending_enemy_ids = enemy_ids.duplicate()

func consume_pending_encounter() -> Array[String]:
	var ids = pending_enemy_ids.duplicate()
	pending_enemy_ids.clear()
	return ids

func create_enemy_by_id(enemy_id: String) -> Enemy:
	var factory = enemy_factories.get(enemy_id, null)
	if factory == null:
		return null
	return factory.call()
