class_name Burn
extends StatusEffect

var damage := 8

func _init():
	name = "Burn"
	duration = 3

func on_turn_start(target, combat):
	target.take_damage(damage)
	combat.ui.log_damage(target, damage)
