class_name SkillFactory
extends RefCounted

# Effect helpers

static func status(status_type: Script) -> ApplyStatusEffect:
	var s: ApplyStatusEffect = ApplyStatusEffect.new()
	s.status_type = status_type
	return s
	
static func damage(power: int) -> DamageEffect:
	var d: DamageEffect = DamageEffect.new()
	d.power = power
	return d
	
static func heal(amount: int) -> HealEffect:
	var h: HealEffect = HealEffect.new()
	h.amount = amount
	return h

# Poison Strike
static func poison_strike() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Poison Strike"
	
	var effects: Array[Effect] = [damage(8), status(Poison)]
	skill.effects = effects
	
	return skill
	
# Fireball
static func fireball() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Fireball"
	
	var effects: Array[Effect] = [damage(10), status(Burn)]
	skill.effects = effects
	
	return skill
	
# Slow Strike
static func slow_strike() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Slow Strike"
	
	var effects: Array[Effect] = [damage(7), status(Slow)]
	skill.effects = effects
	
	return skill

static func healing() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Heal"
	skill.target_type = Action.TargetType.SELF
	
	var effects: Array[Effect] = [heal(15)]
	skill.effects = effects
	
	return skill

static func regen() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Regen"
	skill.target_type = Action.TargetType.SELF
	
	var effects: Array[Effect] = [status(Regen)]
	skill.effects = effects
	
	return skill
