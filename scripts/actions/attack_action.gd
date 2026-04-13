class_name AttackAction
extends Action

func _init():
	name = "Attack"

func execute(user: Entity, target: Entity, _combat: CombatManager = null) -> int:
	return target.take_damage(user.attack)
