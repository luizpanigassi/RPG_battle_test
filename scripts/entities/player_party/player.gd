extends Entity

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _init():
	display_name = "Shadow"
	# Normal attack
	actions.append(AttackAction.new())
	# Skill appends:
	actions.append(SkillFactory.poison_strike())
	actions.append(SkillFactory.fireball())
	actions.append(SkillFactory.slow_strike())
	actions.append(SkillFactory.healing())
	actions.append(SkillFactory.regen())

func play_attack_animation():
	await _play_one_shot_animation("attack")

func play_hurt_animation():
	await _play_one_shot_animation("hurt")

func _play_one_shot_animation(animation_name: String):
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return

	animated_sprite.play(animation_name)

	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	var animation_speed := animated_sprite.sprite_frames.get_animation_speed(animation_name) * animated_sprite.speed_scale
	if animation_speed <= 0.0:
		animation_speed = 1.0

	var duration := float(frame_count) / animation_speed
	await get_tree().create_timer(duration).timeout

	if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
