class_name ApplyStatusEffect
extends Effect

var status_type

func apply(_user, _target, _combat = null):
	if status_type != null:
		_target.apply_status(status_type.new(), _combat)
