class_name Entity
extends Node

var max_hp: int = 100
var hp: int = 100
var attack: int = 15
var defense: int = 5
var speed: int = 10

var actions: Array[Action] = []
var status_effects: Array = []

func take_damage(amount: int) -> int:
	var damage = max(amount - defense, 1)
	hp -= damage
	
	print(name + " took " + str(damage) + " damage. HP: " + str(hp))

	if hp <= 0:
		hp = 0
		die()
	
	return damage

func heal(amount: int):
	hp = min(hp + amount, max_hp)
	print(name + " healed " + str(amount) + " points of damage! HP: " + str(hp))

func apply_status(effect: StatusEffect, combat = null):
	for e in status_effects:
		if e.name == effect.name:
			return
	
	print(name, " is affected by ", effect.name)
	status_effects.append(effect)
	effect.on_apply(self)
	if combat != null and combat.ui != null:
		combat.ui.log(name + " is afflicted with " + effect.name + "!")

func die():
	print(name + " died.")
