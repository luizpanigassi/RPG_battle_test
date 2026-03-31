class_name AttackAction
extends Action

func _init():
	name = "Attack"

func execute(user, target):
	target.take_damage(user.attack)
