class_name Slow
extends StatusEffect

var speed_penalty := 5

func _init():
	name = "Slow"
	duration = 2

func on_apply(target):
	target.speed -= speed_penalty

func on_expire(target):
	target.speed += speed_penalty
