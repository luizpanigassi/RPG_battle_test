extends Entity

func _init():
	actions.append(AttackAction.new())
	actions.append(SkillAction.new())
