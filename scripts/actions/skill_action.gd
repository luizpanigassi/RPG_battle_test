class_name SkillAction
extends Action

var power: int = 20

func _init():
	name = "Skill"

func execute(_user, target) -> int:
	return target.take_damage(power)
