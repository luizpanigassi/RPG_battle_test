class_name Enemy
extends Entity

func choose_action(targets: Array):
	var target = targets[0]
	var action = AttackAction.new()
	return {
		"action": action,
		"target": target
	}
