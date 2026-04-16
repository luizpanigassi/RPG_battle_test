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
var sp_cost: int = 0

func execute(_user: Entity, _target: Entity, _combat: CombatManager = null) -> int:
	return 0

func can_use(user: Entity) -> bool:
	return user.sp >= sp_cost
