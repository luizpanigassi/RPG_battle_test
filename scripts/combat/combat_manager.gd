class_name CombatManager
extends Node

@onready var player = $"../Player"
@onready var enemy = $"../Enemy"
@onready var ui = $"../BattleUi"

var is_player_turn = true
var waiting_for_input = false
var turn_queue: Array = []
var player_party: Array = []
var enemies: Array = []
var current_turn_index := 0

func _ready():
	print("Combat started!")
		
	await get_tree().process_frame

	ui.action_selected.connect(_on_action_selected)
	
	ui.set_actions(player.actions)
	ui.update_hp(player, enemy)
	
	start_combat()

func start_combat():
	player_party = [player]
	enemies = [Goblin.new()]
	
	turn_queue.clear()
	for p in player_party:
		turn_queue.append(p)
	for e in enemies:
		turn_queue.append(e)
	
	sort_turn_order()
	current_turn_index = 0
	next_turn()
	
func sort_turn_order():
	turn_queue.sort_custom(func(a, b):
		return a.speed > b.speed
		)

func next_turn():
	if is_combat_over():
		end_combat()
		return
	
	var current_entity = turn_queue[current_turn_index]
	
	if current_entity == player:
		player_turn()
	else:
		enemy_turn(current_entity)

func player_turn():
	print("Player's turn!")
	waiting_for_input = true

func _on_action_selected(action: Action):
	if not waiting_for_input:
		return
	waiting_for_input = false
	var damage = action.execute(player, enemy)
	ui.log("Player uses " + action.name + " and deals " + str(damage) + " damage!")
	ui.update_hp(player, enemy)
	end_turn()

func enemy_turn(enemy_entity):
	print(enemy_entity.name + "'s turn!")
	await get_tree().create_timer(1.0).timeout
	
	var decision = enemy_entity.choose_action(player_party)
	var action = decision["action"]
	var target = decision["target"]
	
	var damage = action.execute(enemy_entity, target)
	
	ui.log(enemy_entity.name + " attacks and deals " + str(damage) + " damage!")
	
	ui.update_hp(player, enemy)
	end_turn()

func end_turn():
	current_turn_index += 1
	
	if current_turn_index >= turn_queue.size():
		current_turn_index = 0
	next_turn()

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

func end_combat():
	if player.hp <= 0:
		print("Enemy wins!")
	else:
		print("Player wins!")
