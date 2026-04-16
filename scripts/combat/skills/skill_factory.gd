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

static func recover_sp(amount: int) -> SpRecoverEffect:
	var s: SpRecoverEffect = SpRecoverEffect.new()
	s.amount = amount
	return s

# Poison Strike
static func poison_strike() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Poison Strike"
	skill.sp_cost = 3
	
	var effects: Array[Effect] = [damage(8), status(Poison)]
	skill.effects = effects
	
	return skill
	
# Fireball
static func fireball() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Fireball"
	skill.sp_cost = 5
	skill.target_type = Action.TargetType.ALL_ENEMIES
	
	var effects: Array[Effect] = [damage(10), status(Burn)]
	skill.effects = effects
	
	return skill
	
# Slow Strike
static func slow_strike() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Slow Strike"
	skill.sp_cost = 4
	
	var effects: Array[Effect] = [damage(7), status(Slow)]
	skill.effects = effects
	
	return skill

static func healing() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Heal"
	skill.sp_cost = 4
	skill.target_type = Action.TargetType.ALLY
	
	var effects: Array[Effect] = [heal(15)]
	skill.effects = effects
	
	return skill

static func regen() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Regen"
	skill.sp_cost = 6
	skill.target_type = Action.TargetType.ALLY
	
	var effects: Array[Effect] = [status(Regen)]
	skill.effects = effects
	
	return skill

static func meditate() -> SkillAction:
	var skill: SkillAction = SkillAction.new()
	skill.name = "Meditate"
	skill.sp_cost = 0
	skill.target_type = Action.TargetType.SELF

	var effects: Array[Effect] = [recover_sp(10)]
	skill.effects = effects
	
	return skill
