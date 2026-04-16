class_name SkillAction
extends Action

var effects: Array[Effect] = []

func _init():
	name = "Skill"

func try_consume_cost(user: Entity) -> bool:
	if user.sp < sp_cost:
		return false

	user.sp -= sp_cost
	return true

func apply_to_target(user: Entity, target: Entity, combat: CombatManager = null) -> int:
	var total_damage := 0

	for effect in effects:
		var result: Variant = effect.apply(user, target, combat)
		if typeof(result) == TYPE_INT:
			total_damage += result
	
	return total_damage

func execute(user: Entity, target: Entity, combat: CombatManager = null) -> int:
	if not try_consume_cost(user):
		return 0

	return apply_to_target(user, target, combat)
	
