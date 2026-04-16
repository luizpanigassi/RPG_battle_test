extends CombatPlayer
class_name Shadow

func _build_loadout():
	actions.clear()
	actions.append(AttackAction.new())
	actions.append(SkillFactory.poison_strike())
	actions.append(SkillFactory.slow_strike())
	actions.append(SkillFactory.meditate())
