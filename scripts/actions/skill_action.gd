class_name SkillAction
extends Action

var effects: Array[Effect] = []

func _init():
	name = "Skill"

func execute(user: Entity, target: Entity, combat: CombatManager = null) -> int:
	var total_damage := 0
	
	for effect in effects:
		var result: Variant = effect.apply(user, target, combat)
		if typeof(result) == TYPE_INT:
			total_damage += result
	
	return total_damage
