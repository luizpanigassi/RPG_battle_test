class_name HealEffect
extends Effect

var amount := 10

func apply(_user, target, _combat = null):
	target.heal(amount)
	
	return -amount
	
