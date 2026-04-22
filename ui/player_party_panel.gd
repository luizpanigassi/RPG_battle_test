extends PanelContainer

@onready var name_label: Label = $Content/PlayerNameLabel
@onready var hp_bar: ProgressBar = $Content/PlayerHPBar
@onready var sp_bar: ProgressBar = $Content/PlayerSPBar

var entity
var last_hp := -1
var last_sp := -1
var highlight_tween: Tween = null

func setup(e):
	entity = e
	if not is_node_ready():
		await ready

	name_label.text = str(e.display_name)
	hp_bar.max_value = e.max_hp
	hp_bar.value = e.hp
	sp_bar.max_value = e.max_sp
	sp_bar.value = e.sp

	last_hp = e.hp
	last_sp = e.sp

func update_stats():
	if entity == null:
		return

	if hp_bar.max_value != entity.max_hp:
		hp_bar.max_value = entity.max_hp
	if sp_bar.max_value != entity.max_sp:
		sp_bar.max_value = entity.max_sp

	if last_hp != entity.hp:
		var hp_tween := create_tween()
		hp_tween.tween_property(hp_bar, "value", entity.hp, 0.25)
		last_hp = entity.hp

	if last_sp != entity.sp:
		var sp_tween := create_tween()
		sp_tween.tween_property(sp_bar, "value", entity.sp, 0.25)
		last_sp = entity.sp
	
func set_active_turn(enabled: bool):
	if enabled:
		if highlight_tween:
			highlight_tween.kill()
		highlight_tween = create_tween()
		highlight_tween.set_loops()
		highlight_tween.tween_property(self, "modulate", Color(1.15, 1.12, 0.9), 0.35)
		highlight_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.35)      
	
	else:
		if highlight_tween:
			highlight_tween.kill()
			highlight_tween = null
		modulate = Color(1, 1, 1)
