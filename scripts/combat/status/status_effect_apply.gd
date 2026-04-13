class_name ApplyStatusEffect
extends Effect

var status_type: Script

func apply(_user: Entity, target: Entity, combat: CombatManager = null) -> Variant:
	if status_type == null:
		return null

	var status_effect: StatusEffect = status_type.new() as StatusEffect
	if status_effect is StatusEffect:
		target.apply_status(status_effect, combat)

	return null
