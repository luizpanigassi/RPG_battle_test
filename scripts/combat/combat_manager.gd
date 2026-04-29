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
var dead_player_log: Dictionary = {}
var enemy_scene = preload("res://scenes/entities/enemy.tscn")
var enemy_visuals: Dictionary[Enemy, Enemy] = {}
var battle_is_boss := false
var atb_gauge: Dictionary = {}
var current_turn_entity: Entity = null

const ATB_THRESHOLD := 100.0

func _ready():
	await get_tree().process_frame
	await SceneTransition.fade_in()

	get_viewport().size_changed.connect(_on_viewport_size_changed)

	ui.action_selected.connect(_on_action_selected)
	ui.target_selected.connect(_on_target_selected)
	ui.all_enemies_confirmed.connect(_on_all_enemies_confirmed)
	ui.back_pressed.connect(_on_back_pressed)
	
	start_combat()

func start_combat():
	_spawn_player_party()
	var enemy_ids := GameManager.consume_pending_encounter()
	battle_is_boss = enemy_ids.has("badguy")

	enemies.clear()
	for enemy_id in enemy_ids:
		var enemy = GameManager.create_enemy_by_id(enemy_id)
		if enemy != null:
			enemies.append(enemy)

	if enemies.is_empty():
		enemies = [Slime.new()] # fallback genérico
	spawn_enemy_visuals()
	
	ui.setup_enemies(enemies)
	ui.setup_players(player_party)
	_prime_dead_player_log()
	
	await get_tree().process_frame
	_reposition_player_visuals(false)

	turn_queue.clear()
	
	for p in player_party:
		turn_queue.append(p)
	for e in enemies:
		turn_queue.append(e)
	
	_init_atb_gauges()
	
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

func _init_atb_gauges() -> void:
	atb_gauge.clear()

	for entity in turn_queue:
		atb_gauge[entity] = 0.0

func get_living_turn_entities() -> Array[Entity]:
	var living: Array[Entity] = []
	for entity in turn_queue:
		if entity != null and entity.hp > 0:
			living.append(entity)
	return living

func pick_next_actor_by_atb() -> Entity:
	while true:
		var living: Array[Entity] = get_living_turn_entities()
		if living.is_empty():
			return null

		for entity in living:
			var gauge: float = float(atb_gauge.get(entity, 0.0))
			var speed_value: float = max(1.0, float(entity.speed))
			atb_gauge[entity] = gauge + speed_value

		var ready_entities: Array[Entity] = []
		for entity in living:
			if float(atb_gauge.get(entity, 0.0)) >= ATB_THRESHOLD:
				ready_entities.append(entity)

		if ready_entities.is_empty():
			continue

		var chosen: Entity = ready_entities[0]
		for entity in ready_entities:
			var entity_gauge: float = float(atb_gauge.get(entity, 0.0))
			var chosen_gauge: float = float(atb_gauge.get(chosen, 0.0))
			if entity_gauge > chosen_gauge:
				chosen = entity

		atb_gauge[chosen] = float(atb_gauge.get(chosen, 0.0)) - ATB_THRESHOLD
		return chosen
	return null
	
func sort_turn_order():
	turn_queue.sort_custom(func(a, b):
		return a.speed > b.speed
		)

func next_turn():
	if turn_queue.is_empty():
		end_combat()
		return
	
	if is_combat_over():
		end_combat()
		return
	
	var current_entity := pick_next_actor_by_atb()
	if current_entity == null:
		end_combat()
		return

	current_turn_entity = current_entity
	_log_new_party_deaths()

	ui.log(current_turn_entity.display_name + "'s turn!")

	if current_entity.hp <= 0:
		end_turn()
		return
	
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
	ui.update_hp(player_party, current_player, enemies)

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

	if action == null or target == null:
		end_turn()
		return
	
	if target.hp <= 0:
		var alive_targets: Array[Entity] = []
		for p in player_party:
			if p.hp> 0:
				alive_targets.append(p)
		
		if alive_targets.is_empty():
			end_turn()
			return
		
		target = alive_targets[randi() % alive_targets.size()]

	var enemy_visual = enemy_visuals.get(enemy_entity)
	if enemy_visual:
		await enemy_visual.play_attack_animation()
	ui.log_skill(enemy_entity, action)
	
	var damage: int = action.execute(enemy_entity, target, self)
	
	if damage > 0:
		ui.log_damage(target, damage)
		if target != null and player_party.has(target) and target.has_method("play_hurt_animation"):
			await target.play_hurt_animation()
		_log_new_party_deaths()
		
	elif damage < 0:
		ui.log_heal(target, -damage)
	
	await cleanup_dead()
	
	if current_player != null:
		ui.update_hp(player_party, current_player, enemies)
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
		_log_new_party_deaths()
		
	elif damage < 0:
		ui.log_heal(target, -damage)
		
	ui.update_hp(player_party, actor, enemies)
	
	
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
			_log_new_party_deaths()
		elif damage < 0:
			ui.log_heal(enemy, -damage)

	pending_action = null
	ui.update_hp(player_party, actor, enemies)

	await cleanup_dead()
	ui.set_actions(actor.actions, actor)

	end_turn()

func end_turn():
	if turn_queue.is_empty():
		end_combat()
		return
	
	if current_turn_entity != null:
		process_status_end(current_turn_entity)
	
	_log_new_party_deaths()
	current_turn_entity = null
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
			atb_gauge.erase(e)
			await ui.remove_enemy(e)
			removed_any = true
	
	if removed_any:
		_reposition_enemy_visuals(true)

func end_combat():
	waiting_for_input = false
	pending_action = null
	ui.clear_for_combat_end()

	var all_players_dead := true
	for p in player_party:
		if p.hp > 0:
			all_players_dead = false

	for p in player_party:
		if not (p is CombatPlayer):
			continue
		var combat_player := p as CombatPlayer
		var member_state := GameManager.get_party_member_state(combat_player.get_party_member_id())
		member_state.sync_current_hp(combat_player.hp, combat_player.max_hp)
		member_state.sync_current_sp(combat_player.sp, combat_player.max_sp)

	if all_players_dead:
		ui.log("[color=red]Defeat...[/color]")
		await get_tree().create_timer(2.0).timeout
		SceneTransition.fade_transition_to_scene("res://ui/game_over.tscn")
		return
	
	ui.log("[color=green]Victory![/color]")
	var rewards := GameManager.grant_battle_rewards(defeated_enemies)
	ui.log("[color=yellow]Rewards: +%d XP, +%d Gold[/color]" % [rewards["xp"], rewards["gold"]])

	await get_tree().create_timer(2).timeout
	if battle_is_boss:
		SceneTransition.fade_transition_to_scene("res://ui/victory_screen.tscn")
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
		
func _reposition_player_visuals(animated := true) -> void:
	var slots = ui.get_player_slot_positions(player_party.size())

	for i in player_party.size():
		var entity := player_party[i]
		var visual_any: Variant = entity
		if not(visual_any is Node2D):
			continue
		var visual: Node2D = visual_any

		var target_pos: Vector2
		if i < slots.size():
			target_pos = slots[i]
		else:
			target_pos = Vector2(144 + 90 * i, 230 + 24 * i)
		
		if entity.data != null:
			target_pos += entity.data.visual_offset

		if animated:
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(visual, "position", target_pos, 0.2)
		else:
			visual.position = target_pos

func _on_viewport_size_changed():
	_reposition_enemy_visuals(false)
	_reposition_player_visuals(false)

func _log_new_party_deaths() -> void:
	for p in player_party:
		if p == null or p.hp > 0:
			if p != null:
				var live_member_id := ""
				if p is CombatPlayer:
					live_member_id = (p as CombatPlayer).get_party_member_id()
				else:
					live_member_id = p.display_name.to_lower().replace(" ", "_")
				if not live_member_id.is_empty():
					dead_player_log.erase(live_member_id)
			continue

		var member_id := ""
		if p is CombatPlayer:
			member_id = (p as CombatPlayer).get_party_member_id()
		else:
			member_id = p.display_name.to_lower().replace(" ", "_")

		if member_id.is_empty():
			continue
		if dead_player_log.has(member_id):
			continue

		dead_player_log[member_id] = true
		ui.log("[color=orange]%s died![/color]" % p.display_name)

func _prime_dead_player_log() -> void:
	dead_player_log.clear()

	for p in player_party:
		if p == null or p.hp > 0:
			continue
		
		var member_id := ""
		if p is CombatPlayer:
			member_id = (p as CombatPlayer).get_party_member_id()
		else:
			member_id = p.display_name.to_lower().replace(" ", "_")

		if not member_id.is_empty():
			dead_player_log[member_id] = true
