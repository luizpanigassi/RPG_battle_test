class_name CombatManager
extends Node

@onready var player = $"../CanvasLayer/Player"
@onready var ui = $"../CanvasLayer/BattleUi"
@onready var enemy_container = $"../CanvasLayer/EnemyContainer"

var waiting_for_input = false
var turn_queue: Array[Entity] = []
var player_party: Array[Entity] = []
var enemies: Array[Enemy] = []
var current_turn_index := 0
var pending_action: Action = null
var enemy_scene = preload("res://scenes/entities/enemy.tscn")
var enemy_visuals: Dictionary[Enemy, Enemy] = {}

func _ready():
	await get_tree().process_frame
	await SceneTransition.fade_in()

	ui.action_selected.connect(_on_action_selected)
	ui.target_selected.connect(_on_target_selected)
	ui.back_pressed.connect(_on_back_pressed)
	
	ui.set_actions(player.actions)
	ui.update_hp(player, enemies)
	
	start_combat()

func start_combat():
	player_party = [player]
	var enemy_ids := GameManager.consume_pending_encounter()

	enemies.clear()
	for enemy_id in enemy_ids:
		var enemy = GameManager.create_enemy_by_id(enemy_id)
		if enemy != null:
			enemies.append(enemy)

	if enemies.is_empty():
		enemies = [Slime.new()] # fallback genérico
	spawn_enemy_visuals()
	
	ui.setup_enemies(enemies)
	
	turn_queue.clear()
	
	for p in player_party:
		turn_queue.append(p)
	for e in enemies:
		turn_queue.append(e)
	
	sort_turn_order()
	current_turn_index = 0
	
	ui.update_hp(player, enemies)
	
	next_turn()
	
func sort_turn_order():
	turn_queue.sort_custom(func(a, b):
		return a.speed > b.speed
		)

func next_turn():
	if turn_queue.is_empty():
		return
	if is_combat_over():
		end_combat()
		return
	
	var current_entity: Entity = turn_queue[current_turn_index]
	
	process_status_start(current_entity)
	if current_entity == player:
		player_turn()
	else:
		enemy_turn(current_entity)

func spawn_enemy_visuals():
	for child in enemy_container.get_children():
		child.queue_free()

	enemy_visuals.clear()

	var slots = ui.get_enemy_slot_positions(enemies.size())

	for i in enemies.size():
		var enemy_data = enemies[i]
		var visual = enemy_scene.instantiate()
		enemy_container.add_child(visual)

		visual.set_animation_prefix(enemy_data.animation_prefix)
		visual.z_index = 1

		if i < slots.size():
			visual.position = slots[i] + enemy_data.visual_offset
		else:
			visual.position = Vector2(760 + 120 * (i - slots.size() + 1), 280) + enemy_data.visual_offset

		visual.scale = Vector2.ONE * enemy_data.visual_scale
		
		enemy_visuals[enemy_data] = visual
	
	_reposition_enemy_visuals(false)

func process_status_start(entity: Entity):
	for effect in entity.status_effects:
		effect.on_turn_start(entity, self)

func player_turn():
	waiting_for_input = true

func _on_action_selected(action: Action):
	if not waiting_for_input:
		return
	waiting_for_input = false
	pending_action = action
	
	if action.target_type == Action.TargetType.ENEMY:
		ui.start_target_selection(enemies)
	elif action.target_type == Action.TargetType.SELF:
		await _on_target_selected(player)

func enemy_turn(enemy_entity: Enemy):
	await get_tree().create_timer(1.0).timeout
	
	var decision = enemy_entity.choose_action(player_party)
	var action: Action = decision["action"]
	var target: Entity = decision["target"]
	var enemy_visual = enemy_visuals.get(enemy_entity)
	if enemy_visual:
		await enemy_visual.play_attack_animation()
	ui.log_skill(enemy_entity, action)
	
	var damage: int = action.execute(enemy_entity, target, self)
	
	if damage > 0:
		ui.log_damage(target, damage)
		if target == player:
			await player.play_hurt_animation()
		
	elif damage < 0:
		ui.log_heal(target, -damage)
	
	await cleanup_dead()
	
	ui.update_hp(player, enemies)
	end_turn()
	
func _on_target_selected(target: Entity):
	if pending_action == null:
		return
	if target == null:
		return
	var action := pending_action
	pending_action = null
	waiting_for_input = false
	ui.log_skill(player, action)
	await player.play_attack_animation()
	var damage: int = action.execute(player, target, self)
	
	if damage > 0:
		if target is Enemy:
			var target_visual = enemy_visuals.get(target)
			if target_visual:
				await target_visual.play_hurt_animation()
		ui.log_damage(target, damage)
		
	elif damage < 0:
		ui.log_heal(target, -damage)
		
	ui.update_hp(player, enemies)
	
	
	await cleanup_dead()
	ui.set_actions(player.actions)
	
	end_turn()

func end_turn():
	if turn_queue.is_empty():
		end_combat()
		return

	if current_turn_index >= turn_queue.size():
		current_turn_index = 0

	var entity: Entity = turn_queue[current_turn_index]

	process_status_end(entity)

	current_turn_index += 1
	
	if current_turn_index >= turn_queue.size():
		current_turn_index = 0
		
	next_turn()

func process_status_end(entity: Entity):
	if entity.status_effects.is_empty():
		return
		
	for effect in entity.status_effects.duplicate():
		effect.on_turn_end(entity)
		
		effect.duration -= 1
		
		if effect.duration <= 0:
			effect.on_expire(entity)
			entity.status_effects.erase(effect)
			ui.log_status_end(entity, effect)

func is_combat_over() -> bool:
	var all_players_dead = true
	for p in player_party:
		if p.hp > 0:
			all_players_dead = false
	var all_enemies_dead = true
	for e in enemies:
		if e.hp > 0:
			all_enemies_dead = false
	
	return all_players_dead or all_enemies_dead

func cleanup_dead():
	var removed_any := false

	for e in enemies.duplicate():
		if e.hp <= 0:
			var dead_visual = enemy_visuals.get(e)
			if dead_visual:
				dead_visual.queue_free()
				enemy_visuals.erase(e)
			enemies.erase(e)
			turn_queue.erase(e)
			await ui.remove_enemy(e)
			removed_any = true
	
	if removed_any:
		_reposition_enemy_visuals(true)

func end_combat():
	if player.hp <= 0:
		ui.log("[color=red]Defeat...[/color]")
	else:
		ui.log("[color=green]Victory![/color]")
	
	await get_tree().create_timer(2).timeout
	
	get_tree().change_scene_to_file("res://scenes/world/overworld.tscn")

func _on_back_pressed():
	pending_action = null
	waiting_for_input = true
	ui.set_actions(player.actions)

func _reposition_enemy_visuals(animated := true) -> void:
	var slots = ui.get_enemy_slot_positions(enemies.size())
	for i in enemies.size():
		var enemy_data = enemies[i]
		var visual = enemy_visuals.get(enemy_data)
		if visual == null:
			continue

		var target_pos: Vector2
		if i < slots.size():
			target_pos = slots[i] + enemy_data.visual_offset
		else:
			target_pos = Vector2(760 + 120 * (i - slots.size() + 1), 280) + enemy_data.visual_offset

		if animated:
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(visual, "position", target_pos, 0.25)
		else:
			visual.position = target_pos
		
