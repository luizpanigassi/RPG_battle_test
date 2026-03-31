class_name Entity
extends Node

var max_hp: int = 100
var hp: int = 100
var attack: int = 10
var defense: int = 5
var speed: int = 10

var actions: Array[Action] = []

func take_damage(amount: int):
	var damage = max(amount - defense, 1)
	hp -= damage
	
	print(name + " took " + str(damage) + " damage. HP: " + str(hp))

	if hp <= 0:
		die()

func die():
	print(name + " died.")
