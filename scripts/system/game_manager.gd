extends Node

var player_data
var player_stats: PlayerStats = PlayerStats.new()
var pending_enemy_ids: Array[String] = []
var saved_player_position: Vector2 = Vector2.ZERO
var has_saved_player_position: bool = false
var active_player_ids: Array[String] = ["shadow", "mirana"]

var enemy_factories := {
	"goblin": func(): return Goblin.new(),
	"kobold": func(): return Kobold.new(),
	"slime": func(): return Slime.new(),
}

var player_scene_paths := {
	"shadow": "res://scenes/entities/shadow.tscn",
	"mirana": "res://scenes/entities/mirana.tscn",
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

func get_active_player_ids() -> Array[String]:
	if active_player_ids.is_empty():
		active_player_ids = ["shadow"]
	return active_player_ids.duplicate()

func has_party_member(player_id: String) -> bool:
	return active_player_ids.has(player_id)

func add_party_member(player_id: String) -> void:
	if has_party_member(player_id):
		return
	if not player_scene_paths.has(player_id):
		return
	active_player_ids.append(player_id)

func remove_party_member(player_id: String) -> void:
	active_player_ids.erase(player_id)
	if active_player_ids.is_empty():
		active_player_ids = ["shadow"]

func create_player_by_id(player_id: String):
	var scene_path = player_scene_paths.get(player_id, "")
	if scene_path == "":
		return null

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		return null

	return packed_scene.instantiate()

func save_player_position(pos: Vector2) -> void:
	saved_player_position = pos
	has_saved_player_position = true
	player_stats.save_position(pos)

func consume_saved_player_position() -> Vector2:
	has_saved_player_position = false
	return saved_player_position

func grant_battle_rewards(defeated_enemies: Array) -> Dictionary:
	var total_xp := 0
	var total_gold := 0

	for enemy in defeated_enemies:
		if enemy == null:
			continue
		if enemy.data == null:
			continue
		total_xp += int(enemy.data.xp_reward)
		total_gold += int(enemy.data.gold_reward)

	player_stats.gain_xp(total_xp)
	player_stats.add_gold(total_gold)

	return {
		"xp": total_xp,
		"gold": total_gold,
	}
