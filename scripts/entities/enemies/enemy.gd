class_name Enemy
extends Entity

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var animation_prefix := "goblin"
var visual_offset := Vector2.ZERO
var visual_scale := 1.0

func set_animation_prefix(prefix: String):
	animation_prefix = prefix
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	_play_idle()

func play_attack_animation():
	await _play_one_shot_animation("attack")

func play_hurt_animation():
	await _play_one_shot_animation("hurt")

func _play_one_shot_animation(action: String):
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	var anim_name := _resolve_animation_name(action)
	if anim_name.is_empty():
		return

	animated_sprite.play(anim_name)

	# If we fell back to idle, there is no one-shot to wait for.
	if anim_name == _resolve_idle_animation_name():
		return

	var frame_count := animated_sprite.sprite_frames.get_frame_count(anim_name)
	var anim_speed := animated_sprite.sprite_frames.get_animation_speed(anim_name) * animated_sprite.speed_scale
	if anim_speed <= 0.0:
		anim_speed = 1.0

	await get_tree().create_timer(float(frame_count) / anim_speed).timeout
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

func choose_action(targets: Array):
	var target = targets[0]
	var action = AttackAction.new()
	return {
		"action": action,
		"target": target
	}
