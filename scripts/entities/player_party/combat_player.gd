class_name CombatPlayer
extends Entity

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var entity_data: EntityData = preload("res://scripts/entities/data/shadow.tres")

var animation_prefix: String = ""
var _player_initialized := false

func _ready():
	if _player_initialized:
		return
	_player_initialized = true
	_setup_player_data()
	_play_idle()
	_build_loadout()

func _setup_player_data():
	apply_data(entity_data)

	if entity_data != null:
		animation_prefix = entity_data.animation_prefix
		if animation_prefix.is_empty():
			animation_prefix = entity_data.display_name.to_lower().replace(" ", "_")
	else:
		animation_prefix = display_name.to_lower().replace(" ", "_")

	var stats := GameManager.player_stats
	max_hp += stats.max_hp_bonus
	attack += stats.attack_bonus
	defense += stats.defense_bonus

	var member_state := GameManager.get_party_member_state(get_party_member_id())
	hp = member_state.resolve_starting_hp(max_hp)
	sp = member_state.resolve_starting_sp(max_sp)

func get_party_member_id() -> String:
	if not animation_prefix.is_empty():
		return animation_prefix

	if entity_data != null and not entity_data.animation_prefix.is_empty():
		return entity_data.animation_prefix

	if entity_data != null and not entity_data.display_name.is_empty():
		return entity_data.display_name.to_lower().replace(" ", "_")

	return display_name.to_lower().replace(" ", "_")

func _build_loadout():
	# child class vai montar
	pass

func play_attack_animation():
	await _play_one_shot_animation("attack")

func play_hurt_animation():
	await _play_one_shot_animation("hurt")

func _play_one_shot_animation(animation_name: String):
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null:
		return

	var resolved_animation_name := _resolve_animation_name(animation_name)
	if resolved_animation_name.is_empty():
		return

	animated_sprite.play(resolved_animation_name)

	if resolved_animation_name == _resolve_idle_animation_name():
		return

	var frame_count := animated_sprite.sprite_frames.get_frame_count(resolved_animation_name)
	var animation_speed := animated_sprite.sprite_frames.get_animation_speed(resolved_animation_name) * animated_sprite.speed_scale
	if animation_speed <= 0.0:
		animation_speed = 1.0

	var duration := float(frame_count) / animation_speed
	await get_tree().create_timer(duration).timeout

	_play_idle()

func _anim_name(action: String) -> String:
	return "%s_%s" % [animation_prefix, action]

func _resolve_animation_name(action: String) -> String:
	var prefixed := _anim_name(action)
	if animated_sprite.sprite_frames.has_animation(prefixed):
		return prefixed

	if animated_sprite.sprite_frames.has_animation(action):
		return action

	return _resolve_idle_animation_name()

func _resolve_idle_animation_name() -> String:
	var prefixed_idle := _anim_name("idle")
	if animated_sprite.sprite_frames.has_animation(prefixed_idle):
		return prefixed_idle

	if animated_sprite.sprite_frames.has_animation("idle"):
		return "idle"

	return ""

func _play_idle():
	var idle_name := _resolve_idle_animation_name()
	if not idle_name.is_empty():
		animated_sprite.play(idle_name)
