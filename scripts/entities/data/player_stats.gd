class_name PlayerStats
extends Resource

@export var level: int = 1
@export var current_xp: int = 0
@export var total_gold: int = 0
@export var current_hp: int = -1
@export var max_hp_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var max_sp: int = 0
@export var current_sp: int = 0
@export var sp_bonus: int = 0

var last_position: Vector2 = Vector2.ZERO
const XP_PER_LEVEL: int = 100

func gain_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= get_xp_for_next_level():
		current_xp -= get_xp_for_next_level()
		level_up()

func level_up() -> void:
	level += 1
	max_hp_bonus += 10
	attack_bonus += 2
	defense_bonus += 1

func get_xp_for_next_level() -> int:
	return XP_PER_LEVEL * level

func add_gold(amount: int) -> void:
	total_gold += amount

func sync_current_hp(hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		return

	current_hp = clamp(hp, 0, max_hp)

func sync_current_sp(sp:int, max_sp_value: int) -> void:
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

func get_xp_progress() -> float:
	if get_xp_for_next_level() <= 0:
		return 0.0
	return float(current_xp) / float(get_xp_for_next_level())

func save_position(pos: Vector2) -> void:
	last_position = pos

func restore_position() -> Vector2:
	return last_position
