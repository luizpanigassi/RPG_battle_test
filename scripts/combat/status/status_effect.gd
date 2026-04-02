class_name StatusEffect
extends Resource

var name := "Status"
var duration := 3

func on_apply(_target):
	pass

func on_turn_start(_target, _combat):
	pass

func on_turn_end(_target):
	pass

func on_expire(_target):
	pass
