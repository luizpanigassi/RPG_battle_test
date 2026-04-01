extends Control

signal action_selected(action)
signal target_selected(target)
signal back_pressed

@onready var player_hp_bar: ProgressBar = $MainContainer/TopBar/PlayerContainer/PlayerHPBar
@onready var action_container: VBoxContainer = $MainContainer/ActionPanel/ActionContainer
@onready var battle_log: RichTextLabel = $MainContainer/BattleLog
@onready var player_name_label: Label = $MainContainer/TopBar/PlayerContainer/PlayerNameLabel
@onready var enemy_container: VBoxContainer = $MainContainer/EnemyContainer

var player_low_hp_tween: Tween
var enemy_low_hp_tween: Tween
var last_player_hp := -1
var last_enemy_hp := -1
var enemy_panels = {}
var highlighted_enemy = null

func _ready():
	pass
	
func set_actions(actions: Array[Action]):
	for panel in enemy_panels.values():
		panel.set_highlight(false)

	for child in action_container.get_children():
		child.queue_free()

	for action in actions:
		var button := Button.new()
		button.text = action.name
		action_container.add_child(button)
		button.pressed.connect(_on_action_button_pressed.bind(action))

func start_target_selection(enemies: Array):
	for child in action_container.get_children():
		child.queue_free()
	
	clear_enemy_highlight()
	
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		
		var button := Button.new()
		button.text = enemy.name
		action_container.add_child(button)
		button.mouse_entered.connect(_on_target_button_mouse_entered.bind(enemy))
		button.mouse_exited.connect(_on_target_button_mouse_exited.bind(enemy))
		button.pressed.connect(_on_target_button_pressed.bind(enemy))
	
	var back_button := Button.new()
	back_button.text = "Back"
	action_container.add_child(back_button)
	back_button.pressed.connect(_on_back_button_pressed)

	back_button.mouse_entered.connect(clear_enemy_highlight)
	back_button.mouse_exited.connect(clear_enemy_highlight)

func _on_target_button_mouse_entered(enemy):
	highlight_enemy(enemy)

func _on_target_button_mouse_exited(enemy):
	if highlighted_enemy == enemy:
		clear_enemy_highlight()

func highlight_enemy(enemy):
	if highlighted_enemy == enemy:
		return

	clear_enemy_highlight()

	if enemy_panels.has(enemy):
		enemy_panels[enemy].set_highlight(true)
		highlighted_enemy = enemy

func clear_enemy_highlight():
	if highlighted_enemy != null and enemy_panels.has(highlighted_enemy):
		enemy_panels[highlighted_enemy].set_highlight(false)
	highlighted_enemy = null
		
func _on_action_button_pressed(action: Action):
	print("Selected action:", action.name)
	emit_signal("action_selected", action)
	
func _on_target_button_pressed(enemy):
	clear_enemy_highlight()

	emit_signal("target_selected", enemy)
	
func _on_back_button_pressed():
	clear_enemy_highlight()

	emit_signal("back_pressed")

func setup_enemies(enemies: Array):
	for child in enemy_container.get_children():
		child.queue_free()
	
	enemy_panels.clear()
	
	var panel_scene = preload("res://ui/enemy_panel.tscn")
	
	for e in enemies:
		var panel = panel_scene.instantiate()
		enemy_container.add_child(panel)
		panel.setup(e)
		enemy_panels[e] = panel
		
func update_hp(player, enemies):
	player_hp_bar.max_value = player.max_hp
	player_name_label.text = player.name
	
	var player_ratio := float(player.hp) / float(player.max_hp)
	
	if last_player_hp != player.hp:
		animate_bar(player_hp_bar, player.hp, player.max_hp)
		last_player_hp = player.hp
		
	if player_ratio <= 0.2:
		if player_low_hp_tween == null:
			start_low_hp_pulse(player_hp_bar, "player")
	else:
		stop_low_hp_pulse(player_hp_bar, "player", player.hp, player.max_hp)
		
	for e in enemies:
		if enemy_panels.has(e):
			enemy_panels[e].update_hp()
	
func animate_bar(bar: ProgressBar, target_value: int, max_hp: int):
	var tween = create_tween()
	tween.tween_property(bar, "value", target_value, 0.4)
	tween.tween_property(bar, "modulate", Color(1,0.7,0.7), 0.1)
	tween.tween_property(bar, "modulate", Color(1,1,1), 0.1)
	if not is_low_hp_active(bar):
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
		
func start_low_hp_pulse(bar: ProgressBar, tween_ref_name: String):
	var tween = create_tween()
	tween.set_loops()
	
	tween.tween_property(bar, "modulate", Color(1, 0.4, 0.4), 0.4)
	tween.tween_property(bar, "modulate", Color(0.9, 0.2, 0.2), 0.4)
	
	if tween_ref_name == "player":
		player_low_hp_tween = tween
	else:
		enemy_low_hp_tween = tween
		
func stop_low_hp_pulse(bar: ProgressBar, tween_ref_name: String, current_hp: int, max_hp: int):
	var tween
	
	if tween_ref_name == "player":
		tween = player_low_hp_tween
		player_low_hp_tween = null
	else:
		tween = enemy_low_hp_tween
		enemy_low_hp_tween = null
		
	if tween:
		tween.kill()
	
	bar.modulate = get_hp_color(current_hp, max_hp)

func is_low_hp_active(bar: ProgressBar) -> bool:
	return(bar == player_hp_bar and player_low_hp_tween != null)
	
func update_turn_order(queue: Array, current_index: int):
	var text = "Turn order:\n"
	
	for i in range(queue.size()):
		if i == current_index:
			text += "👉"
		text += queue[i].name + "\n"
	
	battle_log.clear()
	battle_log.append_text(text)

func remove_enemy(enemy):
	if enemy_panels.has(enemy):
		var panel = enemy_panels[enemy]
		var tween = create_tween()
		
		tween.tween_property(panel, "modulate:a", 0.0, 1.5)
		await tween.finished
		
		panel.queue_free()
		enemy_panels.erase(enemy)
