extends Control

signal action_selected(action)
signal target_selected(target)
signal back_pressed

@onready var player_hp_bar: ProgressBar = $MainContainer/Layout/TopRow/PlayerPanel/PlayerContainer/PlayerHPBar
@onready var action_container: VBoxContainer = $MainContainer/Layout/BottomRow/ActionPanel/ActionColumn/ActionContainer
@onready var battle_log: RichTextLabel = $MainContainer/Layout/BottomRow/LogPanel/LogColumn/BattleLog
@onready var player_name_label: Label = $MainContainer/Layout/TopRow/PlayerPanel/PlayerContainer/PlayerNameLabel
@onready var enemy_container: HBoxContainer = $MainContainer/Layout/TopRow/EnemyPanel/EnemyPanelContent/EnemyContainer

const MAX_BATTLE_LOG_LINES := 10
const LOG_SKILL_COLOR := "orange"
const LOG_DAMAGE_COLOR := "red"
const LOG_HEAL_COLOR := "green"
const LOG_DEBUFF_COLOR := "violet"
const LOG_BUFF_COLOR := "skyblue"
const LOG_NEUTRAL_COLOR := "gray"

var player_low_hp_tween: Tween
var last_player_hp := -1
var enemy_panels: Dictionary = {}
var highlighted_enemy = null
var battle_log_lines: Array[String] = []

func _ready():
	battle_log.scroll_active = false
	battle_log.bbcode_enabled = true
	
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
	action_selected.emit(action)
	
func _on_target_button_pressed(enemy):
	clear_enemy_highlight()
	target_selected.emit(enemy)
	
func _on_back_button_pressed():
	clear_enemy_highlight()
	back_pressed.emit()

func setup_enemies(enemies: Array):
	for child in enemy_container.get_children():
		child.queue_free()
	
	enemy_panels.clear()
	
	var panel_scene = preload("res://ui/enemy_panel.tscn")
	
	for e in enemies:
		var panel = panel_scene.instantiate()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		enemy_container.add_child(panel)
		panel.setup(e)
		enemy_panels[e] = panel

func get_enemy_slot_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if count <= 0:
		return positions

	var width := enemy_container.size.x
	if width <= 0.0:
		width = enemy_container.get_combined_minimum_size().x
	if width <= 0.0:
		width = 480.0

	var step := width / float(count)
	var y := enemy_container.global_position.y + enemy_container.size.y + 18.0

	for i in count:
		var x := enemy_container.global_position.x + step * (float(i) + 0.5)
		positions.append(Vector2(x, y))

	return positions
		
func update_hp(player, enemies):
	player_hp_bar.max_value = player.max_hp
	player_name_label.text = player.display_name

	if player.max_hp <= 0:
		return

	var player_ratio := float(player.hp) / float(player.max_hp)
	
	if last_player_hp != player.hp:
		animate_bar(player_hp_bar, player.hp, player.max_hp)
		last_player_hp = player.hp
		
	if player_ratio <= 0.2:
		if player_low_hp_tween == null:
			start_low_hp_pulse(player_hp_bar)
	else:
		stop_low_hp_pulse(player_hp_bar, player.hp, player.max_hp)
		
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
	battle_log_lines.append(text)

	while battle_log_lines.size() > MAX_BATTLE_LOG_LINES:
		battle_log_lines.pop_front()

	battle_log.clear()
	battle_log.append_text("\n".join(battle_log_lines))

func log_skill(user, skill):
	_log_with_style(LOG_SKILL_COLOR, "🔥", user.name + " uses " + skill.name + "!")
	
func log_damage(target, amount):
	_log_with_style(LOG_DAMAGE_COLOR, "💥", target.name + " takes " + str(amount) + " damage!")
	
func log_heal(target, amount):
	_log_with_style(LOG_HEAL_COLOR, "💚", target.name + " recovers " + str(amount) + " HP!")
	
func log_status(target, status):
	_log_with_style(LOG_DEBUFF_COLOR, "☠", target.name + " is afflicted with " + status.name + "!")

func log_buff(target, status):
	_log_with_style(LOG_BUFF_COLOR, "✨", target.name + " gains " + status.name + "!")
	
func log_status_end(target, status):
	_log_with_style(LOG_NEUTRAL_COLOR, "✨", status.name + " on " + target.name + " wore off.")

func _log_with_style(color_name: String, icon: String, message: String):
	self.log("[color=%s]%s %s[/color]" % [color_name, icon, message])

func get_hp_color(current_hp: int, max_hp: int) -> Color:
	if max_hp <= 0:
		return Color(0.9, 0.2, 0.2)

	var ratio := float(current_hp) / float(max_hp)
	if ratio > 0.5:
		return Color(0.2, 0.9, 0.2) #verde
	if ratio > 0.2:
		return Color(0.9, 0.8, 0.2) #amarelo
	else:
		return Color(0.9, 0.2, 0.2) #vermelho
		
func start_low_hp_pulse(bar: ProgressBar):
	var tween = create_tween()
	tween.set_loops()
	
	tween.tween_property(bar, "modulate", Color(1, 0.4, 0.4), 0.4)
	tween.tween_property(bar, "modulate", Color(0.9, 0.2, 0.2), 0.4)

	player_low_hp_tween = tween
		
func stop_low_hp_pulse(bar: ProgressBar, current_hp: int, max_hp: int):
	var tween = player_low_hp_tween
	player_low_hp_tween = null
		
	if tween:
		tween.kill()
	
	bar.modulate = get_hp_color(current_hp, max_hp)

func is_low_hp_active(bar: ProgressBar) -> bool:
	return(bar == player_hp_bar and player_low_hp_tween != null)

func remove_enemy(enemy):
	if enemy_panels.has(enemy):
		var panel = enemy_panels[enemy]
		var tween = create_tween()
		
		tween.tween_property(panel, "modulate:a", 0.0, 1.5)
		await tween.finished
		
		panel.queue_free()
		enemy_panels.erase(enemy)
