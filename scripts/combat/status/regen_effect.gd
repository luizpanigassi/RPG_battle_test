class_name Regen
extends StatusEffect

var heal_amount := 5

func _init():
	name = "Regen"
	duration = 5
	is_buff = true

func on_turn_start(target, combat):
	target.heal(heal_amount)
	print(target.name, " regenerates ", heal_amount, " damage!")
	combat.ui.log_heal(target, heal_amount)
