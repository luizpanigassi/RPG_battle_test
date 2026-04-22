extends Control

signal action_selected(action)
signal target_selected(target)
signal back_pressed
signal all_enemies_confirmed

@onready var player_party_container: HBoxContainer = $MainContainer/Layout/TopRow/PlayerPanel/PlayerContainer/PlayerPartyContainer
@onready var action_container: VBoxContainer = $MainContainer/Layout/BottomRow/ActionPanel/ActionColumn/ActionContainer
@onready var battle_log: RichTextLabel = $MainContainer/Layout/BottomRow/LogPanel/LogColumn/BattleLog
@onready var enemy_container: HBoxContainer = $MainContainer/Layout/TopRow/EnemyPanel/EnemyPanelContent/EnemyContainer

const MAX_BATTLE_LOG_LINES := 10
const LOG_SKILL_COLOR := "orange"
const LOG_DAMAGE_COLOR := "red"
const LOG_HEAL_COLOR := "green"
const LOG_DEBUFF_COLOR := "violet"
const LOG_BUFF_COLOR := "skyblue"
const LOG_NEUTRAL_COLOR := "gray"

var player_panels: Dictionary = {}
var enemy_panels: Dictionary = {}
var current_player = null
var highlighted_enemy = null
var battle_log_lines: Array[String] = []

func _ready():
	battle_log.scroll_active = false
	battle_log.bbcode_enabled = true
	
func set_actions(actions: Array, user: Entity = null):
	for panel in enemy_panels.values():
		panel.set_highlight(false)

	for child in action_container.get_children():
		child.queue_free()

	for entry in actions:
		var action := entry as Action
		if action == null:
			continue

		var button := Button.new()
		button.text = action.name
		action_container.add_child(button)
		button.pressed.connect(_on_action_button_pressed.bind(action, user, button))

func start_target_selection(enemies: Array):
	for child in action_container.get_children():
		child.queue_free()
	
	clear_enemy_highlight()
	
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		
		var button := Button.new()
		button.text = enemy.display_name
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

func start_all_enemies_selection():
	for child in action_container.get_children():
		child.queue_free()

	clear_enemy_highlight()

	var all_button := Button.new()
	all_button.text = "All Enemies"
	action_container.add_child(all_button)
	all_button.pressed.connect(func(): all_enemies_confirmed.emit())
	all_button.mouse_entered.connect(highlight_all_enemies)
	all_button.mouse_exited.connect(clear_all_enemy_highlight)

	var back_button := Button.new()
	back_button.text = "Back"
	action_container.add_child(back_button)
	back_button.pressed.connect(_on_back_button_pressed)
	back_button.mouse_entered.connect(clear_all_enemy_highlight)
	back_button.mouse_exited.connect(clear_all_enemy_highlight)

func start_ally_target_selection(allies: Array):
	for child in action_container.get_children():
		child.queue_free()

	clear_enemy_highlight()

	for ally in allies:
		var button := Button.new()
		button.text = ally.display_name
		action_container.add_child(button)

		var is_dead: bool = ally.hp <= 0
		button.disabled = is_dead

		if is_dead:
			button.modulate = Color(0.6, 0.6, 0.6, 1.0)
		else:
			button.pressed.connect(_on_target_button_pressed.bind(ally))
		
	var back_button := Button.new()
	back_button.text = "Back"
	action_container.add_child(back_button)
	back_button.pressed.connect(_on_back_button_pressed)

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

func highlight_all_enemies():
	clear_enemy_highlight()
	for panel in enemy_panels.values():
		panel.set_highlight(true)

func clear_enemy_highlight():
	if highlighted_enemy != null and enemy_panels.has(highlighted_enemy):
		enemy_panels[highlighted_enemy].set_highlight(false)
	highlighted_enemy = null

func clear_all_enemy_highlight():
	for panel in enemy_panels.values():
		panel.set_highlight(false)
	highlighted_enemy = null
		
func _on_action_button_pressed(action: Action, user: Entity, button: Button):
	if user != null and not action.can_use(user):
		_flash_button_no_sp(button)
		return

	action_selected.emit(action)

func _flash_button_no_sp(button: Button):
	var tween := create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 0.35, 0.35), 0.08)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0), 0.12)
	
func _on_target_button_pressed(enemy):
	clear_enemy_highlight()
	target_selected.emit(enemy)
	
func _on_back_button_pressed():
	clear_enemy_highlight()
	clear_all_enemy_highlight()
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

func setup_players(players: Array):
	for child in player_party_container.get_children():
		child.queue_free()
	player_panels.clear()
	var panel_scene = preload("res://ui/player_party_panel.tscn")
	for p in players:
		var panel = panel_scene.instantiate()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_party_container.add_child(panel)
		panel.setup(p)
		player_panels[p] = panel

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

func get_player_slot_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if count <= 0:
		return positions

	var panels := player_party_container.get_children()
	var baseline_y := player_party_container.global_position.y + player_party_container.size.y + 22.0

	if panels.size() >= count:
		for i in count:
			var panel := panels[i] as Control
			if panel == null:
				continue
			var center_x := panel.global_position.x + panel.size.x * 0.5
			positions.append(Vector2(center_x, baseline_y))
		return positions

	var width := player_party_container.size.x
	if width <= 0.0:
		width = player_party_container.get_combined_minimum_size().x
	if width <= 0.0:
		width = 420.0

	var step := width / float(count)
	for i in count:
		var x := player_party_container.global_position.x + step * (float(i) + 0.5)
		positions.append(Vector2(x, baseline_y))

	return positions
		
func update_hp(players: Array, active_player, enemies: Array):
	update_party_and_enemies(players, active_player, enemies)

func update_party_and_enemies(players: Array, active_player, enemies: Array):
	current_player = active_player

	for p in players:
		if player_panels.has(p):
			player_panels[p].update_stats()
			player_panels[p].set_active_turn(p == active_player)
	
	for e in enemies:
		if enemy_panels.has(e):
			enemy_panels[e].update_hp()
	
func log(text: String):
	battle_log_lines.append(text)

	while battle_log_lines.size() > MAX_BATTLE_LOG_LINES:
		battle_log_lines.pop_front()

	battle_log.clear()
	battle_log.append_text("\n".join(battle_log_lines))

func log_skill(user, skill):
	_log_with_style(LOG_SKILL_COLOR, "🔥", user.display_name + " uses " + skill.name + "!")
	
func log_damage(target, amount):
	_log_with_style(LOG_DAMAGE_COLOR, "💥", target.display_name + " takes " + str(amount) + " damage!")
	
func log_heal(target, amount):
	_log_with_style(LOG_HEAL_COLOR, "💚", target.display_name + " recovers " + str(amount) + " HP!")

func log_sp_recover(target, amount):
	_log_with_style("skyblue", "💙", target.display_name + " recovers " + str(amount) + " SP!")
	
func log_status(target, status):
	_log_with_style(LOG_DEBUFF_COLOR, "☠", target.display_name + " is afflicted with " + status.name + "!")

func log_buff(target, status):
	_log_with_style(LOG_BUFF_COLOR, "✨", target.display_name + " gains " + status.name + "!")
	
func log_status_end(target, status):
	_log_with_style(LOG_NEUTRAL_COLOR, "✨", status.name + " on " + target.display_name + " wore off.")

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

func remove_enemy(enemy):
	if enemy_panels.has(enemy):
		var panel = enemy_panels[enemy]
		var tween = create_tween()
		
		tween.tween_property(panel, "modulate:a", 0.0, 1.5)
		await tween.finished
		
		panel.queue_free()
		enemy_panels.erase(enemy)

func clear_for_combat_end():
	clear_enemy_highlight()
	clear_all_enemy_highlight()

	for child in action_container.get_children():
		child.queue_free()
