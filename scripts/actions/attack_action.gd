class_name AttackAction
extends Action

func _init():
	name = "Attack"

func execute(user, target, _combat = null) -> int:
	return target.take_damage(user.attack)
