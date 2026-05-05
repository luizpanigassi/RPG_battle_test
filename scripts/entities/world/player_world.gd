extends CharacterBody2D

@export var speed = 200
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if GameManager.has_saved_player_position:
		global_position = GameManager.consume_saved_player_position()

func _physics_process(_delta: float) -> void:
	var dir = Vector2.ZERO

	if SceneTransition.is_transitioning:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if dir.x > 0:
		sprite.flip_h = false
	elif dir.x < 0:
		sprite.flip_h = true

	velocity = dir.normalized() * speed
	
	if dir.length_squared() > 0.0:
		sprite.play("run")
	else:
		sprite.play("idle")

	move_and_slide()
