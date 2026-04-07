class_name Slime
extends Enemy

func _init():
	name = "Slime"
	animation_prefix = "slime"
	visual_offset = Vector2(0, -80)
	visual_scale = 2.8
	max_hp = 60
	hp = 60
	attack = 6
	defense = 3
	speed = 4
