class_name Goblin
extends Enemy

func _init():
	var entity_data := load("res://scripts/entities/data/goblin.tres")
	apply_data(entity_data)
