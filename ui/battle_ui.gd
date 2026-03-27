extends Control

signal attack_selected

func _ready():
	$AttackButton.pressed.connect(_on_attack_pressed)

func _on_attack_pressed():
	print("You attack!")
	emit_signal("attack_selected")
