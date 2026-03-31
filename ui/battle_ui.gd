extends Control

signal action_selected(action)

@onready var player_hp_bar: ProgressBar = $MainContainer/TopBar/PlayerContainer/PlayerHPBar
@onready var enemy_hp_bar: ProgressBar = $MainContainer/TopBar/EnemyContainer/EnemyHPBar
@onready var action_container: VBoxContainer = $MainContainer/ActionPanel/ActionContainer
@onready var battle_log: RichTextLabel = $MainContainer/BattleLog
@onready var player_name_label: Label = $MainContainer/TopBar/PlayerContainer/PlayerNameLabel
@onready var enemy_name_label: Label = $MainContainer/TopBar/EnemyContainer/EnemyNameLabel

var last_player_hp := -1
var last_enemy_hp := -1

func _ready():
	print("Player HP bar:", player_hp_bar)
	print("Enemy HP bar:", enemy_hp_bar)

func set_actions(actions: Array[Action]):
	for child in action_container.get_children():
		child.queue_free()

	for action in actions:
		var button := Button.new()
		button.text = action.name
		action_container.add_child(button)
		button.pressed.connect(_on_action_button_pressed.bind(action))

func _on_action_button_pressed(action: Action):
	print("Selected action:", action.name)
	emit_signal("action_selected", action)
	
func update_hp(player, enemy):
	player_hp_bar.max_value = player.max_hp
	enemy_hp_bar.max_value = enemy.max_hp
	player_name_label.text = player.name
	enemy_name_label.text = enemy.name
	if last_player_hp != player.hp:
		animate_bar(player_hp_bar, player.hp, player.max_hp)
		last_player_hp = player.hp
	if last_enemy_hp != enemy.hp:
		animate_bar(enemy_hp_bar, enemy.hp, enemy.max_hp)
		last_enemy_hp = enemy.hp
	
func animate_bar(bar: ProgressBar, target_value: int, max_hp: int):
	var tween = create_tween()
	tween.tween_property(bar, "value", target_value, 0.4)
	tween.tween_property(bar, "modulate", Color(1,0.7,0.7), 0.1)
	tween.tween_property(bar, "modulate", Color(1,1,1), 0.1)
	var new_color = get_hp_color(target_value, max_hp)
	tween.parallel().tween_property(bar, "modulate", new_color, 0.25)

func log(text: String):
	battle_log.append_text(text + '\n')
	battle_log.scroll_to_line(battle_log.get_line_count())
	
func get_hp_color(current_hp: int, max_hp: int) -> Color:
	var ratio := float(current_hp) / float(max_hp)
	if ratio > 0.5:
		return Color(0.2, 0.9, 0.2) #verde
	if ratio > 0.2:
		return Color(0.9, 0.8, 0.2) #amarelo
	else:
		return Color(0.9, 0.2, 0.2) #vermelho
