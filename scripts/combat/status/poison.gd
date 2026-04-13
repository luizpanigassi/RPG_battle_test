class_name Poison
extends StatusEffect

var damage := 5

func _init():
	name = "Poison"
	duration = 3

func on_turn_start(target, combat):
	target.take_damage(damage)
	combat.ui.log_damage(target, damage)
