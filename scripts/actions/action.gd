class_name Action
extends Resource

enum TargetType {
	ENEMY,
	SELF,
	ALLY,
	ALL_ENEMIES,
	ALL_ALLIES,
	ALL
}

var name: String = "Action"
var target_type := TargetType.ENEMY

func execute(_user: Entity, _target: Entity, _combat: CombatManager = null) -> int:
	return 0
