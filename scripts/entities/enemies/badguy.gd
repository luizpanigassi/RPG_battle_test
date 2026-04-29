class_name Badguy
extends Enemy

func _init():
	var entity_data := load("res://scripts/entities/data/badguy.tres")
	apply_data(entity_data)
