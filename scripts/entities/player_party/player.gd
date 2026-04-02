extends Entity

func _init():
	
	# Normal attack
	actions.append(AttackAction.new())
	# Skill appends:
	actions.append(SkilLFactory.poison_strike())
	actions.append(SkilLFactory.fireball())
	actions.append(SkilLFactory.slow_strike())
	actions.append(SkilLFactory.healing())
