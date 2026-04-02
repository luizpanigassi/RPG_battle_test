class_name CombatManager
extends Node

@onready var player = $"../Player"
@onready var ui = $"../BattleUi"

var waiting_for_input = false
var turn_queue: Array = []
var player_party: Array = []
var enemies: Array = []
var current_turn_index := 0
var pending_action: Action = null

func _ready():
	print("Combat started!")
		
	await get_tree().process_frame

	ui.action_selected.connect(_on_action_selected)
	ui.target_selected.connect(_on_target_selected)
	ui.back_pressed.connect(_on_back_pressed)
	
	ui.set_actions(player.actions)
	ui.update_hp(player, enemies)
	
	start_combat()

func start_combat():
	player_party = [player]
	enemies = [Goblin.new(), Wolf.new(), Slime.new()]
	
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
	
	var current_entity = turn_queue[current_turn_index]
	
	process_status_start(current_entity)
	if current_entity == player:
		player_turn()
	else:
		enemy_turn(current_entity)

func process_status_start(entity):
	for effect in entity.status_effects:
		effect.on_turn_start(entity, self)

func player_turn():
	print("Player's turn!")
	waiting_for_input = true

func _on_action_selected(action: Action):
	if not waiting_for_input:
		return
	waiting_for_input = false
	pending_action = action
	
	if action.target_type == Action.TargetType.ENEMY:
		ui.start_target_selection(enemies)
	elif action.target_type == Action.TargetType.SELF:
		_on_target_selected(player)

func enemy_turn(enemy_entity):
	print(enemy_entity.name + "'s turn!")
	await get_tree().create_timer(1.0).timeout
	
	var decision = enemy_entity.choose_action(player_party)
	var action = decision["action"]
	var target = decision["target"]
	
	var damage = action.execute(enemy_entity, target, self)
	
	if damage > 0:
		ui.log(enemy_entity.name + " attacks and deals " + str(damage) + " damage!")
		
	elif damage < 0:
		ui.log(enemy_entity.name + " heals " + str(-damage) + " HP!")
	
	else:
		ui.log(enemy_entity.name + " uses " + action.name + "!")
		
	cleanup_dead()
	
	ui.update_hp(player, enemies)
	end_turn()
	
func _on_target_selected(target):
	var damage = pending_action.execute(player, target, self)
	
	if damage > 0:
		ui.log("Player uses " + pending_action.name + " on " + target.name + " and deals " + str(damage) + " damage!")
		
	elif damage < 0:
		ui.log("Player uses " + pending_action.name + " and heals " + str(-damage) + " HP!")
		
	else:
		ui.log("Player uses " + pending_action.name + "!")
		
	ui.update_hp(player, enemies)
	
	pending_action = null
	
	cleanup_dead()
	ui.set_actions(player.actions)
	
	end_turn()

func end_turn():
	if turn_queue.is_empty():
		end_combat()
		return

	if current_turn_index >= turn_queue.size():
		current_turn_index = 0

	var entity = turn_queue[current_turn_index]

	process_status_end(entity)

	current_turn_index += 1
	
	if current_turn_index >= turn_queue.size():
		current_turn_index = 0
		
	next_turn()

func process_status_end(entity):
	if entity.status_effects.is_empty():
		return
		
	for effect in entity.status_effects.duplicate():
		effect.on_turn_end(entity)
		
		effect.duration -= 1
		
		if effect.duration <= 0:
			effect.on_expire(entity)
			entity.status_effects.erase(effect)
			ui.log(entity.name + " is no longer affected by " + effect.name + ".")

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
	for e in enemies.duplicate():
		if e.hp <= 0:
			enemies.erase(e)
			turn_queue.erase(e)
			ui.remove_enemy(e)

func end_combat():
	if player.hp <= 0:
		print("Enemy wins!")
	else:
		print("Player wins!")

func _on_back_pressed():
	pending_action = null
	waiting_for_input = true
	ui.set_actions(player.actions)
