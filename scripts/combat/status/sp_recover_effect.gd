class_name SpRecoverEffect
extends Effect

var amount := 10

func apply(_user, target, _combat = null):
	target.sp_recover(amount)
	
	if _combat != null and _combat.ui != null:
		_combat.ui.log_sp_recover(target, amount)

	return 0
