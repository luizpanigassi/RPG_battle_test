extends CombatPlayer
class_name Mirana

func _build_loadout():
	actions.clear()
	actions.append(AttackAction.new())
	actions.append(SkillFactory.fireball())
	actions.append(SkillFactory.healing())
	actions.append(SkillFactory.regen())
	actions.append(SkillFactory.meditate())
