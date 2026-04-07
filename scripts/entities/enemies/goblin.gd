class_name Goblin
extends Enemy

func _init():
	name = "Goblin"
	animation_prefix = "goblin"
	visual_offset = Vector2(0, -100)
	visual_scale = 0.72
	max_hp = 40
	hp = 40
	attack = 8
	defense = 2
	speed = 10
