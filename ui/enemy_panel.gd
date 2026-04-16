extends PanelContainer

@onready var name_label: Label = $Content/EnemyNameLabel
@onready var hp_bar: ProgressBar = $Content/EnemyHPBar

var entity
var last_hp = -1
var low_hp_tween: Tween = null
var highlight_tween: Tween = null

func setup(e):
	entity = e
	if not is_node_ready():
		await ready

	if name_label:
		name_label.text = str(e.display_name)
	if hp_bar:
		hp_bar.max_value = e.max_hp
		hp_bar.value = e.hp
		last_hp = e.hp
	
func update_hp():
	if entity == null:
		return
		
	var ratio := float(entity.hp) / float(entity.max_hp)
	
	if last_hp != entity.hp:
		animate_bar(entity.hp, entity.max_hp)
		last_hp = entity.hp
	
	if ratio <= 0.2:
		if low_hp_tween == null:
			start_low_hp_pulse()
	else:
		stop_low_hp_pulse()

func animate_bar(target_value: int, max_hp: int):
	var tween = create_tween()
	
	tween.tween_property(hp_bar, "value", target_value, 0.4)
	tween.tween_property(hp_bar, "modulate", Color(1,0.7,0.7), 0.1)
	tween.tween_property(hp_bar, "modulate", Color(1,1,1), 0.1)
	
	if low_hp_tween == null:
		var new_color = get_hp_color(target_value, max_hp)
		tween.parallel().tween_property(hp_bar, "modulate", new_color, 0.25)
		
func get_hp_color(current_hp:int, max_hp: int) -> Color:
	var ratio := float(current_hp) / float(max_hp)
	
	if ratio > 0.5:
		return Color(0.2,0.9,0.2)
		
	if ratio > 0.2:
		return Color(0.9,0.8,0.2)
	
	return Color(0.9,0.2,0.2)
	
func start_low_hp_pulse():
	low_hp_tween = create_tween()
	low_hp_tween.set_loops()
	
	low_hp_tween.tween_property(hp_bar, "modulate", Color(1,0.4,0.4), 0.4)
	low_hp_tween.tween_property(hp_bar, "modulate", Color(0.9,0.2,0.2), 0.4)
	
func stop_low_hp_pulse():
	if low_hp_tween:
		low_hp_tween.kill()
		
	low_hp_tween = null
	
	hp_bar.modulate = get_hp_color(entity.hp, entity.max_hp)

func set_highlight(enabled: bool):
	if enabled:
		if highlight_tween:
			highlight_tween.kill()
			
		highlight_tween = create_tween()
		highlight_tween.set_loops()
		
		highlight_tween.tween_property(self, "modulate", Color(1.3, 1.2, 0.6), 0.45)
		highlight_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.45)
		
	else:
		if highlight_tween:
			highlight_tween.kill()
			highlight_tween = null
			
		modulate = Color(1,1,1)
