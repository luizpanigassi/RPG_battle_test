class_name DamageEffect
extends Effect

var power := 10

func apply(_user, target, _combat = null):
	var damage = target.take_damage(power)
	return damage
