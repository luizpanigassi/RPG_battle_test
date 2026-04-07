class_name Kobold
extends Enemy

func _init():
	name = "Kobold"
	animation_prefix = "kobold"
	visual_offset = Vector2(0, -100)
	visual_scale = 1.15
	max_hp = 70
	hp = 70
	attack = 12
	defense = 4
	speed = 16
