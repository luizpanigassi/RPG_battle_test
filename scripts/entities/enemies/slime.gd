class_name Slime
extends Enemy

func _init():
	var entity_data := load("res://scripts/entities/data/slime.tres")
	apply_data(entity_data)
