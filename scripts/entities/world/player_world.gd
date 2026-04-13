extends CharacterBody2D

@export var speed = 200

func _physics_process(_delta: float) -> void:
	var dir = Vector2.ZERO

	if SceneTransition.is_transitioning:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	velocity = dir.normalized() * speed
	
	move_and_slide()
