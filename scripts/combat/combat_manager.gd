class_name CombatManager
extends Node

@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
@onready var ui = $"../CanvasLayer/BattleUi"
@onready var enemy_container = $"../CanvasLayer/EnemyContainer"

var player_anchor: Node2D = null

var waiting_for_input = false
var turn_queue: Array[Entity] = []
var player_party: Array[Entity] = []
var enemies: Array[Enemy] = []
var defeated_enemies: Array[Enemy] = []
var current_turn_index := 0
var pending_action: Action = null
var current_player: Entity = null
var enemy_scene = preload("res://scenes/entities/enemy.tscn")
var enemy_visuals: Dictionary[Enemy, Enemy] = {}

func _ready():
	await get_tree().process_frame
	await SceneTransition.fade_in()

	ui.action_selected.connect(_on_action_selected)
	ui.target_selected.connect(_on_target_selected)
	ui.all_enemies_confirmed.connect(_on_all_enemies_confirmed)
	ui.back_pressed.connect(_on_back_pressed)
	
	start_combat()

func start_combat():
	_spawn_player_party()
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

	if not player_party.is_empty():
		current_player = player_party[0]
		ui.update_hp(current_player, enemies)
	
	next_turn()

func _spawn_player_party():
	for p in player_party:
		if is_instance_valid(p):
			p.queue_free()
	player_party.clear()

	var base_position := Vector2(144, 149)
	var base_scale := Vector2(2.33332, 2.34643)
	var base_z_index := 2
	if player_anchor != null:
		base_position = player_anchor.position
		base_scale = player_anchor.scale
		base_z_index = player_anchor.z_index
		player_anchor.queue_free()
		player_anchor = null

	var active_ids := GameManager.get_active_player_ids()
	for i in active_ids.size():
		var player_id: String = active_ids[i]
		var player_instance = GameManager.create_player_by_id(player_id)
		if player_instance == null:
			continue
		if not (player_instance is Entity):
			continue

		var slot_offset := Vector2(90.0 * float(i), 34.0 * float(i))
		player_instance.position = base_position + slot_offset
		player_instance.scale = base_scale
		player_instance.z_index = base_z_index + i
		canvas_layer.add_child(player_instance)
		player_party.append(player_instance)

	if player_party.is_empty():
		var fallback = GameManager.create_player_by_id("shadow")
		if fallback != null and fallback is Entity:
			fallback.position = base_position
			fallback.scale = base_scale
			fallback.z_index = base_z_index
			canvas_layer.add_child(fallback)
			player_party.append(fallback)
	
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
	if current_entity.hp <= 0:
		end_turn()
		return
	
	process_status_start(current_entity)
	if player_party.has(current_entity):
		player_turn(current_entity)
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

func player_turn(player_entity: Entity):
	current_player = player_entity
	waiting_for_input = true
	ui.set_actions(current_player.actions, current_player)
	ui.update_hp(current_player, enemies)

func _on_action_selected(action: Action):
	if not waiting_for_input:
		return

	waiting_for_input = false
	pending_action = action
	
	if action.target_type == Action.TargetType.ENEMY:
		ui.start_target_selection(enemies)
	elif action.target_type == Action.TargetType.SELF:
		await _on_target_selected(current_player)
	elif action.target_type == Action.TargetType.ALL_ENEMIES:
		ui.start_all_enemies_selection()
	elif action.target_type == Action.TargetType.ALLY:
		ui.start_ally_target_selection(player_party)

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
		if target != null and player_party.has(target) and target.has_method("play_hurt_animation"):
			await target.play_hurt_animation()
		
	elif damage < 0:
		ui.log_heal(target, -damage)
	
	await cleanup_dead()
	
	if current_player != null:
		ui.update_hp(current_player, enemies)
	end_turn()
	
func _on_target_selected(target: Entity):
	if pending_action == null:
		return
	if target == null:
		return
	var action := pending_action
	pending_action = null
	waiting_for_input = false
	var actor := current_player
	if actor == null:
		end_turn()
		return

	ui.log_skill(actor, action)
	if actor.has_method("play_attack_animation"):
		await actor.play_attack_animation()
	var damage: int = action.execute(actor, target, self)
	
	if damage > 0:
		if target is Enemy:
			var target_visual = enemy_visuals.get(target)
			if target_visual:
				await target_visual.play_hurt_animation()
		ui.log_damage(target, damage)
		
	elif damage < 0:
		ui.log_heal(target, -damage)
		
	ui.update_hp(actor, enemies)
	
	
	await cleanup_dead()
	ui.set_actions(actor.actions, actor)
	
	end_turn()

func _on_all_enemies_confirmed():
	if pending_action == null:
		waiting_for_input = true
		if current_player != null:
			ui.set_actions(current_player.actions, current_player)
		return
	var action := pending_action
	pending_action = null
	await _execute_action_all_enemies(current_player, action)

func _execute_action_all_enemies(actor: Entity, action: Action):
	if actor == null:
		waiting_for_input = true
		return

	var skill_action := action as SkillAction
	if skill_action == null:
		pending_action = null
		ui.set_actions(actor.actions, actor)
		waiting_for_input = true
		return

	if not skill_action.try_consume_cost(actor):
		pending_action = null
		ui.set_actions(actor.actions, actor)
		waiting_for_input = true
		return

	ui.log_skill(actor, skill_action)
	if actor.has_method("play_attack_animation"):
		await actor.play_attack_animation()

	var alive_targets: Array[Enemy] = []
	for enemy in enemies:
		if enemy.hp > 0:
			alive_targets.append(enemy)

	for enemy in alive_targets:
		var damage: int = skill_action.apply_to_target(actor, enemy, self)

		if damage > 0:
			var target_visual = enemy_visuals.get(enemy)
			if target_visual:
				await target_visual.play_hurt_animation()
			ui.log_damage(enemy, damage)
		elif damage < 0:
			ui.log_heal(enemy, -damage)

	pending_action = null
	ui.update_hp(actor, enemies)

	await cleanup_dead()
	ui.set_actions(actor.actions, actor)

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
			defeated_enemies.append(e)
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
	waiting_for_input = false
	pending_action = null
	ui.clear_for_combat_end()

	var leader: Entity = null
	if not player_party.is_empty():
		leader = player_party[0]
	elif current_player != null:
		leader = current_player

	if leader != null:
		GameManager.player_stats.sync_current_hp(leader.hp, leader.max_hp)
		GameManager.player_stats.sync_current_sp(leader.sp, leader.max_sp)

	var all_players_dead := true
	for p in player_party:
		if p.hp > 0:
			all_players_dead = false
			break

	if all_players_dead:
		ui.log("[color=red]Defeat...[/color]")
	else:
		ui.log("[color=green]Victory![/color]")
		var rewards := GameManager.grant_battle_rewards(defeated_enemies)
		ui.log("[color=yellow]Rewards: +%d XP, +%d Gold[/color]" % [rewards["xp"], rewards["gold"]])

	await get_tree().create_timer(2).timeout
	
	get_tree().change_scene_to_file("res://scenes/world/overworld.tscn")

func _on_back_pressed():
	pending_action = null
	waiting_for_input = true
	if current_player != null:
		ui.set_actions(current_player.actions, current_player)

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
		
