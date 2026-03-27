class_name CombatManager
extends Node

@onready var player = $"../Player"
@onready var enemy = $"../Enemy"
@onready var ui = $"../BattleUi"

var is_player_turn = true
var waiting_for_input = false

func _ready():
	print("Combat started!")

	ui.attack_selected.connect(_on_attack_selected)

	start_combat()

func start_combat():
	next_turn()

func next_turn():
	if player.hp <= 0 or enemy.hp <=0:
		end_combat()
		return

	if is_player_turn:
		player_turn()
	else:
		enemy_turn()

func player_turn():
	print("Player's turn!")
	waiting_for_input = true

func _on_attack_selected():
	if not waiting_for_input:
		return
	waiting_for_input = false
	enemy.take_damage(player.attack)
	end_turn()

func enemy_turn():
	print("Enemy's turn!")
	await get_tree().create_timer(1.0).timeout

	player.take_damage(enemy.attack)
	end_turn()

func end_turn():
	is_player_turn = !is_player_turn
	next_turn()

func end_combat():
	if player.hp <= 0:
		print("Enemy wins!")
	else:
		print("Player wins!")
