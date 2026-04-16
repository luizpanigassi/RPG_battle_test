class_name Kobold
extends Enemy

func _init():
	var entity_data := load("res://scripts/entities/data/kobold.tres")
	apply_data(entity_data)
