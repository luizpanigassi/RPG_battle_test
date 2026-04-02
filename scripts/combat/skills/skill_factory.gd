class_name SkilLFactory
extends RefCounted

# Effect helpers

static func status(type):
	var s = ApplyStatusEffect.new()
	s.status_type = type
	return s
	
static func damage(power):
	var d = DamageEffect.new()
	d.power = power
	return d
	
static func heal(amount):
	var h = HealEffect.new()
	h.amount = amount
	return h

# Poison Strike
static func poison_strike():
	var skill = SkillAction.new()
	skill.name = "Poison Strike"
	
	skill.effects = [damage(8), status(Poison)]
	
	return skill
	
# Fireball
static func fireball():
	var skill = SkillAction.new()
	skill.name = "Fireball"
	
	skill.effects = [damage(10), status(Burn)]
	
	return skill
	
# Slow Strike
static func slow_strike():
	var skill = SkillAction.new()
	skill.name = "Slow Strike"
	
	skill.effects = [damage(7), status(Slow)]
	
	return skill

static func healing():
	var skill = SkillAction.new()
	skill.name = "Heal"
	skill.target_type = Action.TargetType.SELF
	
	skill.effects = [heal(15)]
	
	return skill
