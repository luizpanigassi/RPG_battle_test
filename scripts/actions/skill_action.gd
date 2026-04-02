class_name SkillAction
extends Action

var effects: Array = []

func _init():
	name = "Skill"

func execute(_user, target, combat = null) -> int:
	var total_damage := 0
	
	for effect in effects:
		var result = effect.apply(_user, target, combat)
		if typeof(result) == TYPE_INT:
			total_damage += result
	
	return total_damage
