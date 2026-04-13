class_name Entity
extends Node

var max_hp: int = 100
var hp: int = 100
var attack: int = 1500
var defense: int = 5
var speed: int = 10
var display_name: String = "Placeholder"

var actions: Array[Action] = []
var status_effects: Array[StatusEffect] = []

func take_damage(amount: int) -> int:
	var damage = max(amount - defense, 1)
	hp -= damage
	
	if hp <= 0:
		hp = 0
		die()
	
	return damage

func heal(amount: int):
	hp = min(hp + amount, max_hp)

func apply_status(effect: StatusEffect, combat: CombatManager = null):
	for e in status_effects:
		if e.name == effect.name:
			return

	if combat != null and combat.ui != null:
		if effect.is_buff:
			combat.ui.log_buff(self, effect)
		else:
			combat.ui.log_status(self, effect)
	status_effects.append(effect)
	effect.on_apply(self)

func die():
	pass
