class_name PartyMemberState
extends Resource

@export var current_hp: int = -1
@export var current_sp: int = -1

func sync_current_hp(hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		return

	current_hp = clamp(hp, 0, max_hp)

func sync_current_sp(sp: int, max_sp_value: int) -> void:
	if max_sp_value <= 0:
		return

	current_sp = clamp(sp, 0, max_sp_value)

func resolve_starting_hp(max_hp: int) -> int:
	if max_hp <= 0:
		return 0

	if current_hp < 0:
		current_hp = max_hp

	current_hp = clamp(current_hp, 0, max_hp)
	return current_hp

func resolve_starting_sp(max_sp_value: int) -> int:
	if max_sp_value <= 0:
		return 0

	if current_sp < 0:
		current_sp = max_sp_value

	current_sp = clamp(current_sp, 0, max_sp_value)
	return current_sp
